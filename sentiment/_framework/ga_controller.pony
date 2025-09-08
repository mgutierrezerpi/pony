// Generic Genetic Algorithm Controller
// Manages population evolution independent of problem domain

use "random"
use "collections"
use "time"

actor GenericGAController[T: ProblemDomain val, O: GenomeOperations val, C: GAConfiguration val] is FitnessReceiver
  let _env: Env
  let _rng: Rand
  let _reporter: ReportSink tag
  let _domain: T
  let _ops: O
  let _config: C
  
  var _pop: Array[Array[U8] val] ref = _pop.create()
  var _fit: Array[F64] ref = _fit.create()
  var _pending: USize = 0
  var _gen: USize = 0
  var _max_gens: USize = 0
  var _stagnant_gens: USize = 0
  var _last_best_fitness: F64 = 0.0

  new create(env: Env, domain: T, ops: O, config: C, reporter: ReportSink tag) =>
    _env = env
    _domain = domain
    _ops = ops
    _config = config
    _rng = Rand(Time.nanos(), Time.millis())
    _reporter = reporter
    _max_gens = 0 // No limit by default
    _init_pop()
    _eval_pop()
  
  new with_limit(env: Env, domain: T, ops: O, config: C, reporter: ReportSink tag, max_gens: USize) =>
    _env = env
    _domain = domain
    _ops = ops
    _config = config
    _rng = Rand(Time.nanos(), Time.millis())
    _reporter = reporter
    _max_gens = max_gens
    _init_pop()
    _eval_pop()

  fun ref _init_pop() =>
    _pop.clear()
    for _ in Range[USize](0, _config.population_size()) do
      _pop.push(_domain.random_genome(_rng))
    end
  
  be _eval_pop() =>
    _fit = Array[F64](_pop.size())
    _fit.undefined(_pop.size())
    _pending = _pop.size()
    
    var i: USize = 0
    while i < _pop.size() do
      try _eval_genome(i, _pop(i)?) end
      i = i + 1
    end
  
  fun _eval_genome(id: USize, genome: Array[U8] val) =>
    // In real implementation, this would dispatch to workers
    let fitness = _domain.evaluate(genome)
    got_fit(id, fitness)

  be got_fit(id: USize, fitness: F64) =>
    try _fit(id)? = fitness end
    if _pending > 0 then _pending = _pending - 1 end
    if _pending == 0 then try _finish_gen()? end end

  fun ref _finish_gen() ? =>
    _gen = _gen + 1
    
    // Calculate statistics
    var bestf: F64 = -1e300
    var besti: USize = 0
    var sum: F64 = 0
    var i: USize = 0
    while i < _pop.size() do
      let f: F64 = _fit(i)?
      if f > bestf then bestf = f; besti = i end
      sum = sum + f
      i = i + 1
    end
    let avg: F64 = sum / _pop.size().f64()
    
    // Report progress
    _reporter.tick(_gen, bestf, avg, _pop(besti)?)
    _reporter.save_best(_gen, bestf, _pop(besti)?)
    
    // Track stagnation
    if bestf <= _last_best_fitness then
      _stagnant_gens = _stagnant_gens + 1
    else
      _stagnant_gens = 0
      _last_best_fitness = bestf
    end
    
    // Check termination conditions
    if bestf >= _domain.perfect_fitness() then
      _env.out.print("PERFECT! Achieved fitness " + bestf.string() + " at generation " + _gen.string())
      _env.out.print("Result: " + _domain.display_result(_pop(besti)?))
      return
    end
    
    if (_max_gens > 0) and (_gen >= _max_gens) then
      _env.out.print("Max generations reached. Best fitness: " + bestf.string())
      _env.out.print("Result: " + _domain.display_result(_pop(besti)?))
      return
    end
    
    // Create next generation
    _next_generation(besti, bestf)?
    _eval_pop()

  fun ref _next_generation(best_idx: USize, best_fitness: F64) ? =>
    let nextp = Array[Array[U8] val](_pop.size())
    
    // Adaptive diversity based on stagnation
    let is_very_stagnant = _stagnant_gens > 100
    let is_extremely_stagnant = _stagnant_gens > 500
    let is_ultra_stagnant = _stagnant_gens > 1000
    
    // Elitism - always keep the best
    let elitism_count = if is_ultra_stagnant then 1 else _config.elitism_count() end
    nextp.push(_pop(best_idx)?)
    
    // Keep other elite individuals if not ultra-stagnant
    if elitism_count > 1 then
      for idx in Range[USize](0, _pop.size()) do
        if (idx != best_idx) and (nextp.size() < elitism_count) then
          if _fit(idx)? > (best_fitness * 0.95) then
            nextp.push(_pop(idx)?)
          end
        end
      end
    end
    
    // Inject fresh genomes when stagnant
    if is_ultra_stagnant then
      let fresh_count = _pop.size() / 4
      for _ in Range[USize](0, fresh_count) do
        if nextp.size() < _pop.size() then
          nextp.push(_domain.random_genome(_rng))
        end
      end
    end
    
    // Fill rest with selection, crossover, and mutation
    while nextp.size() < _pop.size() do
      let use_random = if is_ultra_stagnant then
        (_rng.next() % 2) == 0
      elseif is_extremely_stagnant then
        (_rng.next() % 3) == 0
      elseif is_very_stagnant then
        (_rng.next() % 5) == 0
      else
        (_rng.next() % 20) == 0
      end
      
      if use_random then
        nextp.push(_domain.random_genome(_rng))
      else
        let a = _tournament()?
        let b = _tournament()?
        (let c1, let c2) = _ops.crossover(_rng, _pop(a)?, _pop(b)?)
        
        // Apply mutations with varying intensity based on stagnation
        let mutation_type = _rng.next() % 10
        let use_heavy = (is_ultra_stagnant and (mutation_type < 8)) or
                       (is_extremely_stagnant and (mutation_type < 7)) or
                       (is_very_stagnant and (mutation_type < 4))
        
        if use_heavy then
          nextp.push(_ops.heavy_mutate(_rng, c1))
        else
          nextp.push(_ops.mutate(_rng, c1))
        end
        
        if nextp.size() < _pop.size() then
          if use_heavy then
            nextp.push(_ops.heavy_mutate(_rng, c2))
          else
            nextp.push(_ops.mutate(_rng, c2))
          end
        end
      end
    end
    
    _pop = nextp

  fun ref _tournament(): USize ? =>
    var winner: USize = _rng.next().usize() % _pop.size()
    var wf: F64 = _fit(winner)?
    var j: USize = 1
    while j < _config.tournament_size() do
      let ix: USize = _rng.next().usize() % _pop.size()
      let fx: F64 = _fit(ix)?
      if fx > wf then winner = ix; wf = fx end
      j = j + 1
    end
    winner