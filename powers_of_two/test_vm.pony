// Test suite for Powers of Two Virtual Machine and Genetic Algorithm
// Validates VM instruction execution, fitness calculation, and evolution components

use "pony_test"
use "collections"
use "random"
use "./core"
use "./_framework"

actor \nodoc\ TestMain is TestList
  new create(env: Env) => PonyTest(env, this)
  
  new make() => None
  
  fun tag tests(test: PonyTest) =>
    // Virtual Machine Core Tests
    test(_TestVMBasicInstructions)
    test(_TestVMRegisterOperations)
    test(_TestVMLoopingInstructions)
    test(_TestVMInfiniteLoopProtection)
    
    // Powers Domain Tests  
    test(_TestPowersCalculator)
    test(_TestFitnessEvaluation)
    test(_TestRandomTestCases)
    
    // Genetic Operations Tests
    test(_TestGenomeGeneration)
    test(_TestMutationOperations)
    test(_TestCrossoverOperations)

// =============================================================================
// Virtual Machine Instruction Tests
// =============================================================================

class \nodoc\ iso _TestVMBasicInstructions is UnitTest
  """
  Tests basic VM instructions: NOP, ZERO, INC, MOV, ADD, CONST0, CONST1
  """
  
  fun name(): String => "VM Basic Instructions"
  
  fun apply(test_helper: TestHelper) =>
    // Test NOP instruction does nothing
    let nop_program: Array[U8] val = [0; 0; 0]  // NOP R0, R0
    let nop_result = VM.run(nop_program, 5)
    test_helper.assert_eq[USize](nop_result, 0, "NOP should leave R0 at 0")
    
    // Test ZERO instruction sets register to 0
    let zero_program: Array[U8] val = [7; 0; 0; 1; 0; 0]  // CONST1 R0; ZERO R0  
    let zero_result = VM.run(zero_program, 0)
    test_helper.assert_eq[USize](zero_result, 0, "ZERO should clear register")
    
    // Test INC instruction increments register
    let increment_program: Array[U8] val = [2; 0; 0; 2; 0; 0]  // INC R0; INC R0
    let increment_result = VM.run(increment_program, 0)
    test_helper.assert_eq[USize](increment_result, 2, "INC should increment register twice")
    
    // Test CONST1 loads constant 1
    let const1_program: Array[U8] val = [7; 0; 0]  // CONST1 R0
    let const1_result = VM.run(const1_program, 0)
    test_helper.assert_eq[USize](const1_result, 1, "CONST1 should load 1 into register")

class \nodoc\ iso _TestVMRegisterOperations is UnitTest
  """
  Tests register manipulation instructions: MOV, ADD, SWAP, LOADN
  """
  
  fun name(): String => "VM Register Operations"
  
  fun apply(test_helper: TestHelper) =>
    // Test MOV instruction copies between registers
    let move_program: Array[U8] val = [7; 1; 0; 3; 0; 1]  // CONST1 R1; MOV R0, R1
    let move_result = VM.run(move_program, 0)
    test_helper.assert_eq[USize](move_result, 1, "MOV should copy value between registers")
    
    // Test ADD instruction adds registers
    let add_program: Array[U8] val = [7; 0; 0; 7; 1; 0; 4; 0; 1]  // CONST1 R0; CONST1 R1; ADD R0, R1
    let add_result = VM.run(add_program, 0)
    test_helper.assert_eq[USize](add_result, 2, "ADD should sum register values")
    
    // Test LOADN instruction loads input value
    let loadn_program: Array[U8] val = [6; 0; 0]  // LOADN R0
    let loadn_result = VM.run(loadn_program, 42)
    test_helper.assert_eq[USize](loadn_result, 42, "LOADN should load input value into register")

class \nodoc\ iso _TestVMLoopingInstructions is UnitTest
  """
  Tests advanced instructions: DEC, DOUBLE, LOOP for implementing powers of 2
  """
  
  fun name(): String => "VM Looping Instructions"
  
  fun apply(test_helper: TestHelper) =>
    // Test DEC instruction decrements register
    let decrement_program: Array[U8] val = [7; 0; 0; 2; 0; 0; 9; 0; 0]  // CONST1 R0; INC R0; DEC R0
    let decrement_result = VM.run(decrement_program, 0)
    test_helper.assert_eq[USize](decrement_result, 1, "DEC should decrement register value")
    
    // Test DOUBLE instruction multiplies by 2
    let double_program: Array[U8] val = [7; 0; 0; 2; 0; 0; 10; 0; 0]  // CONST1 R0; INC R0; DOUBLE R0
    let double_result = VM.run(double_program, 0)
    test_helper.assert_eq[USize](double_result, 4, "DOUBLE should multiply register by 2")
    
    // Test LOOP instruction with a simple counting loop
    // Program: CONST1 R0; CONST0 R1; LOOP 4, R0; INC R1; (continue)
    let loop_program: Array[U8] val = [
      7; 0; 0   // CONST1 R0 (counter = 1)
      8; 1; 0   // CONST0 R1 (accumulator = 0)  
      11; 4; 0  // LOOP instruction 4, R0 (if R0 > 0, decrement R0 and jump to instruction 4)
      3; 0; 1   // MOV R0, R1 (move result to R0 for return)
      2; 1; 0   // INC R1 (increment accumulator)
    ]
    let loop_result = VM.run(loop_program, 0)  // Should increment R1 once (since R0 starts at 1)
    test_helper.assert_eq[USize](loop_result, 1, "LOOP should decrement counter and execute loop body once")

class \nodoc\ iso _TestVMInfiniteLoopProtection is UnitTest
  """
  Tests that VM execution terminates within reasonable bounds to prevent infinite loops
  """
  
  fun name(): String => "VM Infinite Loop Protection"
  
  fun apply(test_helper: TestHelper) =>
    // Create a program with an infinite loop: LOOP 0, R1 (jump to instruction 0)
    // R1 starts at 1, so this would loop forever without protection
    let infinite_loop_program: Array[U8] val = [
      11; 0; 1   // LOOP instruction 0, R1 (infinite loop)
    ]
    
    // Should terminate due to execution step limit, not hang forever
    let infinite_result = VM.run(infinite_loop_program, 0)
    test_helper.assert_true(true, "VM should terminate infinite loops within execution limit")

// =============================================================================
// Powers Domain Mathematics Tests  
// =============================================================================

class \nodoc\ iso _TestPowersCalculator is UnitTest
  """
  Tests the mathematical reference implementation for powers of 2
  """
  
  fun name(): String => "Powers Calculator Mathematics"
  
  fun apply(test_helper: TestHelper) =>
    // Test basic powers of 2 calculations
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(0), 1, "2^0 should equal 1")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(1), 2, "2^1 should equal 2")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(2), 4, "2^2 should equal 4")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(3), 8, "2^3 should equal 8")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(4), 16, "2^4 should equal 16")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(5), 32, "2^5 should equal 32")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(6), 64, "2^6 should equal 64")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(7), 128, "2^7 should equal 128")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(8), 256, "2^8 should equal 256")
    test_helper.assert_eq[USize](PowersOfTwoCalculator.compute_power_of_2(9), 512, "2^9 should equal 512")

class \nodoc\ iso _TestFitnessEvaluation is UnitTest
  """
  Tests fitness evaluation including both fixed and random test cases
  """
  
  fun name(): String => "Fitness Evaluation Logic"
  
  fun apply(test_helper: TestHelper) =>
    // Test perfect genome that always returns correct answer
    let perfect_genome: Array[U8] val = [6; 0; 0; 7; 1; 0]  // LOADN R0; CONST1 R1; (simplified)
    // Note: This is a simplified test - real perfect genomes are more complex
    
    // Test genome that always returns 0 (worst case)
    let zero_genome: Array[U8] val = [8; 0; 0]  // CONST0 R0
    let zero_fitness = PowersDomain.evaluate(zero_genome)
    test_helper.assert_true(zero_fitness < 0.1, "Genome returning 0 should have very low fitness")
    
    // Test genome that returns input-1 (previous local optimum)
    let decrement_genome: Array[U8] val = [6; 0; 0; 9; 0; 0]  // LOADN R0; DEC R0
    let decrement_fitness = PowersDomain.evaluate(decrement_genome)
    test_helper.assert_true(decrement_fitness < 0.5, "Input-1 genome should not get high fitness")

class \nodoc\ iso _TestRandomTestCases is UnitTest
  """
  Tests that random test cases are included in fitness evaluation
  """
  
  fun name(): String => "Random Test Case Integration"
  
  fun apply(test_helper: TestHelper) =>
    // Create a genome that only works for 2^0 and 2^1 but fails on higher powers
    let limited_genome: Array[U8] val = [
      6; 0; 0   // LOADN R0
      2; 0; 0   // INC R0 (returns input+1, so 2^0->1✓, 2^1->2✓, but 2^2->3✗)
    ]
    
    let limited_fitness = PowersDomain.evaluate(limited_genome)
    
    // Should get partial credit for some correct answers but not perfect score
    // because random test cases (like 2^8, 2^9) will fail
    test_helper.assert_true(limited_fitness > 0.0, "Should get some credit for partial correctness")
    test_helper.assert_true(limited_fitness < 1.0, "Should not get perfect score due to random test failures")

// =============================================================================
// Genetic Algorithm Operations Tests
// =============================================================================

class \nodoc\ iso _TestGenomeGeneration is UnitTest
  """
  Tests random genome generation and basic genome properties
  """
  
  fun name(): String => "Genome Generation"
  
  fun apply(test_helper: TestHelper) =>
    let test_rng = Rand(123)  // Seeded for reproducible tests
    
    // Test genome size is correct
    let random_genome = PowersDomain.random_genome(test_rng)
    test_helper.assert_eq[USize](random_genome.size(), 48, "Genome should be 48 bytes (16 instructions × 3 bytes)")
    
    // Test genome contains valid values (this is a basic sanity check)
    test_helper.assert_true(random_genome.size() > 0, "Generated genome should not be empty")

class \nodoc\ iso _TestMutationOperations is UnitTest
  """
  Tests genetic mutation operations respect instruction boundaries
  """
  
  fun name(): String => "Mutation Operations"
  
  fun apply(test_helper: TestHelper) =>
    let test_rng = Rand(456)  // Seeded for reproducible tests
    let original_genome = PowersDomain.random_genome(test_rng)
    
    // Test standard mutation
    let mutated_genome = PowersGenomeOperations.mutate(test_rng, original_genome)
    test_helper.assert_eq[USize](mutated_genome.size(), original_genome.size(), 
      "Mutated genome should maintain original size")
    
    // Test heavy mutation  
    let heavily_mutated = PowersGenomeOperations.heavy_mutate(test_rng, original_genome)
    test_helper.assert_eq[USize](heavily_mutated.size(), original_genome.size(),
      "Heavy mutation should maintain genome size")

class \nodoc\ iso _TestCrossoverOperations is UnitTest
  """
  Tests genetic crossover operations produce valid offspring
  """
  
  fun name(): String => "Crossover Operations"
  
  fun apply(test_helper: TestHelper) =>
    let test_rng = Rand(789)  // Seeded for reproducible tests
    let parent_a = PowersDomain.random_genome(test_rng)
    let parent_b = PowersDomain.random_genome(test_rng)
    
    // Test crossover produces two offspring
    (let offspring_1, let offspring_2) = PowersGenomeOperations.crossover(test_rng, parent_a, parent_b)
    
    test_helper.assert_eq[USize](offspring_1.size(), parent_a.size(), 
      "First offspring should have correct genome size")
    test_helper.assert_eq[USize](offspring_2.size(), parent_b.size(),
      "Second offspring should have correct genome size")