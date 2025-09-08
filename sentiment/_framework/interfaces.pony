// Generic interfaces for the GA framework
// These define the contracts that specific implementations must fulfill

use "random"

// Interface for problem-specific implementations
trait ProblemDomain
  """
  Defines the problem domain for the GA to solve.
  Implementations specify genome size, evaluation, and fitness calculation.
  """
  fun genome_size(): USize
  fun random_genome(rng: Rand): Array[U8] val
  fun evaluate(genome: Array[U8] val): F64
  fun perfect_fitness(): F64
  fun display_result(genome: Array[U8] val): String

// Interface for genome operations
trait GenomeOperations
  """
  Defines genetic operations on genomes.
  Can be customized per problem domain.
  """
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val)

// Interface for progress reporting
interface tag ReportSink
  """
  Receives progress updates from the GA.
  """
  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val)
  be save_best(gen: USize, fitness: F64, genome: Array[U8] val)

// Interface for fitness evaluation callbacks
interface tag FitnessReceiver
  """
  Receives fitness results from parallel evaluators.
  """
  be got_fit(id: USize, fitness: F64)

// Configuration interface
trait GAConfiguration
  """
  Configuration parameters for the GA.
  """
  fun population_size(): USize
  fun tournament_size(): USize
  fun worker_count(): USize
  fun mutation_rate(): F64
  fun crossover_rate(): F64
  fun elitism_count(): USize