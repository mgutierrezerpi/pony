// Main entry point for powers of 2 genetic algorithm

use "random"
use "time"
use "files"
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
      | "summary" => _summary(env)
      | "test" => _test(env, args)
      else
        // Check if it's a number (compute 2^n)
        try
          let n = args(1)?.usize()?
          _compute_power(env, n)
        else
          _usage(env)
        end
      end
    else
      _usage(env)
    end
  
  fun _usage(env: Env) =>
    env.out.print("Usage:")
    env.out.print("  powers_of_two train              - Train from scratch")
    env.out.print("  powers_of_two resume [gens]      - Resume from last saved generation")
    env.out.print("  powers_of_two clear              - Clear all saved generations")
    env.out.print("  powers_of_two summary            - Generate evolution summary report")
    env.out.print("  powers_of_two test <n>           - Test VM with input n")
    env.out.print("  powers_of_two <n>                - Compute 2^n using best trained genome")
  
  fun _train(env: Env) =>
    env.out.print("=== Powers of 2 Evolution ===")
    env.out.print("Starting GA training for computing 2^n...")
    env.out.print("")
    
    let reporter = GenericReporter(env, "powers_of_two/bin/")
    GenericGAController[PowersDomain val, PowersGenomeOperations val, PowersEvolutionConfig val]
      .create(env, PowersDomain, PowersGenomeOperations, PowersEvolutionConfig, reporter)
  
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
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "powers_of_two/bin/")
    
    match genome
    | let g: Array[U8] val =>
      env.out.print("Resuming from generation " + gen.string())
      let reporter = GenericReporter(env, "powers_of_two/bin/")
      
      if limit > 0 then
        env.out.print("Will run for " + limit.string() + " more generations")
        GenericGAController[PowersDomain val, PowersGenomeOperations val, PowersEvolutionConfig val]
          .with_limit(env, PowersDomain, PowersGenomeOperations, PowersEvolutionConfig, reporter, gen + limit)
      else
        GenericGAController[PowersDomain val, PowersGenomeOperations val, PowersEvolutionConfig val]
          .create(env, PowersDomain, PowersGenomeOperations, PowersEvolutionConfig, reporter)
      end
    | None =>
      env.out.print("No saved genomes found, starting fresh")
      _train(env)
    end
  
  fun _clear(env: Env) =>
    env.out.print("Clearing all saved generations...")
    let deleted = GenomePersistence.clear_all_generations(env, "powers_of_two/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")
  
  fun _summary(env: Env) =>
    env.out.print("Generating evolution summary...")
    
    // Find the latest generation and best fitness
    (let latest_gen, let best_genome) = GenomePersistence.find_latest_generation(env, "powers_of_two/bin/")
    
    match best_genome
    | let genome: Array[U8] val =>
      let best_fitness = PowersDomain.evaluate(genome)
      
      // Create evolution summary in main project directory
      let success = EvolutionDataArchiver.create_evolution_summary_report(
        env, 
        "powers_of_two/",  // Save in main project directory instead of bin/
        latest_gen, 
        best_fitness, 
        latest_gen
      )
      
      if success then
        env.out.print("✓ Evolution summary saved to powers_of_two/evolution_summary.yaml")
        env.out.print("Latest generation: " + latest_gen.string())
        env.out.print("Best fitness: " + (best_fitness * 100).string() + "%")
        env.out.print("Best solution: " + PowersDomain.display_result(genome))
      else
        env.out.print("✗ Failed to save evolution summary")
      end
    | None =>
      env.out.print("No saved genomes found. Run training first.")
    end
  
  fun _test(env: Env, args: Array[String] val) =>
    try
      let n = args(2)?.usize()?
      
      // Create a simple test genome
      let rng = Rand(42)
      let genome = PowersDomain.random_genome(rng)
      let result = VM.run(genome, n)
      let expected = PowersOfTwoCalculator.compute_power_of_2(n)
      
      env.out.print("Test with n=" + n.string())
      env.out.print("Expected: 2^" + n.string() + " = " + expected.string())
      env.out.print("Got: " + result.string())
      env.out.print("Fitness: " + PowersDomain.evaluate(genome).string())
    else
      env.out.print("Usage: powers_of_two test <n>")
    end
  
  fun _compute_power(env: Env, n: USize) =>
    // Find and load the best trained genome
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "powers_of_two/bin/")
    
    match genome
    | let g: Array[U8] val =>
      let result = VM.run(g, n)
      let expected = PowersOfTwoCalculator.compute_power_of_2(n)
      
      env.out.print("Using genome from generation " + gen.string())
      env.out.print("2^" + n.string() + " = " + result.string())
      env.out.print("(Expected: " + expected.string() + ")")
      
      if result == expected then
        env.out.print("✓ Correct!")
      else
        if expected != 0 then
          let err_pct = ((result - expected).abs().f64() / expected.f64()) * 100
          env.out.print("✗ Error: " + err_pct.string() + "%")
        else
          env.out.print("✗ Incorrect")
        end
      end
      
      // Show the genome's overall fitness
      let fitness = PowersDomain.evaluate(g)
      env.out.print("")
      env.out.print("Genome fitness: " + (fitness * 100).string() + "%")
      env.out.print("Test cases passed: " + (fitness * 8).string() + " / 8")
    | None =>
      env.out.print("No trained genome found. Run 'powers_of_two train' first.")
    end