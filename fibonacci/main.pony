use "collections"
use "random"
use "time"
use "files"

use @printf[I32](fmt: Pointer[U8] tag, ...)

// -------------------------
// Terminology in this file:
// Genome = raw bytes (the evolvable program)
// Instructions = interpreted form of a Genome for execution
// Execution = run the instructions as a VM program for a given n
// -------------------------

// ===== VM + Genome spec =====
primitive OPCODE
  fun nop(): U8 => 0
  fun zero(): U8 => 1       // ZERO dst         -> R[dst] = 0
  fun inc(): U8 => 2        // INC  dst         -> R[dst] = 1 + R[dst]
  fun mov(): U8 => 3        // MOV  dst, src    -> R[dst] = R[src]
  fun add(): U8 => 4        // ADD  dst, src    -> R[dst] = R[dst] + R[src]
  fun swap(): U8 => 5       // SWAP a, b        -> swap R[a], R[b]
  fun loadn(): U8 => 6      // LOADN dst        -> R[dst] = n (loop count)
  fun const1(): U8 => 7     // CONST1 dst       -> R[dst] = 1
  fun const0(): U8 => 8     // CONST0 dst       -> R[dst] = 0

primitive VMConfig
  fun reg_count(): U8 => 4          // R0..R3
  fun prog_len(): USize => 16       // instructions per genome
  fun instr_bytes(): USize => 3     // [opcode, dst, src_or_b]
  fun genome_len(): USize => prog_len() * instr_bytes()

// Decode helpers
primitive _Clamp
  fun reg(i: U8): U8 => i % VMConfig.reg_count()
  fun opc(x: U8): U8 =>
    let m: U8 = 9
    x % m

// Execute a genome for a given n; return predicted Fib(n) as I64 via R0.
primitive VM
  fun run(genome: Array[U8] box, n: USize): I64 =>
    var r: Array[I64] = Array[I64](VMConfig.reg_count().usize())
    r.push(0); r.push(1); r.push(0); r.push(0)  // R0=0, R1=1, R2=0, R3=0
    let l = VMConfig.prog_len().usize()
    let step_bytes = VMConfig.instr_bytes().usize()

    // Execute program body for n steps (so loops can emerge)
    var t: USize = 0
    while t < n do
      var ip: USize = 0
      while ip < l do
        let base = ip * step_bytes
        let op: U8  = _Clamp.opc(try genome(base)? else 0 end)
        let a: U8   = _Clamp.reg(try genome(base + 1)? else 0 end)
        let b: U8   = _Clamp.reg(try genome(base + 2)? else 0 end)

        match op
        | OPCODE.nop() => None
        | OPCODE.zero() => try r(a.usize())? = 0 end
        | OPCODE.inc() => try r(a.usize())? = r(a.usize())? + 1 end
        | OPCODE.mov() => try r(a.usize())? = r(b.usize())? end
        | OPCODE.add() => try r(a.usize())? = r(a.usize())? + r(b.usize())? end
        | OPCODE.swap() =>
          try
            let tmp: I64 = r(a.usize())?
            r(a.usize())? = r(b.usize())?
            r(b.usize())? = tmp
          end
        | OPCODE.loadn() => try r(a.usize())? = n.i64() end
        | OPCODE.const1() => try r(a.usize())? = 1 end
        | OPCODE.const0() => try r(a.usize())? = 0 end
        else None
        end
        ip = ip + 1
      end
      t = t + 1
    end
    // Output register:
    try r(0)? else 0 end

// ===== Fibonacci ground truth =====
primitive Fib
  fun fib(n: USize): I64 =>
    if n < 2 then n.i64() end
    var a: I64 = 0
    var b: I64 = 1
    var i: USize = 1
    while i < n do
      let tmp: I64 = a + b
      a = b
      b = tmp
      i = i + 1
    end
    b

// ===== Tests / Fitness =====
primitive Suite
  // Training set and holdout to encourage generality
  fun train_ns(): Array[USize] val =>
    recover val
      let xs = Array[USize]
      xs.push(0); xs.push(1); xs.push(2); xs.push(3); xs.push(4)
      xs.push(5); xs.push(6); xs.push(7); xs.push(8); xs.push(9); xs.push(10)
      xs
    end
  fun hold_ns(): Array[USize] val =>
    recover val
      let xs = Array[USize]
      xs.push(11); xs.push(12); xs.push(13); xs.push(14)
      xs
    end

  fun fitness(genome: Array[U8] box): F64 =>
    // Lower error -> higher fitness. Bound and normalize.
    var err: F64 = 0
    for n in train_ns().values() do
      let yhat: I64 = VM.run(genome, n)
      let y: I64 = Fib.fib(n)
      let d: F64 = (yhat - y).f64()
      err = err + (d * d)
    end
    // Convert to fitness: 1 / (1 + RMSE)
    let rmse: F64 = (err / train_ns().size().f64()).sqrt()
    1.0 / (1.0 + rmse)

// ===== GA machinery =====
trait val FitnessSink
  be got_fit(id: USize, f: F64)

actor Evaluator
  be eval(id: USize, genome: Array[U8] val, sink: FitnessSink tag) =>
    let fit = Suite.fitness(genome)
    sink.got_fit(id, fit)

primitive GAConf
  fun pop(): USize => 250
  fun gens(): USize => 400
  fun workers(): USize => 8
  fun tournament_k(): USize => 5
  fun mutation_rate(): F64 => 0.06       // prob per byte to mutate
  fun mutation_sigma(): U8 => 8          // random tweak scale
  fun elite(): USize => 2

primitive GAOps
  fun random_genome(rng: Rand): Array[U8] val =>
    let n = VMConfig.genome_len().usize()
    recover val
      let buf = Array[U8](n)
      var i: USize = 0
      while i < n do
        buf.push(rng.next().u8())
        i = i + 1
      end
      buf
    end

  fun mutate(rng: Rand, g: Array[U8] box): Array[U8] val =>
    let n = g.size()
    let bytes = recover iso Array[U8 val](n) end
    for i in Range[USize](0, n) do
      var b: U8 = try g(i)? else 0 end
      // With some probability, tweak this byte slightly (or random flip)
      let p: F64 = (rng.next().f64() / U64.max_value().f64())
      if p < GAConf.mutation_rate() then
        let delta: U8 = (rng.next().u8() % GAConf.mutation_sigma())
        if (rng.next().u8() and 1) == 1 then
          b = b + delta
        else
          b = b - delta
        end
      end
      bytes.push(b)
    end
    consume bytes

  fun crossover(rng: Rand, a: Array[U8] box, b: Array[U8] box): (Array[U8] val, Array[U8] val) =>
    let n = a.size()
    if n == 0 then
      (recover val Array[U8] end, recover val Array[U8] end)
    else
      let cut: USize = (rng.next().usize() % n)
      let c1 = recover iso Array[U8 val](n) end
      let c2 = recover iso Array[U8 val](n) end
      for i in Range[USize](0, n) do
        if i < cut then
          c1.push(try a(i)? else 0 end)
          c2.push(try b(i)? else 0 end)
        else
          c1.push(try b(i)? else 0 end)
          c2.push(try a(i)? else 0 end)
        end
      end
      (consume c1, consume c2)
    end

actor Reporter
  let _env: Env
  new create(env: Env) => _env = env

  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val) =>
    @printf[I32]("gen=%lu best=%.5f avg=%.5f\n".cstring(), gen, best, avg)
    // Optional: quick check on holdout
    var hold_err: F64 = 0
    for n in Suite.hold_ns().values() do
      let yhat: I64 = VM.run(genome, n)
      let y: I64 = Fib.fib(n)
      let d: F64 = (yhat - y).f64()
      hold_err = hold_err + (d * d)
    end
    let rmse: F64 = (hold_err / Suite.hold_ns().size().f64()).sqrt()
    @printf[I32]("  holdout_rmse=%.5f | sample: F(12)=%lld, got=%lld\n".cstring(),
      rmse, Fib.fib(12), VM.run(genome, 12))

  be save_best(gen: USize, fitness: F64, genome: Array[U8] val) =>
    _env.out.print("Saving best genome - Gen: " + gen.string() + " Fitness: " + fitness.string())

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
      @printf[I32]("DONE. Best fitness %.6f  Example: F(15)=%lld got=%lld\n".cstring(),
        bestf, Fib.fib(15), VM.run(_pop(besti)?, 15))
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

actor Main
  new create(env: Env) =>
    GAController(env)