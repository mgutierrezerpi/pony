// Evolution controller - manages the genetic algorithm process
// Handles population management, selection, and generational updates

use "random"
use "collections"
use "files"

actor GAController is FitnessSink
  let _env: Env
  let _rng: Rand
  let _report: Reporter tag
  let _workers: USize
  var _pop: Array[Array[U8] val] ref = _pop.create()
  var _fit: Array[F64] ref = _fit.create()
  var _pending: USize = 0
  var _gen: USize = 0
  var _max_gens: USize = 0
  var _stagnant_gens: USize = 0
  var _last_best_fitness: F64 = 0.0

  new create(env: Env) =>
    _env = env
    _rng = Rand
    _report = Reporter(env)
    _workers = GAConf.workers()
    _max_gens = GAConf.gens()
    _init_pop()
    _eval_pop()
  
  new resume(env: Env) =>
    _env = env
    _rng = Rand
    _report = Reporter(env)
    _workers = GAConf.workers()
    _max_gens = 10000 // Very high limit for resume to allow continued evolution
    _init_from_saved()
    _eval_pop()
  
  new resume_with_limit(env: Env, additional_gens: USize) =>
    _env = env
    _rng = Rand
    _report = Reporter(env)
    _workers = GAConf.workers()
    _max_gens = 0 // Will be set in _init_from_saved_with_limit
    _init_from_saved_with_limit(additional_gens)
    _eval_pop()

  fun ref _init_pop() =>
    _pop.clear()
    for _ in Range[USize](0, GAConf.pop()) do
      _pop.push(GAOps.random_genome(_rng))
    end
  
  fun ref _init_from_saved() =>
    _pop.clear()
    
    // Find the highest generation and load its best genome
    let auth = FileAuth(_env.root)
    var max_gen: USize = 0
    var found = false
    
    // Search backwards from a high number to find the latest generation efficiently
    var gen: USize = 100000
    while gen > 0 do
      let gen_padded = _pad_generation(gen)
      let path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      if path.exists() then
        max_gen = gen
        found = true
        break
      end
      gen = gen - 1
    end
    
    if found then
      _gen = max_gen
      _stagnant_gens = 0  // Reset stagnation counter on resume
      _last_best_fitness = 0.0  // Will be updated on first evaluation
      _env.out.print("Loading best genome from generation " + max_gen.string())
      
      let gen_padded = _pad_generation(max_gen)
      let bytes_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      let file = File.open(bytes_path)
      let genome_bytes = file.read(48)
      file.dispose()
      
      if genome_bytes.size() == 48 then
        // Convert to val array
        let best_genome = recover val
          let arr = Array[U8](48)
          for b in (consume genome_bytes).values() do
            arr.push(b)
          end
          arr
        end
        
        // Start population with the best genome and random variations
        _pop.push(best_genome)
        
        // Fill rest of population with mutations of the best genome
        for _ in Range[USize](1, GAConf.pop()) do
          let r = _rng.next() % 6
          if r == 0 then
            // ~17% completely random genomes for diversity
            _pop.push(GAOps.random_genome(_rng))
          elseif r == 1 then
            // ~17% heavy mutations for escaping local optima
            _pop.push(GAOps.heavy_mutate(_rng, best_genome))
          else
            // ~66% regular mutations of the best genome
            _pop.push(GAOps.mutate(_rng, best_genome))
          end
        end
      else
        _env.out.print("Error: Invalid genome file size, falling back to random population")
        _gen = 0
        _init_pop()
      end
    else
      _env.out.print("No saved genomes found, starting fresh")
      _gen = 0
      _init_pop()
    end
  
  fun ref _init_from_saved_with_limit(additional_gens: USize) =>
    _pop.clear()
    
    // Find the highest generation and load its best genome
    let auth = FileAuth(_env.root)
    var max_gen: USize = 0
    var found = false
    
    // Search backwards from a high number to find the latest generation efficiently
    var gen: USize = 100000
    while gen > 0 do
      let gen_padded = _pad_generation(gen)
      let path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      if path.exists() then
        max_gen = gen
        found = true
        break
      end
      gen = gen - 1
    end
    
    if found then
      _gen = max_gen
      _max_gens = _gen + additional_gens // Set limit to current + additional
      _stagnant_gens = 0  // Reset stagnation counter on resume
      _last_best_fitness = 0.0  // Will be updated on first evaluation
      _env.out.print("Loading best genome from generation " + max_gen.string())
      _env.out.print("Will run for " + additional_gens.string() + " more generations (until gen " + _max_gens.string() + ")")
      
      let gen_padded = _pad_generation(max_gen)
      let bytes_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      let file = File.open(bytes_path)
      let genome_bytes = file.read(48)
      file.dispose()
      
      if genome_bytes.size() == 48 then
        // Convert to val array
        let best_genome = recover val
          let arr = Array[U8](48)
          for b in (consume genome_bytes).values() do
            arr.push(b)
          end
          arr
        end
        
        // Start population with the best genome and random variations
        _pop.push(best_genome)
        
        // Fill rest of population with mutations of the best genome
        for _ in Range[USize](1, GAConf.pop()) do
          let r = _rng.next() % 6
          if r == 0 then
            // ~17% completely random genomes for diversity
            _pop.push(GAOps.random_genome(_rng))
          elseif r == 1 then
            // ~17% heavy mutations for escaping local optima
            _pop.push(GAOps.heavy_mutate(_rng, best_genome))
          else
            // ~66% regular mutations of the best genome
            _pop.push(GAOps.mutate(_rng, best_genome))
          end
        end
      else
        _env.out.print("Error: Invalid genome file size, falling back to random population")
        _gen = 0
        _max_gens = additional_gens
        _init_pop()
      end
    else
      _env.out.print("No saved genomes found, starting fresh for " + additional_gens.string() + " generations")
      _gen = 0
      _max_gens = additional_gens
      _init_pop()
    end
  
  fun _pad_generation(gen: USize): String =>
    if gen < 10 then
      "00" + gen.string()
    elseif gen < 100 then
      "0" + gen.string()
    else
      gen.string()
    end

  be _eval_pop() =>
    _fit = Array[F64](_pop.size()); _fit.undefined(_pop.size())
    _pending = _pop.size()
    var i: USize = 0
    while i < _pop.size() do
      try Evaluator.eval(i, _pop(i)?, this) end
      i = i + 1
    end

  be got_fit(id: USize, f: F64) =>
    try _fit(id)? = f end
    if _pending > 0 then _pending = _pending - 1 end
    if _pending == 0 then try _finish_gen()? end end

  fun ref _finish_gen() ? =>
    _gen = _gen + 1
    // stats
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
    _report.tick(_gen, bestf, avg, _pop(besti)?)
    if (_gen % 25) == 0 then _report.save_best(_gen, bestf, _pop(besti)?) end

    // Track stagnation
    if bestf <= _last_best_fitness then
      _stagnant_gens = _stagnant_gens + 1
    else
      _stagnant_gens = 0
      _last_best_fitness = bestf
    end

    // Check for perfect fitness first (terminate early if achieved)
    if bestf >= 0.99999 then
      _report.save_best(_gen, bestf, _pop(besti)?)
      _env.out.print("PERFECT! Achieved fitness " + bestf.string() + " at generation " + _gen.string())
      _env.out.print("DONE. Best fitness " + bestf.string() + " Example: F(15)=" + Fib.fib(15).string() + " got=" + VM.run(_pop(besti)?, 15).string())
      return
    end
    
    if _gen >= _max_gens then
      _report.save_best(_gen, bestf, _pop(besti)?)
      _env.out.print("DONE. Best fitness " + bestf.string() + " Example: F(15)=" + Fib.fib(15).string() + " got=" + VM.run(_pop(besti)?, 15).string())
      return
    end

    // Next generation with adaptive diversity based on stagnation
    let nextp = Array[Array[U8] val](_pop.size())
    
    // If we've been stagnant for too long, be more aggressive
    let is_very_stagnant = _stagnant_gens > 100
    let is_extremely_stagnant = _stagnant_gens > 500
    
    // ALWAYS keep the best - never throw it away completely
    nextp.push(_pop(besti)?)
    
    // Keep top 5 when not making progress to preserve good solutions
    if bestf > 0.5 then
      // Sort population by fitness to find top performers
      let sorted_indices = Array[USize](_pop.size())
      for idx in Range[USize](0, _pop.size()) do
        sorted_indices.push(idx)
      end
      // Simple selection of top 5 (already have best at index besti)
      for idx in Range[USize](0, _pop.size()) do
        if (idx != besti) and (nextp.size() < 5) then
          try
            if _fit(idx)? > (bestf * 0.95) then
              nextp.push(_pop(idx)?)
            end
          end
        end
      end
    end

    // Fill rest by tournament selection + crossover + mutation
    while nextp.size() < _pop.size() do
      // Increase randomness based on stagnation but not too extreme
      let use_random = if is_extremely_stagnant then
        (_rng.next() % 3) == 0  // 33% random when extremely stagnant (not 50%)
      elseif is_very_stagnant then
        (_rng.next() % 5) == 0  // 20% random when very stagnant (not 25%)
      else
        (_rng.next() % 20) == 0 // 5% random normally
      end
      
      if use_random then
        nextp.push(GAOps.random_genome(_rng))
      else
        let a: USize = _tournament()?
        let b: USize = _tournament()?
        (let c1, let c2) = GAOps.crossover(_rng, _pop(a)?, _pop(b)?)
        
        // More aggressive mutations when stagnant
        let mutation_type = _rng.next() % 10
        if is_very_stagnant and (mutation_type < 4) then
          // 40% heavy mutation when very stagnant
          nextp.push(GAOps.heavy_mutate(_rng, c1))
        elseif is_extremely_stagnant and (mutation_type < 7) then
          // 70% heavy mutation when extremely stagnant
          nextp.push(GAOps.heavy_mutate(_rng, c1))
        else
          nextp.push(GAOps.mutate(_rng, c1))
        end
        
        if nextp.size() < _pop.size() then
          if use_random then
            nextp.push(GAOps.random_genome(_rng))
          elseif is_very_stagnant and (mutation_type < 4) then
            nextp.push(GAOps.heavy_mutate(_rng, c2))
          else
            nextp.push(GAOps.mutate(_rng, c2))
          end
        end
      end
    end
    _pop = nextp
    _eval_pop()

  fun ref _tournament(): USize ? =>
    var winner: USize = _rng.next().usize() % _pop.size()
    var wf: F64 = _fit(winner)?
    var j: USize = 1
    while j < GAConf.tournament_k() do
      let ix: USize = _rng.next().usize() % _pop.size()
      let fx: F64 = _fit(ix)?
      if fx > wf then winner = ix; wf = fx end
      j = j + 1
    end
    winner