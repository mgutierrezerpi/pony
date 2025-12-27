// Generic Genetic Algorithm Controller
// Manages population evolution independent of problem domain
//
// This controller implements the evolutionary process for nucleo-based genomes:
// 1. NUCLEOS: Atomic operations that serve as basic building blocks
// 2. CODONS: Functional sequences formed by combining nucleos
// 3. GENOMES: Complete sequences of nucleos that evolve into effective solutions
//
// Features:
// - Adaptive diversity management (responds to evolutionary stagnation)
// - Tournament selection for parent choice
// - Elitism to preserve best solutions
// - Multiple mutation strategies based on population health
// - Real-time progress reporting and genome persistence

use "random"
use "collections"
use "time"

actor GenericGAController[T: ProblemDomain val, O: GenomeOperations val, C: GAConfiguration val] is FitnessReceiver
  """
  Main genetic algorithm engine that evolves populations of genomes.
  
  Type Parameters:
  - T: Problem domain that defines fitness evaluation and genome structure
  - O: Genetic operations (mutation, crossover) that respect nucleo/codon boundaries
  - C: Configuration parameters (population size, selection pressure, etc.)
  
  The controller maintains the population and orchestrates the evolution cycle:
  Generation Loop -> Fitness Evaluation -> Selection -> Reproduction -> Next Generation
  """
  // Core system components
  let _env: Env                    // Environment for I/O and system access
  let _rng: Rand                   // Random number generator for genetic operations
  let _reporter: ReportSink tag    // Actor for progress reporting and genome persistence
  let _domain: T                   // Problem-specific domain (fitness evaluation, genome creation)
  let _ops: O                      // Genetic operations (mutation, crossover, heavy mutation)
  let _config: C                   // Evolution parameters (population size, selection pressure)
  
  // Population state
  var _pop: Array[Array[U8] val] ref = _pop.create()  // Current population of genomes
  var _fit: Array[F64] ref = _fit.create()            // Fitness scores for each genome
  var _pending: USize = 0                             // Number of pending fitness evaluations
  
  // Evolution progress tracking
  var _gen: USize = 0                    // Current generation number
  var _max_gens: USize = 0               // Maximum generations (0 = no limit)
  var _stagnant_gens: USize = 0          // Generations without improvement
  var _last_best_fitness: F64 = 0.0      // Best fitness from previous generation

  new create(env: Env, domain: T, ops: O, config: C, reporter: ReportSink tag) =>
    """
    Creates a new GA controller and starts unlimited evolution.
    
    Parameters:
    - env: System environment for I/O operations
    - domain: Problem domain defining fitness evaluation and genome structure
    - ops: Genetic operations that understand nucleo/codon structure
    - config: Evolution parameters (population size, mutation rates, etc.)
    - reporter: Actor for progress updates and genome persistence
    
    Immediately begins evolution by creating initial population and evaluating fitness.
    """
    _env = env
    _domain = domain
    _ops = ops
    _config = config
    _rng = Rand(Time.nanos(), Time.millis())  // Seed with current time for randomness
    _reporter = reporter
    _max_gens = 0 // No generation limit - evolve until perfect solution found
    _init_pop()   // Create initial random population
    _eval_pop()   // Start fitness evaluation process
  
  new with_limit(env: Env, domain: T, ops: O, config: C, reporter: ReportSink tag, max_gens: USize) =>
    """
    Creates a new GA controller with a generation limit.
    
    Same as create() but stops evolution after max_gens generations even if
    perfect solution is not found. Useful for time-bounded experiments.
    """
    _env = env
    _domain = domain
    _ops = ops
    _config = config
    _rng = Rand(Time.nanos(), Time.millis())
    _reporter = reporter
    _max_gens = max_gens  // Stop after this many generations
    _init_pop()
    _eval_pop()

  fun ref _init_pop() =>
    """
    Initializes the population with completely random genomes.
    
    Creates a diverse starting population where each genome is a random
    sequence of nucleos. This genetic diversity is essential for evolution
    to explore the solution space effectively.
    """
    _pop.clear()
    for _ in Range[USize](0, _config.population_size()) do
      _pop.push(_domain.random_genome(_rng))  // Generate random nucleo sequence
    end
  
  be _eval_pop() =>
    """
    Evaluates the fitness of all genomes in the current population.
    
    This is the "Execute" phase of the evolution cycle where each genome
    is run against test cases to measure how well its nucleos combine into
    effective codons for solving the problem.
    
    Uses asynchronous evaluation - fitness results come back via got_fit().
    """
    _fit = Array[F64](_pop.size())   // Prepare fitness array
    _fit.undefined(_pop.size())      // Pre-allocate space
    _pending = _pop.size()           // Track how many evaluations are pending
    
    var i: USize = 0
    while i < _pop.size() do
      try _eval_genome(i, _pop(i)?) end  // Evaluate each genome
      i = i + 1
    end
  
  fun _eval_genome(id: USize, genome: Array[U8] val) =>
    """
    Evaluates a single genome's fitness.
    
    In a parallel implementation, this would dispatch to worker actors.
    For now, it evaluates synchronously and sends the result back to got_fit().
    
    The domain's evaluate() method tests how well the genome's nucleos
    work together to solve the problem (e.g., compute powers of 2).
    """
    // In real implementation, this would dispatch to parallel worker actors
    let fitness = _domain.evaluate(genome)  // Run genome against test cases
    got_fit(id, fitness)                    // Send result back asynchronously

  be got_fit(id: USize, fitness: F64) =>
    """
    Receives a fitness evaluation result.
    
    This is called when a genome's fitness evaluation completes.
    When all evaluations are done (_pending reaches 0), triggers
    the next phase of evolution.
    """
    try _fit(id)? = fitness end                        // Store the fitness score
    if _pending > 0 then _pending = _pending - 1 end   // Decrement pending counter
    if _pending == 0 then try _finish_gen()? end end   // All done? Process generation

  fun ref _finish_gen() ? =>
    """
    Completes a generation after all fitness evaluations are done.
    
    This is the "Measure" and "Select" phase of the evolution cycle:
    1. Calculate population statistics (best, average fitness)
    2. Report progress and save elite genomes
    3. Check termination conditions (perfect solution, generation limit)
    4. Create next generation if continuing
    """
    _gen = _gen + 1
    
    // MEASURE PHASE: Calculate population statistics
    var bestf: F64 = -1e300      // Track best fitness
    var besti: USize = 0          // Track best genome index
    var sum: F64 = 0              // Sum for average calculation
    var i: USize = 0
    while i < _pop.size() do
      let f: F64 = _fit(i)?       // Get fitness for this genome
      if f > bestf then bestf = f; besti = i end  // Track best performer
      sum = sum + f               // Add to sum for average
      i = i + 1
    end
    let avg: F64 = sum / _pop.size().f64()        // Calculate average fitness
    
    // Report progress to external systems (console, file persistence, etc.)
    _reporter.tick(_gen, bestf, avg, _pop(besti)?)      // Generation summary
    _reporter.save_best(_gen, bestf, _pop(besti)?)      // Save elite genome
    
    // Track evolutionary stagnation (no improvement in best fitness)
    // This drives adaptive diversity mechanisms
    if bestf <= _last_best_fitness then
      _stagnant_gens = _stagnant_gens + 1    // No improvement - increment stagnation
    else
      _stagnant_gens = 0                     // Improvement found - reset stagnation
      _last_best_fitness = bestf             // Update best fitness benchmark
    end
    
    // TERMINATION CONDITIONS: Check if evolution should stop
    
    // Success condition: Perfect or near-perfect solution found
    if bestf >= _domain.perfect_fitness() then
      _env.out.print("PERFECT! Achieved fitness " + bestf.string() + " at generation " + _gen.string())
      _env.out.print("Final evolved solution: " + _domain.display_result(_pop(besti)?))
      return  // Evolution complete - stop here
    end
    
    // Time limit condition: Maximum generations reached
    if (_max_gens > 0) and (_gen >= _max_gens) then
      _env.out.print("Max generations reached. Best fitness: " + bestf.string())
      _env.out.print("Best evolved solution: " + _domain.display_result(_pop(besti)?))
      return  // Time limit reached - stop evolution
    end
    
    // Continue evolution: Create next generation and evaluate it
    _next_generation(besti, bestf)?  // REPRODUCE PHASE: Create offspring
    _eval_pop()                      // EXECUTE PHASE: Evaluate new population

  fun ref _next_generation(best_idx: USize, best_fitness: F64) ? =>
    """
    Creates the next generation through selection, reproduction, and mutation.
    
    This is the "REPRODUCE" phase implementing sophisticated adaptive evolution:
    
    1. ADAPTIVE DIVERSITY: Responds to evolutionary stagnation by:
       - Increasing mutation rates when population converges
       - Injecting fresh random genomes when stuck in local optima
       - Reducing elitism when ultra-stagnant to force exploration
    
    2. ELITISM: Preserves best solutions to prevent losing good nucleos/codons
    
    3. SELECTION: Uses tournament selection to choose parents
    
    4. CROSSOVER: Combines nucleo sequences from two parents
    
    5. MUTATION: Applies various mutation strategies:
       - Light mutation: Small changes preserving codon structure
       - Heavy mutation: Large changes breaking codons for exploration
    
    The balance between these operations adapts based on population health.
    """
    let nextp = Array[Array[U8] val](_pop.size())  // Next generation population
    
    // ADAPTIVE DIVERSITY MECHANISM: Detect different levels of stagnation
    // These thresholds trigger increasingly aggressive diversity measures
    let is_very_stagnant = _stagnant_gens > 100      // Minor stagnation
    let is_extremely_stagnant = _stagnant_gens > 500  // Serious stagnation
    let is_ultra_stagnant = _stagnant_gens > 1000     // Critical stagnation
    
    // ELITISM: Preserve best solutions to maintain evolutionary progress
    // Reduce elitism during ultra-stagnation to force more exploration
    let elitism_count = if is_ultra_stagnant then 1 else _config.elitism_count() end
    nextp.push(_pop(best_idx)?)  // Always keep the absolute best genome
    
    // Keep other elite individuals (high-fitness genomes) if not ultra-stagnant
    // This preserves valuable nucleo combinations that work well
    if elitism_count > 1 then
      for idx in Range[USize](0, _pop.size()) do
        if (idx != best_idx) and (nextp.size() < elitism_count) then
          // Keep genomes within 5% of best fitness (likely have good codons)
          if _fit(idx)? > (best_fitness * 0.95) then
            nextp.push(_pop(idx)?)
          end
        end
      end
    end
    
    // FRESH GENOME INJECTION: Break out of local optima with new random material
    // When evolution is stuck, inject completely new nucleo sequences
    if is_ultra_stagnant then
      let fresh_count = _pop.size() / 4  // Replace 25% with fresh genomes
      for _ in Range[USize](0, fresh_count) do
        if nextp.size() < _pop.size() then
          // Add completely random nucleo sequences to explore new areas
          nextp.push(_domain.random_genome(_rng))
        end
      end
    end
    
    // MAIN REPRODUCTION LOOP: Fill remaining population through evolution
    while nextp.size() < _pop.size() do
      // ADAPTIVE RANDOMNESS: Probability of using random genome vs evolution
      // More stagnation = higher chance of random injection
      let use_random = if is_ultra_stagnant then
        (_rng.next() % 2) == 0      // 50% random genomes
      elseif is_extremely_stagnant then
        (_rng.next() % 3) == 0      // 33% random genomes
      elseif is_very_stagnant then
        (_rng.next() % 5) == 0      // 20% random genomes
      else
        (_rng.next() % 20) == 0     // 5% random genomes (normal operation)
      end
      
      if use_random then
        // Inject completely random genome to increase diversity
        nextp.push(_domain.random_genome(_rng))
      else
        // STANDARD EVOLUTIONARY REPRODUCTION:
        
        // 1. SELECTION: Choose parents through tournament selection
        let a = _tournament()?  // Parent A: winner of tournament
        let b = _tournament()?  // Parent B: winner of tournament
        
        // 2. CROSSOVER: Combine nucleo sequences from both parents
        // This preserves good codons while creating new combinations
        (let c1, let c2) = _ops.crossover(_rng, _pop(a)?, _pop(b)?)
        
        // 3. MUTATION: Apply adaptive mutations based on stagnation level
        let mutation_type = _rng.next() % 10  // Random mutation selector
        
        // ADAPTIVE MUTATION STRATEGY: More stagnation = more heavy mutations
        // Heavy mutations break codon structures for exploration
        // Light mutations preserve codons while making small improvements
        let use_heavy = (is_ultra_stagnant and (mutation_type < 8)) or      // 80% heavy
                       (is_extremely_stagnant and (mutation_type < 7)) or   // 70% heavy
                       (is_very_stagnant and (mutation_type < 4))           // 40% heavy
                       // Normal operation: 10% heavy mutations
        
        // Apply chosen mutation strategy to first offspring
        if use_heavy then
          // Heavy mutation: Break existing codon patterns, explore new combinations
          nextp.push(_ops.heavy_mutate(_rng, c1))
        else
          // Light mutation: Preserve codon structure, make incremental improvements
          nextp.push(_ops.mutate(_rng, c1))
        end
        
        // Apply same mutation strategy to second offspring if there's room
        if nextp.size() < _pop.size() then
          if use_heavy then
            nextp.push(_ops.heavy_mutate(_rng, c2))
          else
            nextp.push(_ops.mutate(_rng, c2))
          end
        end
      end
    end
    
    // Replace old population with new generation
    _pop = nextp

  fun ref _tournament(): USize ? =>
    """
    Tournament selection: Chooses a parent genome for reproduction.
    
    Process:
    1. Randomly select K individuals from population (K = tournament_size)
    2. The individual with highest fitness wins the tournament
    3. Return the winner's index for use in crossover
    
    This creates selection pressure (better genomes more likely to reproduce)
    while maintaining diversity (weaker genomes still have a chance).
    
    Tournament selection is particularly good for nucleo-based evolution because:
    - It preserves genomes with good codon combinations
    - It allows some weaker genomes to contribute useful nucleos
    - It's robust to fitness scaling issues
    """
    // Start with a random individual as initial winner
    var winner: USize = _rng.next().usize() % _pop.size()
    var wf: F64 = _fit(winner)?  // Winner's fitness
    
    // Compare with other tournament participants
    var j: USize = 1
    while j < _config.tournament_size() do
      let ix: USize = _rng.next().usize() % _pop.size()  // Random participant
      let fx: F64 = _fit(ix)?                            // Participant's fitness
      if fx > wf then winner = ix; wf = fx end           // Better fitness wins
      j = j + 1
    end
    winner  // Return index of tournament winner