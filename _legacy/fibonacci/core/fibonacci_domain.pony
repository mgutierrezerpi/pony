// Fibonacci-specific problem domain implementation

use "random"
use "collections"
use ".."
use "../_framework"

primitive FibonacciDomain is ProblemDomain
  """
  Problem domain for evolving VM programs that compute Fibonacci numbers.
  """
  
  fun genome_size(): USize => 48
  
  fun random_genome(rng: Rand): Array[U8] val =>
    recover val
      let arr = Array[U8](48)
      for _ in Range[USize](0, 48) do
        arr.push(rng.next().u8())
      end
      arr
    end
  
  fun evaluate(genome: Array[U8] val): F64 =>
    """
    Evaluate fitness by comparing VM output to actual Fibonacci values.
    """
    var score: F64 = 0
    let test_cases: Array[USize] = [0; 1; 2; 3; 5; 8; 10; 12; 15]
    
    for n in test_cases.values() do
      let expected = Fib.fib(n)
      let got = VM.run(genome, n)
      
      if expected == got then
        score = score + 1.0
      elseif expected != 0 then
        // Partial credit based on relative error
        let err = (expected - got).abs().f64() / expected.abs().f64()
        if err < 1.0 then
          score = score + (1.0 - err)
        end
      end
    end
    
    score / test_cases.size().f64()
  
  fun perfect_fitness(): F64 => 0.99999
  
  fun display_result(genome: Array[U8] val): String =>
    let n: USize = 15
    "F(" + n.string() + ")=" + Fib.fib(n).string() + " got=" + VM.run(genome, n).string()

primitive FibonacciGenomeOps is GenomeOperations
  """
  Specialized genome operations for VM instruction genomes.
  """
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Mutation aware of VM instruction structure (3-byte instructions).
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 1-2 complete instructions
      let mutations = 1 + (rng.next().usize() % 2)
      for _ in Range[USize](0, mutations) do
        try
          let instr_idx = rng.next().usize() % VMConfig.prog_len().usize()
          let base = instr_idx * 3
          
          // Mutate opcode or operands
          let what = rng.next() % 3
          if what == 0 then
            // New random opcode
            arr(base)? = rng.next().u8() % 9 // Number of opcodes
          else
            // New random register
            arr(base + what.usize())? = rng.next().u8() % VMConfig.reg_count()
          end
        end
      end
      arr
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation - randomizes many instructions.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 5-8 instructions
      let mutations = 5 + (rng.next().usize() % 4)
      for _ in Range[USize](0, mutations) do
        try
          let instr_idx = rng.next().usize() % VMConfig.prog_len().usize()
          let base = instr_idx * 3
          
          // Completely randomize the instruction
          arr(base)? = rng.next().u8() % 9 // Number of opcodes
          arr(base + 1)? = rng.next().u8() % VMConfig.reg_count()
          arr(base + 2)? = rng.next().u8() % VMConfig.reg_count()
        end
      end
      arr
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Crossover at instruction boundaries.
    """
    let prog_len = VMConfig.prog_len().usize()
    let p1 = rng.next().usize() % prog_len
    let p2 = rng.next().usize() % prog_len
    let start_instr = if p1 < p2 then p1 else p2 end
    let end_instr = if p1 < p2 then p2 else p1 end
    
    let start = start_instr * 3
    let end' = end_instr * 3
    
    (recover val
      let c1 = Array[U8](48)
      var i: USize = 0
      while i < 48 do
        try
          if (i >= start) and (i < end') then
            c1.push(b(i)?)
          else
            c1.push(a(i)?)
          end
        end
        i = i + 1
      end
      c1
    end,
    recover val
      let c2 = Array[U8](48)
      var i: USize = 0
      while i < 48 do
        try
          if (i >= start) and (i < end') then
            c2.push(a(i)?)
          else
            c2.push(b(i)?)
          end
        end
        i = i + 1
      end
      c2
    end)

primitive FibonacciConfig is GAConfiguration
  """
  Configuration for the Fibonacci GA.
  """
  fun population_size(): USize => 50
  fun tournament_size(): USize => 3
  fun worker_count(): USize => 8
  fun mutation_rate(): F64 => 0.1
  fun crossover_rate(): F64 => 0.7
  fun elitism_count(): USize => 5