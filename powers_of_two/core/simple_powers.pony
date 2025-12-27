// Simplified Powers of 2 Problem - much less code!

use "random"
use "collections"
use "../../_framework"

primitive PowersOfTwo is SimpleProblem
  """
  Evolve VM programs to compute 2^n.
  Just 3 methods needed instead of massive boilerplate!
  """
  
  fun genome_size(): USize => 48  // 16 nucleos × 3 bytes
  
  fun fitness(genome: Array[U8] val): F64 =>
    """Test how well this genome computes powers of 2"""
    var correct: F64 = 0
    let total_tests: F64 = 12
    
    // Test fixed cases: 2^0 through 2^7
    for n in Range[USize](0, 8) do
      let expected = _pow2(n)
      let got = VM.run(genome, n)
      if got == expected then correct = correct + 1 end
    end
    
    // Test random cases: pick 4 random powers
    let rng = Rand(42)  // Fixed seed for consistent testing
    for _ in Range[USize](0, 4) do
      let n = rng.next().usize() % 10  // 2^0 to 2^9
      let expected = _pow2(n)
      let got = VM.run(genome, n)
      if got == expected then correct = correct + 1 end
    end
    
    correct / total_tests  // Return percentage correct
  
  fun display(genome: Array[U8] val): String =>
    """Show what this genome produces"""
    var result = "Results: "
    for n in Range[USize](0, 6) do
      let got = VM.run(genome, n)
      let expected = _pow2(n)
      result = result + "2^" + n.string() + "=" + got.string()
      if got == expected then result = result + "✓ " else result = result + "✗ " end
    end
    result
  
  fun _pow2(n: USize): USize =>
    """Calculate 2^n the boring way"""
    if n == 0 then return 1 end
    var result: USize = 1
    for _ in Range[USize](0, n) do result = result * 2 end
    result

// Optional: Custom configuration for powers of 2
primitive PowersConfig is SimpleConfig
  fun population(): USize => 200     // Larger population for complex problem
  fun generations(): USize => 2000   // More generations needed
  fun mutation_rate(): F64 => 0.15   // Higher mutation for exploration
  fun perfect_score(): F64 => 0.99   // 99% accuracy is "perfect"