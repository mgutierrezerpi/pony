// Main entry point using the modular GA framework

use "files"
use "random"
use "_framework"
use "core"

actor Main
  new create(env: Env) =>
    let args = env.args
    if args.size() < 2 then
      _usage(env)
      return
    end
    
    try
      match args(1)?
      | "train" => _train(env)
      | "resume" => _resume(env, args)
      | "clear" => _clear(env)
      | "test" => _test(env, args)
      else
        // Check if it's a number (compute F(n))
        try
          let n = args(1)?.usize()?
          _compute_fibonacci(env, n)
        else
          _usage(env)
        end
      end
    else
      _usage(env)
    end
  
  fun _usage(env: Env) =>
    env.out.print("Usage:")
    env.out.print("  fibonacci train              - Train from scratch")
    env.out.print("  fibonacci resume [gens]      - Resume from last saved generation")
    env.out.print("  fibonacci clear              - Clear all saved generations")
    env.out.print("  fibonacci test <n>           - Test VM with input n")
    env.out.print("  fibonacci <n>                - Compute F(n) using best trained genome")
  
  fun _train(env: Env) =>
    env.out.print("Starting GA training for Fibonacci...")
    let reporter = GenericReporter(env, "fibonacci/bin/")
    GenericGAController[FibonacciDomain val, FibonacciGenomeOps val, FibonacciConfig val]
      .create(env, FibonacciDomain, FibonacciGenomeOps, FibonacciConfig, reporter)
  
  fun _resume(env: Env, args: Array[String] val) =>
    // Check if generation limit was provided
    let limit = try
      if args.size() >= 3 then
        args(2)?.usize()?
      else
        0
      end
    else
      0
    end
    
    // Load the latest generation
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "fibonacci/bin/")
    
    match genome
    | let g: Array[U8] val =>
      env.out.print("Resuming from generation " + gen.string())
      let reporter = GenericReporter(env, "fibonacci/bin/")
      
      if limit > 0 then
        env.out.print("Will run for " + limit.string() + " more generations")
        // Create controller with loaded state and limit
        GenericGAController[FibonacciDomain val, FibonacciGenomeOps val, FibonacciConfig val]
          .with_limit(env, FibonacciDomain, FibonacciGenomeOps, FibonacciConfig, reporter, gen + limit)
      else
        // Resume without limit
        GenericGAController[FibonacciDomain val, FibonacciGenomeOps val, FibonacciConfig val]
          .create(env, FibonacciDomain, FibonacciGenomeOps, FibonacciConfig, reporter)
      end
    | None =>
      env.out.print("No saved genomes found, starting fresh")
      _train(env)
    end
  
  fun _clear(env: Env) =>
    env.out.print("Clearing all saved generations...")
    let deleted = GenomePersistence.clear_all_generations(env, "fibonacci/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")
  
  fun _test(env: Env, args: Array[String] val) =>
    try
      let n = args(2)?.usize()?
      
      // Create a simple test genome
      let rng = Rand(42)
      let genome = FibonacciDomain.random_genome(rng)
      let result = VM.run(genome, n)
      let expected = Fib.fib(n)
      
      env.out.print("Test with n=" + n.string())
      env.out.print("Expected: F(" + n.string() + ") = " + expected.string())
      env.out.print("Got: " + result.string())
      env.out.print("Fitness: " + FibonacciDomain.evaluate(genome).string())
    else
      env.out.print("Usage: fibonacci test <n>")
    end
  
  fun _compute_fibonacci(env: Env, n: USize) =>
    // Find and load the best trained genome
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "fibonacci/bin/")
    
    match genome
    | let g: Array[U8] val =>
      let result = VM.run(g, n)
      let expected = Fib.fib(n)
      env.out.print("Using genome from generation " + gen.string())
      env.out.print("F(" + n.string() + ") = " + result.string())
      env.out.print("(Expected: " + expected.string() + ")")
      
      if result == expected then
        env.out.print("✓ Correct!")
      else
        let err = (((result - expected).abs().f64() / expected.f64()) * 100)
        env.out.print("✗ Error: " + err.string() + "%")
      end
    | None =>
      env.out.print("No trained genome found. Run 'fibonacci train' first.")
    end