// Evolution controller - manages the genetic algorithm process
// Handles population management, selection, and generational updates

use "random"
use "collections"

actor GAController is FitnessSink
  let _env: Env
  let _rng: Rand
  let _report: Reporter tag
  let _workers: USize
  var _pop: Array[Array[U8] val] ref = _pop.create()
  var _fit: Array[F64] ref = _fit.create()
  var _pending: USize = 0
  var _gen: USize = 0

  new create(env: Env) =>
    _env = env
    _rng = Rand
    _report = Reporter(env)
    _workers = GAConf.workers()
    _init_pop()
    _eval_pop()

  fun ref _init_pop() =>
    _pop.clear()
    for _ in Range[USize](0, GAConf.pop()) do
      _pop.push(GAOps.random_genome(_rng))
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

    if _gen >= GAConf.gens() then
      _report.save_best(_gen, bestf, _pop(besti)?)
      _env.out.print("DONE. Best fitness " + bestf.string() + " Example: F(15)=" + Fib.fib(15).string() + " got=" + VM.run(_pop(besti)?, 15).string())
      return
    end

    // Next generation with elitism
    let nextp = Array[Array[U8] val](_pop.size())
    // keep elites
    nextp.push(_pop(besti)?)
    var second_best: USize = besti
    var best2: F64 = -1e300
    i = 0
    while i < _pop.size() do
      if i != besti then
        let f2: F64 = _fit(i)?
        if f2 > best2 then best2 = f2; second_best = i end
      end
      i = i + 1
    end
    nextp.push(_pop(second_best)?)

    // Fill rest by tournament selection + crossover + mutation
    while nextp.size() < _pop.size() do
      let a: USize = _tournament()?
      let b: USize = _tournament()?
      (let c1, let c2) = GAOps.crossover(_rng, _pop(a)?, _pop(b)?)
      nextp.push(GAOps.mutate(_rng, c1))
      if nextp.size() < _pop.size() then nextp.push(GAOps.mutate(_rng, c2)) end
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