// Example: Using the GA framework to evolve text strings
// This demonstrates how the framework can be reused for different problem domains

use "random"
use "../_framework"

primitive TextMatchingDomain is ProblemDomain
  """
  Problem domain for evolving text strings to match a target.
  """
  
  fun target(): String => "Hello, World!"
  
  fun genome_size(): USize => target().size()
  
  fun random_genome(rng: Rand): Array[U8] val =>
    recover val
      let arr = Array[U8](genome_size())
      for _ in Range[USize](0, genome_size()) do
        // Generate printable ASCII characters (space to ~)
        arr.push(32 + (rng.next().u8() % 95))
      end
      arr
    end
  
  fun evaluate(genome: Array[U8] val): F64 =>
    """
    Evaluate fitness by comparing to target string.
    """
    let target_bytes = target().array()
    var matches: F64 = 0
    
    for i in Range[USize](0, genome_size()) do
      try
        if genome(i)? == target_bytes(i)? then
          matches = matches + 1.0
        else
          // Partial credit for being close in ASCII value
          let diff = (genome(i)?.i32() - target_bytes(i)?.i32()).abs()
          if diff < 10 then
            matches = matches + (1.0 - (diff.f64() / 10.0))
          end
        end
      end
    end
    
    matches / genome_size().f64()
  
  fun perfect_fitness(): F64 => 0.99999
  
  fun display_result(genome: Array[U8] val): String =>
    let result = String.from_array(genome)
    "Got: \"" + result + "\" (Target: \"" + target() + "\")"

primitive TextGenomeOps is GenomeOperations
  """
  Text-specific genome operations.
  """
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Mutate 1-2 characters.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      let mutations = 1 + (rng.next().usize() % 2)
      for _ in Range[USize](0, mutations) do
        try
          let pos = rng.next().usize() % arr.size()
          // Mutate to nearby ASCII character
          let current = arr(pos)?
          let delta = (rng.next().i8() % 5) - 2 // -2 to +2
          let new_val = (current.i32() + delta.i32()).u8()
          if (new_val >= 32) and (new_val <= 126) then
            arr(pos)? = new_val
          else
            arr(pos)? = 32 + (rng.next().u8() % 95)
          end
        end
      end
      arr
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Mutate many characters.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      let mutations = genome.size() / 3
      for _ in Range[USize](0, mutations) do
        try
          let pos = rng.next().usize() % arr.size()
          arr(pos)? = 32 + (rng.next().u8() % 95)
        end
      end
      arr
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Standard two-point crossover.
    """
    ByteGenomeOps.crossover(rng, a, b)

primitive TextMatchConfig is GAConfiguration
  """
  Configuration for text matching GA.
  """
  fun population_size(): USize => 100
  fun tournament_size(): USize => 5
  fun worker_count(): USize => 1
  fun mutation_rate(): F64 => 0.05
  fun crossover_rate(): F64 => 0.8
  fun elitism_count(): USize => 10