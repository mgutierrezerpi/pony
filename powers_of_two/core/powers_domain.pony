// Domain implementation for powers of 2 problem
// Evolves VM programs using nucleos (atomic operations) to compute 2^n

use "random"
use "collections"
use "../_framework"

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
          let minimal_credit = (1.0 - error_ratio.min(1.0)) * 0.001  // Tiny partial credit
          total_fitness_score = total_fitness_score + minimal_credit
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
          let minimal_credit = (1.0 - error_ratio.min(1.0)) * 0.001
          total_fitness_score = total_fitness_score + minimal_credit
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
  
  These operations are aware of the VM nucleo format:
  - Each nucleo is 3 bytes: [opcode, destination_register, source_register]
  - There are 12 different nucleo types and 4 registers
  - Mutations respect nucleo boundaries to maintain codon integrity
  """
  
  fun mutate(random_generator: Rand, parent_genome: Array[U8] val): Array[U8] val =>
    """
    Standard mutation: modifies 1-2 random nucleos in the genome.
    Respects nucleo boundaries and valid opcode/register ranges to preserve codon structure.
    """
    recover val
      // Create a copy of the parent genome
      let mutated_genome = Array[U8](parent_genome.size())
      for byte_value in parent_genome.values() do
        mutated_genome.push(byte_value)
      end
      
      // Decide how many nucleos to mutate (1 or 2)
      let num_mutations = 1 + (random_generator.next().usize() % 2)
      
      for mutation_count in Range[USize](0, num_mutations) do
        try
          // Pick a random nucleo to mutate (0-15)
          let nucleo_index = random_generator.next().usize() % 16
          let nucleo_start_byte = nucleo_index * 3
          
          // Decide what part of the nucleo to mutate (opcode or operands)
          let mutation_target = random_generator.next() % 3
          
          if mutation_target == 0 then
            // Mutate the nucleo opcode (first byte)
            mutated_genome(nucleo_start_byte)? = random_generator.next().u8() % 12  // 12 valid nucleos
          else
            // Mutate one of the operand registers
            let operand_byte_offset = mutation_target.usize()
            mutated_genome(nucleo_start_byte + operand_byte_offset)? = random_generator.next().u8() % 4  // 4 valid registers
          end
        end
      end
      mutated_genome
    end
  
  fun heavy_mutate(random_generator: Rand, parent_genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation: randomizes 5-8 complete nucleos for escaping local optima.
    Used when the population becomes too similar and needs diversity.
    May break existing codon structures but enables exploration of new solutions.
    """
    recover val
      let heavily_mutated_genome = Array[U8](parent_genome.size())
      for byte_value in parent_genome.values() do
        heavily_mutated_genome.push(byte_value)
      end
      
      // Mutate many nucleos (5-8)
      let num_heavy_mutations = 5 + (random_generator.next().usize() % 4)
      
      for mutation_count in Range[USize](0, num_heavy_mutations) do
        try
          let nucleo_to_randomize = random_generator.next().usize() % 16
          let nucleo_byte_start = nucleo_to_randomize * 3
          
          // Completely randomize all 3 bytes of the nucleo
          heavily_mutated_genome(nucleo_byte_start)? = random_generator.next().u8() % 12     // 12 nucleo types
          heavily_mutated_genome(nucleo_byte_start + 1)? = random_generator.next().u8() % 4  // destination register
          heavily_mutated_genome(nucleo_byte_start + 2)? = random_generator.next().u8() % 4  // source register
        end
      end
      heavily_mutated_genome
    end
  
  fun crossover(random_generator: Rand, parent_a: Array[U8] val, parent_b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Two-point crossover that respects nucleo boundaries.
    Swaps a contiguous block of nucleos between two parent genomes.
    This preserves codon structures within the swapped region.
    """
    // Choose two random nucleo positions for crossover points
    let crossover_point_1 = random_generator.next().usize() % 16
    let crossover_point_2 = random_generator.next().usize() % 16
    let crossover_start_nucleo = if crossover_point_1 < crossover_point_2 then crossover_point_1 else crossover_point_2 end
    let crossover_end_nucleo = if crossover_point_1 < crossover_point_2 then crossover_point_2 else crossover_point_1 end
    
    // Convert nucleo indices to byte positions
    let crossover_start_byte = crossover_start_nucleo * 3
    let crossover_end_byte = crossover_end_nucleo * 3
    
    // Create first offspring
    let offspring_1 = recover val
      let child_genome = Array[U8](48)
      var byte_index: USize = 0
      while byte_index < 48 do
        try
          if (byte_index >= crossover_start_byte) and (byte_index < crossover_end_byte) then
            // Take this section from parent B
            child_genome.push(parent_b(byte_index)?)
          else
            // Take this section from parent A
            child_genome.push(parent_a(byte_index)?)
          end
        end
        byte_index = byte_index + 1
      end
      child_genome
    end
    
    // Create second offspring (opposite crossover)
    let offspring_2 = recover val
      let child_genome = Array[U8](48)
      var byte_index: USize = 0
      while byte_index < 48 do
        try
          if (byte_index >= crossover_start_byte) and (byte_index < crossover_end_byte) then
            // Take this section from parent A
            child_genome.push(parent_a(byte_index)?)
          else
            // Take this section from parent B
            child_genome.push(parent_b(byte_index)?)
          end
        end
        byte_index = byte_index + 1
      end
      child_genome
    end
    
    (offspring_1, offspring_2)

primitive PowersEvolutionConfig is GAConfiguration
  """
  Genetic Algorithm configuration parameters for powers of 2 evolution.
  
  These parameters control the evolution process:
  - Population size: how many genomes evolve simultaneously
  - Tournament size: how many compete in selection
  - Mutation/crossover rates: how often genetic operations occur
  - Elitism: how many best genomes are preserved each generation
  """
  fun population_size(): USize => 200        // Large population for diversity
  fun tournament_size(): USize => 3          // Small tournaments for selection pressure
  fun worker_count(): USize => 8             // Parallel fitness evaluation
  fun mutation_rate(): F64 => 0.15           // Higher mutation rate for exploration
  fun crossover_rate(): F64 => 0.7           // Moderate crossover rate
  fun elitism_count(): USize => 3            // Preserve top 3 genomes each generation