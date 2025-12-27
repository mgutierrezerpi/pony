// VM Powers of 2 - Nucleo-aware but much simpler!

use "collections"
use "../_framework"

primitive VMPowersOfTwo is VMProblem
  """
  VM-aware powers of 2 evolution.
  Respects nucleos but way less code than the full version!
  """
  
  fun nucleos_per_genome(): USize => 16
  
  fun fitness(genome: Array[U8] val): F64 =>
    """Test on powers of 2 from 0 to 9"""
    var correct: USize = 0
    
    // Test all cases: 2^0 through 2^9
    for n in Range[USize](0, 10) do
      let expected = _pow2(n)
      let result = VM.run(genome, n)
      if result == expected then correct = correct + 1 end
    end
    
    correct.f64() / 10.0  // Return fraction correct
  
  fun display(genome: Array[U8] val): String =>
    """Show test results"""
    var output = "Powers: "
    let display_cases: Array[USize] = [0; 1; 2; 3; 4; 5]
    for n in display_cases.values() do
      let result = VM.run(genome, n)
      let expected = _pow2(n)
      output = output + "2^" + n.string() + "=" + result.string()
      if result == expected then output = output + "✓ " else output = output + "✗ " end
    end
    output
  
  fun _pow2(n: USize): USize =>
    """Calculate 2^n"""
    if n == 0 then return 1 end
    var result: USize = 1
    for _ in Range[USize](0, n) do result = result * 2 end
    result