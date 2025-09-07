// Parallel Genetic Algorithm using Pony actors for concurrent fitness evaluation

use "collections"
use "random"
use "time"

actor ParallelGAController[D: ProblemDomain val, G: GenomeOperations val, C: GAConfiguration val]
  """
  Main coordinator for parallel genetic algorithm execution using worker actors.
  """
  let _env: Env
  let _domain: D
  let _genome_ops: G  
  let _config: C
  let _reporter: ReportSink tag
  let _rng: Rand
  var _generation: USize = 0
  var _population: Array[Array[U8] val] = Array[Array[U8] val]
  var _fitness_scores: Array[F64] = Array[F64]
  let _workers: Array[FitnessWorker[D, G, C]] = Array[FitnessWorker[D, G, C]]
  var _completed_evaluations: USize = 0
  var _target_generation: USize = 0
  var _running: Bool = false
  var _ignore_perfect_fitness: Bool = false

  new create(env: Env, domain: D, genome_ops: G, config: C, reporter: ReportSink tag) =>
    _env = env
    _domain = domain
    _genome_ops = genome_ops
    _config = config
    _reporter = reporter
    _rng = Rand(Time.nanos(), Time.millis())
    _target_generation = 10000 // Default max generations
    
    // Create worker actors for parallel fitness evaluation
    for i in Range[USize](0, _config.worker_count()) do
      _workers.push(FitnessWorker[D, G, C].create(this, domain))
    end
    
    _initialize_population()
    _start_evolution()

  new with_limit(env: Env, domain: D, genome_ops: G, config: C, reporter: ReportSink tag, 
                 target_gen: USize) =>
    _env = env
    _domain = domain
    _genome_ops = genome_ops
    _config = config
    _reporter = reporter
    _rng = Rand(Time.nanos(), Time.millis())
    _target_generation = target_gen
    
    // Create worker actors
    for i in Range[USize](0, _config.worker_count()) do
      _workers.push(FitnessWorker[D, G, C].create(this, domain))
    end
    
    // Try to load existing population
    (let gen, let genome_opt) = GenomePersistence.find_latest_generation(_env, "sentiment/bin/")
    match genome_opt
    | let genome: Array[U8] val =>
      _generation = gen
      _initialize_population_from_best(genome)
    | None =>
      _initialize_population()
    end
    
    _start_evolution()

  new with_limit_no_perfect(env: Env, domain: D, genome_ops: G, config: C, reporter: ReportSink tag, 
                           target_gen: USize) =>
    _env = env
    _domain = domain
    _genome_ops = genome_ops
    _config = config
    _reporter = reporter
    _rng = Rand(Time.nanos(), Time.millis())
    _target_generation = target_gen
    _ignore_perfect_fitness = true  // Ignore perfect fitness for resume mode
    
    // Create worker actors
    for i in Range[USize](0, _config.worker_count()) do
      _workers.push(FitnessWorker[D, G, C].create(this, domain))
    end
    
    // Try to load existing population
    (let gen, let genome_opt) = GenomePersistence.find_latest_generation(_env, "sentiment/bin/")
    match genome_opt
    | let genome: Array[U8] val =>
      _generation = gen
      _initialize_population_from_best(genome)
    | None =>
      _initialize_population()
    end
    
    _start_evolution()

  be fitness_result(worker_id: USize, genome_id: USize, fitness: F64) =>
    """Receive fitness evaluation result from worker actor."""
    try
      _fitness_scores(genome_id)? = fitness
    end
    
    _completed_evaluations = _completed_evaluations + 1
    
    // When all evaluations are complete, proceed to next generation
    if _completed_evaluations >= _population.size() then
      _process_generation()
    end

  fun ref _initialize_population() =>
    """Initialize random population."""
    _population = Array[Array[U8] val](_config.population_size())
    _fitness_scores = Array[F64](_config.population_size())
    
    for i in Range[USize](0, _config.population_size()) do
      _population.push(_domain.random_genome(_rng))
      _fitness_scores.push(0.0)
    end

  fun ref _initialize_population_from_best(best_genome: Array[U8] val) =>
    """Initialize population with variations of the best genome."""
    _population = Array[Array[U8] val](_config.population_size())
    _fitness_scores = Array[F64](_config.population_size())
    
    // Keep the best genome
    _population.push(best_genome)
    _fitness_scores.push(0.0)
    
    // Create variations
    for i in Range[USize](1, _config.population_size()) do
      let mutated = if (i % 5) == 0 then
        _genome_ops.heavy_mutate(_rng, best_genome)
      else
        _genome_ops.mutate(_rng, best_genome)
      end
      _population.push(mutated)
      _fitness_scores.push(0.0)
    end

  fun ref _start_evolution() =>
    """Start the evolutionary process."""
    if _running then return end
    _running = true
    _evaluate_population()

  fun ref _evaluate_population() =>
    """Distribute population evaluation across worker actors."""
    _completed_evaluations = 0
    
    // Distribute genomes to workers in round-robin fashion
    for i in Range[USize](0, _population.size()) do
      try
        let worker_id = i % _workers.size()
        let worker = _workers(worker_id)?
        let genome = _population(i)?
        worker.evaluate_genome(worker_id, i, genome)
      end
    end

  fun ref _process_generation() =>
    """Process completed generation and create next generation."""
    _generation = _generation + 1
    
    // Find best and average fitness
    var best_fitness: F64 = 0.0
    var total_fitness: F64 = 0.0
    var best_genome: (Array[U8] val | None) = None
    
    for i in Range[USize](0, _fitness_scores.size()) do
      try
        let fitness = _fitness_scores(i)?
        total_fitness = total_fitness + fitness
        if fitness > best_fitness then
          best_fitness = fitness
          best_genome = _population(i)?
        end
      end
    end
    
    let avg_fitness = total_fitness / _fitness_scores.size().f64()
    
    // Report progress via the reporter
    match best_genome
    | let genome: Array[U8] val =>
      _reporter.tick(_generation, best_fitness, avg_fitness, genome)
      
      // Save best genome periodically
      if (_generation % 50) == 0 then
        _reporter.save_best(_generation, best_fitness, genome)
      end
    end
    
    // Check termination conditions
    if ((not _ignore_perfect_fitness) and (best_fitness >= _domain.perfect_fitness())) or 
       (_generation >= _target_generation) then
      _finish_evolution(best_fitness, best_genome)
      return
    end
    
    // Create next generation
    _create_next_generation(best_fitness)
    
    // Continue evolution
    _evaluate_population()

  fun ref _create_next_generation(best_fitness: F64) =>
    """Create the next generation using selection, crossover, and mutation."""
    let new_population = Array[Array[U8] val](_config.population_size())
    
    // Elitism: keep best genomes
    let elite_indices = _get_best_indices(_config.elitism_count())
    for idx in elite_indices.values() do
      try
        new_population.push(_population(idx)?)
      end
    end
    
    // Fill rest with offspring
    while new_population.size() < _config.population_size() do
      if _rng.real() < _config.crossover_rate() then
        // Crossover
        let parent1 = _tournament_selection()
        let parent2 = _tournament_selection()
        (let child1, let child2) = _genome_ops.crossover(_rng, parent1, parent2)
        
        let offspring = if (_rng.next() % 2) == 0 then child1 else child2 end
        let final_offspring = if _rng.real() < _config.mutation_rate() then
          if (best_fitness < 0.1) and (_rng.real() < 0.3) then
            _genome_ops.heavy_mutate(_rng, offspring)
          else
            _genome_ops.mutate(_rng, offspring)
          end
        else
          offspring
        end
        
        new_population.push(final_offspring)
      else
        // Mutation only
        let parent = _tournament_selection()
        let mutated = if (best_fitness < 0.1) and (_rng.real() < 0.2) then
          _genome_ops.heavy_mutate(_rng, parent)
        else
          _genome_ops.mutate(_rng, parent)
        end
        new_population.push(mutated)
      end
    end
    
    _population = new_population
    _fitness_scores = Array[F64](_config.population_size())
    for i in Range[USize](0, _config.population_size()) do
      _fitness_scores.push(0.0)
    end

  fun ref _tournament_selection(): Array[U8] val =>
    """Select parent using tournament selection."""
    var best_fitness: F64 = -1.0
    var best_genome: Array[U8] val = recover val Array[U8](0) end
    
    for _ in Range[USize](0, _config.tournament_size()) do
      try
        let idx = _rng.next().usize() % _population.size()
        let fitness = _fitness_scores(idx)?
        if fitness > best_fitness then
          best_fitness = fitness
          best_genome = _population(idx)?
        end
      end
    end
    
    best_genome

  fun ref _get_best_indices(count: USize): Array[USize] =>
    """Get indices of the best genomes using simple selection."""
    let result = Array[USize](count)
    let used = Array[Bool](_fitness_scores.size())
    
    // Initialize used array
    for j in Range[USize](0, _fitness_scores.size()) do
      used.push(false)
    end
    
    // Find the top 'count' genomes
    for _ in Range[USize](0, count) do
      var best_idx: USize = 0
      var best_fitness: F64 = -1.0
      var found = false
      
      for i in Range[USize](0, _fitness_scores.size()) do
        try
          if not used(i)? then
            let fitness = _fitness_scores(i)?
            if (not found) or (fitness > best_fitness) then
              best_idx = i
              best_fitness = fitness
              found = true
            end
          end
        end
      end
      
      if found then
        result.push(best_idx)
        try used(best_idx)? = true end
      end
    end
    
    result

  fun ref _finish_evolution(best_fitness: F64, best_genome: (Array[U8] val | None)) =>
    """Complete the evolution process."""
    match best_genome
    | let genome: Array[U8] val =>
      _env.out.print("\nEvolution completed!")
      _env.out.print("Final fitness: " + best_fitness.string())
      _env.out.print("Generation: " + _generation.string())
      _env.out.print("")
      _env.out.print(_domain.display_result(genome))
      _reporter.save_best(_generation, best_fitness, genome)
    | None =>
      _env.out.print("Evolution failed - no valid genome found")
    end
    
    _running = false

actor FitnessWorker[D: ProblemDomain val, G: GenomeOperations val, C: GAConfiguration val]
  """
  Worker actor for parallel fitness evaluation.
  """
  let _controller: ParallelGAController[D, G, C] tag
  let _domain: D

  new create(controller: ParallelGAController[D, G, C] tag, domain: D) =>
    _controller = controller
    _domain = domain

  be evaluate_genome(worker_id: USize, genome_id: USize, genome: Array[U8] val) =>
    """Evaluate fitness of a genome and report back to controller."""
    let fitness = _domain.evaluate(genome)
    _controller.fitness_result(worker_id, genome_id, fitness)