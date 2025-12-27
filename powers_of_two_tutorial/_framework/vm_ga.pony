// VM-Aware Genetic Algorithm
// Simplified but respects nucleo/codon structure

use "random"
use "collections"

trait VMProblem
  """
  VM-specific problem - knows about nucleos and codons
  """
  fun nucleos_per_genome(): USize
    """How many nucleos (instructions) in a genome?"""
  
  fun bytes_per_nucleo(): USize =>
    """Default: 3 bytes per nucleo [opcode, dest, src]"""
    3
  
  fun fitness(genome: Array[U8] val): F64
    """Rate this VM program from 0.0 to 1.0"""
  
  fun display(genome: Array[U8] val): String
    """Show what this VM program does"""
  
  fun max_opcode(): U8 =>
    """Largest valid opcode (default for 12 opcodes: 0-11)"""
    11
  
  fun max_register(): U8 =>
    """Largest valid register (default for 4 registers: 0-3)"""
    3

primitive VMGA
  """
  VM-aware evolution that respects nucleo boundaries
  """
  
  fun evolve[P: VMProblem val](
    env: Env,
    problem: P,
    population: USize = 200,
    generations: USize = 2000,
    output_dir: String = "bin/"): Bool =>
    """
    Evolve VM programs with nucleo-aware mutations.
    
    Example:
      VMGA.evolve[MyVMProblem](env, MyVMProblem, 150, 1000)
    """
    
    env.out.print("Starting VM evolution...")
    env.out.print("Nucleos per genome: " + problem.nucleos_per_genome().string())
    env.out.print("Total genome size: " + (problem.nucleos_per_genome() * problem.bytes_per_nucleo()).string() + " bytes")
    
    let domain = _VMDomainAdapter[P](problem)
    let ops = _VMGenomeOps[P](problem)
    let config = _VMGAConfig(population, generations)
    let reporter = GenericReporter(env, output_dir)
    
    GenericGAController[_VMDomainAdapter[P] val, _VMGenomeOps[P] val, _VMGAConfig val]
      .with_limit(env, domain, ops, config, reporter, generations)
    
    true

// Internal adapters for VM-aware evolution
class val _VMDomainAdapter[P: VMProblem val] is ProblemDomain
  let _problem: P
  new val create(problem: P) => _problem = problem
  
  fun genome_size(): USize => 
    _problem.nucleos_per_genome() * _problem.bytes_per_nucleo()
  
  fun evaluate(genome: Array[U8] val): F64 => _problem.fitness(genome)
  fun perfect_fitness(): F64 => 0.99
  fun display_result(genome: Array[U8] val): String => _problem.display(genome)
  
  fun random_genome(rng: Rand): Array[U8] val =>
    recover val
      let genome = Array[U8](genome_size())
      
      // Generate nucleos (not just random bytes!)
      for _ in Range[USize](0, _problem.nucleos_per_genome()) do
        genome.push(rng.next().u8() % (_problem.max_opcode() + 1))  // Valid opcode
        genome.push(rng.next().u8() % (_problem.max_register() + 1)) // Valid dest register
        genome.push(rng.next().u8() % (_problem.max_register() + 1)) // Valid src register
      end
      genome
    end

class val _VMGenomeOps[P: VMProblem val] is GenomeOperations
  let _problem: P
  new val create(problem: P) => _problem = problem
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """Nucleo-aware mutation - respects instruction boundaries"""
    recover val
      let mutated = Array[U8](genome.size())
      for b in genome.values() do mutated.push(b) end
      
      // Mutate 1-2 complete nucleos
      let num_mutations = 1 + (rng.next().usize() % 2)
      
      for _ in Range[USize](0, num_mutations) do
        try
          // Pick a random nucleo to mutate
          let nucleo_idx = rng.next().usize() % _problem.nucleos_per_genome()
          let byte_offset = nucleo_idx * _problem.bytes_per_nucleo()
          
          // Decide what part of the nucleo to mutate
          match rng.next() % 3
          | 0 => // Mutate opcode
            mutated(byte_offset)? = rng.next().u8() % (_problem.max_opcode() + 1)
          | 1 => // Mutate destination register
            mutated(byte_offset + 1)? = rng.next().u8() % (_problem.max_register() + 1)
          | 2 => // Mutate source register
            mutated(byte_offset + 2)? = rng.next().u8() % (_problem.max_register() + 1)
          end
        end
      end
      mutated
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """Heavy nucleo-aware mutation - may break codons"""
    recover val
      let mutated = Array[U8](genome.size())
      for b in genome.values() do mutated.push(b) end
      
      // Mutate 25-50% of nucleos
      let mutation_count = (_problem.nucleos_per_genome() / 4) + 
                          (rng.next().usize() % (_problem.nucleos_per_genome() / 4))
      
      for _ in Range[USize](0, mutation_count) do
        try
          let nucleo_idx = rng.next().usize() % _problem.nucleos_per_genome()
          let byte_offset = nucleo_idx * _problem.bytes_per_nucleo()
          
          // Completely randomize this nucleo
          mutated(byte_offset)? = rng.next().u8() % (_problem.max_opcode() + 1)
          mutated(byte_offset + 1)? = rng.next().u8() % (_problem.max_register() + 1)
          mutated(byte_offset + 2)? = rng.next().u8() % (_problem.max_register() + 1)
        end
      end
      mutated
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """Nucleo-aware crossover - preserves codon boundaries"""
    let num_nucleos = _problem.nucleos_per_genome()
    let bytes_per = _problem.bytes_per_nucleo()
    
    // Pick crossover points at nucleo boundaries
    let split1 = rng.next().usize() % num_nucleos
    let split2 = rng.next().usize() % num_nucleos
    let start_nucleo = if split1 < split2 then split1 else split2 end
    let end_nucleo = if split1 < split2 then split2 else split1 end
    
    // Convert to byte positions
    let start_byte = start_nucleo * bytes_per
    let end_byte = end_nucleo * bytes_per
    
    (recover val
      let child1 = Array[U8](a.size())
      var i: USize = 0
      while i < a.size() do
        try
          if (i >= start_byte) and (i < end_byte) then
            child1.push(b(i)?)  // Take middle section from parent B
          else
            child1.push(a(i)?)  // Take ends from parent A
          end
        end
        i = i + 1
      end
      child1
    end,
    recover val
      let child2 = Array[U8](b.size())
      var i: USize = 0
      while i < b.size() do
        try
          if (i >= start_byte) and (i < end_byte) then
            child2.push(a(i)?)  // Take middle section from parent A
          else
            child2.push(b(i)?)  // Take ends from parent B
          end
        end
        i = i + 1
      end
      child2
    end)

class val _VMGAConfig is GAConfiguration
  let _pop: USize
  let _gens: USize
  
  new val create(population: USize, generations: USize) =>
    _pop = population
    _gens = generations
  
  fun population_size(): USize => _pop
  fun tournament_size(): USize => 3
  fun worker_count(): USize => 8
  fun mutation_rate(): F64 => 0.15
  fun crossover_rate(): F64 => 0.7
  fun elitism_count(): USize => 3