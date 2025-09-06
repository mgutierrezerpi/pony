// Fitness evaluation for genomes
// Measures how well a genome's execution matches the expected Fibonacci sequence

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

trait val FitnessSink
  be got_fit(id: USize, f: F64)

actor Evaluator
  be eval(id: USize, genome: Array[U8] val, sink: FitnessSink tag) =>
    let fit = Suite.fitness(genome)
    sink.got_fit(id, fit)

actor Reporter
  let _env: Env
  new create(env: Env) => _env = env

  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val) =>
    _env.out.print("gen=" + gen.string() + " best=" + best.string() + " avg=" + avg.string())
    // Optional: quick check on holdout
    var hold_err: F64 = 0
    for n in Suite.hold_ns().values() do
      let yhat: I64 = VM.run(genome, n)
      let y: I64 = Fib.fib(n)
      let d: F64 = (yhat - y).f64()
      hold_err = hold_err + (d * d)
    end
    let rmse: F64 = (hold_err / Suite.hold_ns().size().f64()).sqrt()
    _env.out.print("  holdout_rmse=" + rmse.string() + " | sample: F(12)=" + Fib.fib(12).string() + ", got=" + VM.run(genome, 12).string())

  be save_best(gen: USize, fitness: F64, genome: Array[U8] val) =>
    _env.out.print("Saving best genome - Gen: " + gen.string() + " Fitness: " + fitness.string())