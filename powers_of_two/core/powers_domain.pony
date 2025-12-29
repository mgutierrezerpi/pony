// Domain implementation for powers of 2 problem
// Evolves VM programs using nucleos (atomic operations) to compute 2^n

use "random"
use "collections"
use "../../_framework"
use "../../_framework/operators/mutations"

// Mathematical helper for computing powers of 2
primitive PowersOfTwoCalculator
  """
  Helper utility to compute the correct answer for powers of 2.
  Used for fitness evaluation and result verification.
  """
  
  fun compute_power_of_2(exponent: USize): USize =>
    """
    Computes 2^exponent using iterative multiplication.
    Examples: 2^0=1, 2^1=2, 2^2=4, 2^3=8, 2^4=16, etc.
    """
    if exponent == 0 then return 1 end
    
    var power_result: USize = 1
    for multiplication_step in Range[USize](0, exponent) do
      power_result = power_result * 2
    end
    power_result

primitive PowersDomain is ProblemDomain
  """
  Problem domain for evolving VM programs that compute powers of 2.
  
  The goal is to evolve a genome (VM program) that can correctly compute 2^n
  for any input n. The genome consists of 16 nucleos (atomic operations), each taking 3 bytes.
  Nucleos combine into codons (functional sequences) that achieve the computation.
  
  Test cases range from 2^0=1 to 2^7=128.
  """
  
  // Configuration constants
  fun genome_size(): USize => 48  // 16 nucleos × 3 bytes per nucleo
  
  fun random_genome(random_generator: Rand): Array[U8] val =>
    """
    Creates a completely random genome as starting point for evolution.
    Each byte is randomly generated, representing nucleo opcodes and operands.
    """
    recover val
      let genome_bytes = Array[U8](genome_size())
      for byte_index in Range[USize](0, genome_size()) do
        genome_bytes.push(random_generator.next().u8())
      end
      genome_bytes
    end
  
  fun evaluate(candidate_genome: Array[U8] val): F64 =>
    """
    Evaluates how well a genome performs on powers of 2 test cases.
    
    COMPREHENSIVE TESTING: Fixed test cases (0-7) + random test cases
    to prevent overfitting and ensure the solution generalizes well.
    """
    var total_fitness_score: F64 = 0.0
    
    // Fixed test cases: 2^0 through 2^7 (must get these right)
    let fixed_exponents: Array[USize] = [0; 1; 2; 3; 4; 5; 6; 7]
    
    for test_exponent in fixed_exponents.values() do
      let correct_answer = PowersOfTwoCalculator.compute_power_of_2(test_exponent)
      let genome_answer = VM.run(candidate_genome, test_exponent)
      
      if genome_answer == correct_answer then
        total_fitness_score = total_fitness_score + 1.0
      else
        if correct_answer > 0 then
          let error_ratio = (correct_answer - genome_answer).abs().f64() / correct_answer.f64()
          let partial_credit = (1.0 - error_ratio.min(1.0)) * 0.2  // More generous partial credit
          total_fitness_score = total_fitness_score + partial_credit
        end
      end
    end
    
    // Random test cases: Test with random exponents to prevent overfitting
    // Use seeded random generator for reproducible testing
    let test_rng = Rand(42)  // Fixed seed for consistent evaluation
    let random_test_count: USize = 4  // Test 4 additional random cases
    
    for _ in Range[USize](0, random_test_count) do
      let random_exponent = test_rng.next().usize() % 10  // Test 2^0 through 2^9
      let correct_answer = PowersOfTwoCalculator.compute_power_of_2(random_exponent)
      let genome_answer = VM.run(candidate_genome, random_exponent)
      
      if genome_answer == correct_answer then
        total_fitness_score = total_fitness_score + 1.0
      else
        if correct_answer > 0 then
          let error_ratio = (correct_answer - genome_answer).abs().f64() / correct_answer.f64()
          let partial_credit = (1.0 - error_ratio.min(1.0)) * 0.2  // More generous partial credit
          total_fitness_score = total_fitness_score + partial_credit
        end
      end
    end
    
    // Convert to percentage: total_score / total_test_count
    let total_test_count = fixed_exponents.size() + random_test_count
    total_fitness_score / total_test_count.f64()
  
  fun perfect_fitness(): F64 => 0.99999
  
  fun display_result(genome_to_display: Array[U8] val): String =>
    """
    Shows sample outputs from the genome for debugging/visualization.
    Tests both fixed cases and some random cases to show generalization.
    """
    var results_summary = "Powers of 2 results: "
    
    // Show fixed test cases
    let fixed_cases: Array[USize] = [0; 1; 2; 3; 4; 5]
    for test_case in fixed_cases.values() do
      let genome_result = VM.run(genome_to_display, test_case)
      let expected_result = PowersOfTwoCalculator.compute_power_of_2(test_case)
      
      results_summary = results_summary + "2^" + test_case.string() + "=" + genome_result.string()
      
      if genome_result == expected_result then
        results_summary = results_summary + "✓ "
      else
        results_summary = results_summary + "(exp:" + expected_result.string() + ") "
      end
    end
    
    // Show a couple random cases for generalization testing
    results_summary = results_summary + "| Random: "
    let random_cases: Array[USize] = [8; 9]  // Test 2^8=256, 2^9=512
    for test_case in random_cases.values() do
      let genome_result = VM.run(genome_to_display, test_case)
      let expected_result = PowersOfTwoCalculator.compute_power_of_2(test_case)
      
      results_summary = results_summary + "2^" + test_case.string() + "=" + genome_result.string()
      
      if genome_result == expected_result then
        results_summary = results_summary + "✓ "
      else
        results_summary = results_summary + "(exp:" + expected_result.string() + ") "
      end
    end
    
    results_summary

primitive PowersGenomeOperations is GenomeOperations
  """
  Genetic operations (mutation, crossover) specialized for VM nucleo genomes.
  Uses the reusable VMMutations operator from the framework!

  VM nucleo format:
  - Each nucleo is 3 bytes: [opcode, destination_register, source_register]
  - 12 different nucleo types (opcodes 0-11)
  - 4 registers (0-3)
  """

  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Standard mutation: modifies 1-2 random nucleos.
    Uses generic VMMutations operator with VM-specific constraints.
    """
    let mutation_count = 1 + (rng.next().usize() % 2)
    let constraints: Array[(U8, U8)] val = [(0, 11); (0, 3); (0, 3)]  // opcode 0-11, regs 0-3

    VMMutations.mutate_instructions(rng, genome, 3, mutation_count, constraints)

  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation: randomizes 5-8 complete nucleos.
    Uses generic VMMutations operator - much cleaner than custom code!
    """
    let mutation_count = 5 + (rng.next().usize() % 4)
    let constraints: Array[(U8, U8)] val = [(0, 11); (0, 3); (0, 3)]

    VMMutations.heavy_mutate_instructions(rng, genome, 3, mutation_count, constraints)

  fun crossover(rng: Rand, parent_a: Array[U8] val, parent_b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Two-point crossover that respects nucleo boundaries.
    Uses generic VMMutations crossover operator.
    """
    VMMutations.crossover_instructions(rng, parent_a, parent_b, 3)

primitive PowersEvolutionConfig is GAConfiguration
  """
  Genetic Algorithm configuration parameters for powers of 2 evolution.

  These parameters control the evolution process:
  - Population size: how many genomes evolve simultaneously
  - Tournament size: how many compete in selection
  - Mutation/crossover rates: how often genetic operations occur
  - Elitism: how many best genomes are preserved each generation
  """
  fun population_size(): USize => 500        // Large population for diversity
  fun tournament_size(): USize => 5          // Larger tournaments for selection pressure
  fun worker_count(): USize => 8             // Parallel fitness evaluation
  fun mutation_rate(): F64 => 0.18           // Balanced mutation rate (not too destructive)
  fun crossover_rate(): F64 => 0.75          // Higher crossover to preserve building blocks
  fun elitism_count(): USize => 10           // Preserve more top genomes to prevent degeneration