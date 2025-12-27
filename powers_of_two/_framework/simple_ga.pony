// Simplified Genetic Algorithm Interface
// Reduces boilerplate while maintaining power and flexibility

use "random"
use "collections"

trait SimpleProblem
  """
  Simplified problem definition - just define these 3 methods and you're done!
  """
  fun genome_size(): USize
    """How many bytes in a genome?"""
  
  fun fitness(genome: Array[U8] val): F64
    """Rate this genome from 0.0 (terrible) to 1.0 (perfect)"""
  
  fun display(genome: Array[U8] val): String
    """Show results for this genome (for debugging/display)"""

trait SimpleConfig
  """
  Optional configuration - has sensible defaults but can be overridden
  """
  fun population(): USize => 100
  fun generations(): USize => 1000
  fun mutation_rate(): F64 => 0.1
  fun crossover_rate(): F64 => 0.7
  fun elitism(): USize => 2
  fun perfect_score(): F64 => 0.99

primitive SimpleGA
  """
  One-line GA runner - handles all the complexity internally
  """
  
  fun evolve[P: SimpleProblem val, C: SimpleConfig val](
    env: Env,
    problem: P,
    config: C,
    output_dir: String = "bin/"): Bool =>
    """
    Run evolution and return true if perfect solution found.
    
    Example usage:
      SimpleGA.evolve[MyProblem, DefaultConfig](env, MyProblem)
    """
    
    env.out.print("Starting evolution...")
    env.out.print("Population: " + config.population().string())
    env.out.print("Target fitness: " + (config.perfect_score() * 100).string() + "%")
    
    // Create traditional components internally
    let domain = _SimpleDomainAdapter[P](problem)
    let ops = _SimpleGenomeOps[P](problem)
    let ga_config = _SimpleGAConfig[C](config)
    let reporter = GenericReporter(env, output_dir)
    
    // Run the full GA
    GenericGAController[_SimpleDomainAdapter[P] val, _SimpleGenomeOps[P] val, _SimpleGAConfig[C] val]
      .with_limit(env, domain, ops, ga_config, reporter, config.generations())
    
    true // TODO: Return actual success status

// Default configuration that works well for most problems
primitive DefaultConfig is SimpleConfig

// Internal adapters that bridge simple interface to full framework
class val _SimpleDomainAdapter[P: SimpleProblem val] is ProblemDomain
  let _problem: P

  new val create(problem: P) => _problem = problem
  
  fun genome_size(): USize => _problem.genome_size()
  fun evaluate(genome: Array[U8] val): F64 => _problem.fitness(genome)
  fun perfect_fitness(): F64 => 0.99 // DefaultConfig.perfect_score()
  fun display_result(genome: Array[U8] val): String => _problem.display(genome)
  
  fun random_genome(rng: Rand): Array[U8] val =>
    recover val
      let genome = Array[U8](_problem.genome_size())
      for _ in Range[USize](0, _problem.genome_size()) do
        genome.push(rng.next().u8())
      end
      genome
    end

class val _SimpleGenomeOps[P: SimpleProblem val] is GenomeOperations
  let _problem: P

  new val create(problem: P) => _problem = problem
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Simple random mutation
    recover val
      let mutated = Array[U8](genome.size())
      for b in genome.values() do mutated.push(b) end
      
      // Mutate 1-3 random bytes
      let mutations = 1 + (rng.next().usize() % 3)
      for _ in Range[USize](0, mutations) do
        try
          let pos = rng.next().usize() % mutated.size()
          mutated(pos)? = rng.next().u8()
        end
      end
      mutated
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Mutate 20-50% of bytes
    recover val
      let mutated = Array[U8](genome.size())
      for b in genome.values() do mutated.push(b) end
      
      let mutation_count = (genome.size() / 5) + (rng.next().usize() % (genome.size() / 3))
      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % mutated.size()
          mutated(pos)? = rng.next().u8()
        end
      end
      mutated
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    // Simple single-point crossover
    let size = a.size().min(b.size())
    let split = rng.next().usize() % size
    
    (recover val
      let child1 = Array[U8](size)
      var i: USize = 0
      while i < size do
        try
          if i < split then child1.push(a(i)?) else child1.push(b(i)?) end
        end
        i = i + 1
      end
      child1
    end,
    recover val
      let child2 = Array[U8](size)
      var i: USize = 0
      while i < size do
        try
          if i < split then child2.push(b(i)?) else child2.push(a(i)?) end
        end
        i = i + 1
      end
      child2
    end)

class val _SimpleGAConfig[C: SimpleConfig val] is GAConfiguration
  let _config: C

  new val create(config: C) => _config = config
  
  fun population_size(): USize => _config.population()
  fun tournament_size(): USize => 3
  fun worker_count(): USize => 8
  fun mutation_rate(): F64 => _config.mutation_rate()
  fun crossover_rate(): F64 => _config.crossover_rate()
  fun elitism_count(): USize => _config.elitism()