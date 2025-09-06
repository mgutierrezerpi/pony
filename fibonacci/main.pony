// Fibonacci Genetic Algorithm
//
// Terminology:
// - Genome: Raw bytes representing an evolvable VM program
// - Execution: Running the VM instructions for a given input n
// - Fitness: How well the genome's execution matches expected results
//
// This project evolves VM programs that learn to compute Fibonacci numbers
// through genetic algorithms, without knowing the algorithm beforehand.

use "files"
use "collections"

actor Main
  new create(env: Env) =>
    let args = env.args
    
    try
      if args.size() <= 1 then
        // Default: check if we should resume or start fresh
        if _should_resume(env) then
          env.out.print("Resuming from best saved genome...")
          GAController.resume(env)
        else
          env.out.print("Starting fresh training...")  
          GAController(env)
        end
      else
        match args(1)?
        | "train" => 
          env.out.print("Training mode...")
          GAController(env)
        | "resume" => 
          env.out.print("Resuming training...")
          if args.size() > 2 then
            try
              let generations = args(2)?.usize()?
              GAController.resume_with_limit(env, generations)
            else
              env.out.print("Invalid generations number: " + args(2)?)
            end
          else
            GAController.resume(env)
          end
        | "test" =>
          if args.size() > 2 then
            _test_genome(env, args(2)?)
          else
            env.out.print("Usage: fibonacci test <generation_number>")
          end
        | "clear" =>
          _clear_generations(env)
        else
          // Check if it's a number to compute Fibonacci for
          try
            let n = args(1)?.usize()?
            _compute_fibonacci(env, n)
          else
            _show_usage(env)
          end
        end
      end
    else
      _show_usage(env)
    end
  
  fun _should_resume(env: Env): Bool =>
    // Check if we have saved genomes and the latest one has fitness < 1.0
    let auth = FileAuth(env.root)
    // Find the highest generation number
    var max_gen: USize = 0
    var found = false
    
    // Search backwards from a high number to find the latest generation efficiently  
    var gen: USize = 100000
    while gen > 0 do
      let gen_padded = _pad_generation(gen)
      let path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".yml")
      if path.exists() then
        max_gen = gen
        found = true
        break
      end
      gen = gen - 1
    end
    
    if found then
      // Read the fitness from the latest generation file
      let gen_padded = _pad_generation(max_gen) 
      let path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".yml")
      let file = File.open(path)
      let content = file.read_string(file.size())
      file.dispose()
      
      // Parse fitness from YAML (simple string matching)
      if content.contains("fitness: 1.0") or content.contains("fitness: 1") then
        false // Perfect fitness, don't resume
      else
        true  // Can improve, should resume
      end
    else
      false // No saved genomes found
    end
  
  fun _pad_generation(gen: USize): String =>
    if gen < 10 then
      "00" + gen.string()
    elseif gen < 100 then
      "0" + gen.string()  
    else
      gen.string()
    end
  
  fun _test_genome(env: Env, gen_str: String) =>
    try
      let gen = gen_str.usize()?
      let gen_padded = _pad_generation(gen)
      let auth = FileAuth(env.root)
      let bytes_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      
      if not bytes_path.exists() then
        env.out.print("Genome file not found: " + bytes_path.path)
        return
      end
      
      let file = File.open(bytes_path)
      let genome_bytes = file.read(48)
      file.dispose()
      
      if genome_bytes.size() != 48 then
        env.out.print("Invalid genome file size: " + genome_bytes.size().string())
        return
      end
      
      // Convert to val array
      let genome = recover val
        let arr = Array[U8](48)
        for b in (consume genome_bytes).values() do
          arr.push(b)
        end
        arr
      end
      
      env.out.print("Testing genome from generation " + gen_str + ":")
      for n in Range[USize](0, 20) do
        let result = VM.run(genome, n)
        let expected = Fib.fib(n)
        let status = if result == expected then "✓" else "✗" end
        env.out.print("F(" + n.string() + ")=" + expected.string() + " got=" + result.string() + " " + status)
      end
    else
      env.out.print("Invalid generation number: " + gen_str)
    end
  
  fun _compute_fibonacci(env: Env, n: USize) =>
    // Find the best trained genome
    let auth = FileAuth(env.root)
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
      let gen_padded = _pad_generation(max_gen)
      let bytes_path = FilePath(auth, "fibonacci/bin/best_genome_gen_" + gen_padded + ".bytes")
      
      let file = File.open(bytes_path)
      let genome_bytes = file.read(48)
      file.dispose()
      
      if genome_bytes.size() == 48 then
        // Convert to val array
        let genome = recover val
          let arr = Array[U8](48)
          for b in (consume genome_bytes).values() do
            arr.push(b)
          end
          arr
        end
        
        let result = VM.run(genome, n)
        env.out.print("F(" + n.string() + ") = " + result.string())
      else
        env.out.print("Error: Invalid genome file")
      end
    else
      env.out.print("Error: No trained genome found. Run training first with: fibonacci train")
    end
  
  fun _clear_generations(env: Env) =>
    let auth = FileAuth(env.root)
    let dir_path = FilePath(auth, "fibonacci/bin")
    
    if not dir_path.exists() then
      env.out.print("No fibonacci/bin directory found")
      return
    end
    
    var count: USize = 0
    try
      let dir = Directory(dir_path)?
      
      for entry in dir.entries()?.values() do
        let name = entry
        if name.contains("best_genome_gen_") and (name.contains(".yml") or name.contains(".bytes")) then
          let file_path = FilePath(auth, "fibonacci/bin/" + name)
          if file_path.exists() then
            if file_path.remove() then
              count = count + 1
            else
              env.out.print("Failed to remove: " + name)
            end
          end
        end
      end
      
      if count > 0 then
        env.out.print("Cleared " + count.string() + " generation files")
      else
        env.out.print("No generation files found to clear")
      end
    else
      env.out.print("Failed to access fibonacci/bin directory")
    end
  
  fun _show_usage(env: Env) =>
    env.out.print("Usage:")
    env.out.print("  fibonacci                - Auto-resume if possible, otherwise train")  
    env.out.print("  fibonacci train          - Start fresh training")
    env.out.print("  fibonacci resume         - Resume from best saved genome (unlimited)")
    env.out.print("  fibonacci resume <GENS>  - Resume for exactly GENS generations")
    env.out.print("  fibonacci test <N>       - Test saved genome from generation N")
    env.out.print("  fibonacci clear          - Remove all saved generation files")
    env.out.print("  fibonacci <N>            - Compute F(N) using best trained genome")