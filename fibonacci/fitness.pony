// Fitness evaluation for genomes
// Measures how well a genome's execution matches the expected Fibonacci sequence

use "files"

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
    let auth = FileAuth(_env.root)
    let gen_padded = _pad_generation(gen)
    let yml_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".yml")
    let bytes_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
    let yml_file = File.create(yml_path)
    let bytes_file = File.create(bytes_path)
    
    // Write raw genome bytes to .bytes file
    for b in genome.values() do
      bytes_file.write(Array[U8](1).>push(b))
    end
    bytes_file.dispose()
    
    // Write YAML format
    yml_file.print("# Best Genome - Generation " + gen.string())
    yml_file.print("generation: " + gen.string())
    yml_file.print("fitness: " + fitness.string())
    yml_file.print("")
    
    // GA Configuration used
    yml_file.print("# Genetic Algorithm Configuration")
    yml_file.print("ga_config:")
    yml_file.print("  population_size: " + GAConf.pop().string())
    yml_file.print("  max_generations: " + GAConf.gens().string())
    yml_file.print("  tournament_size: " + GAConf.tournament_k().string())
    yml_file.print("  mutation_rate: " + GAConf.mutation_rate().string())
    yml_file.print("  mutation_sigma: " + GAConf.mutation_sigma().string())
    yml_file.print("  elite_count: " + GAConf.elite().string())
    yml_file.print("")
    
    // VM Configuration
    yml_file.print("# Virtual Machine Configuration")
    yml_file.print("vm_config:")
    yml_file.print("  register_count: " + VMConfig.reg_count().string())
    yml_file.print("  program_length: " + VMConfig.prog_len().string())
    yml_file.print("  instruction_bytes: " + VMConfig.instr_bytes().string())
    yml_file.print("  genome_size: " + VMConfig.genome_len().string() + " # bytes")
    yml_file.print("  genome_file: best_genome_gen_" + gen_padded + ".bytes")
    yml_file.print("")
    
    // Genome data (raw bytes stored in separate file)
    yml_file.print("# Genome Data")
    yml_file.print("genome:")
    yml_file.print("  size_bytes: " + genome.size().string())
    yml_file.print("  raw_bytes_file: best_genome_gen_" + gen_padded + ".bytes")
    yml_file.print("")
    
    // Test results
    yml_file.print("# Performance on Training Set")
    yml_file.print("training_results:")
    for n in Suite.train_ns().values() do
      let predicted = VM.run(genome, n)
      let actual = Fib.fib(n)
      let err = (predicted - actual).abs()
      yml_file.print("  fib_" + n.string() + ":")
      yml_file.print("    expected: " + actual.string())
      yml_file.print("    predicted: " + predicted.string())
      yml_file.print("    error: " + err.string())
    end
    yml_file.print("")
    
    // Holdout results
    yml_file.print("# Performance on Holdout Set")
    yml_file.print("holdout_results:")
    for n in Suite.hold_ns().values() do
      let predicted = VM.run(genome, n)
      let actual = Fib.fib(n)
      let err = (predicted - actual).abs()
      yml_file.print("  fib_" + n.string() + ":")
      yml_file.print("    expected: " + actual.string())
      yml_file.print("    predicted: " + predicted.string())
      yml_file.print("    error: " + err.string())
    end
    
    yml_file.dispose()
    _env.out.print("  -> Saved to fibonacci/bin/best_genome_gen_" + gen_padded + ".yml")
    _env.out.print("  -> Saved raw bytes to fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
  
  fun _pad_generation(gen: USize): String =>
    if gen < 10 then
      "00" + gen.string()
    elseif gen < 100 then
      "0" + gen.string()
    else
      gen.string()
    end

