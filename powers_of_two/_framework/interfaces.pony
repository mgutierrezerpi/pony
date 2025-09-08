// Core interfaces for the Genetic Algorithm framework
// These contracts define how different components interact in the GA system

use "random"

trait ProblemDomainDefinition
  """
  Interface that defines a specific optimization problem for genetic evolution.
  
  Each problem domain (like powers of 2, Fibonacci, sentiment analysis) must implement
  this interface to specify:
  - How genomes are structured and sized
  - How fitness is calculated
  - How results are displayed
  
  This abstraction allows the same GA framework to solve different types of problems.
  """
  
  fun genome_byte_count(): USize
    """Returns the size in bytes of each genome (individual solution)."""
  
  fun create_random_genome(random_number_generator: Rand): Array[U8] val
    """Generates a completely random genome as a starting point for evolution."""
  
  fun calculate_fitness(candidate_solution: Array[U8] val): F64
    """
    Evaluates how good a solution is, returning a fitness score from 0.0 to 1.0.
    Higher scores indicate better solutions.
    """
  
  fun maximum_achievable_fitness(): F64
    """
    Returns the theoretical maximum fitness score.
    Used to determine when evolution can stop (perfect solution found).
    """
  
  fun format_solution_output(solution_genome: Array[U8] val): String
    """Formats a genome's performance for human-readable display."""

trait GeneticOperationProvider
  """
  Interface for genetic operators that modify genomes during evolution.
  
  These operations simulate biological processes:
  - Mutation: Random changes to introduce variety
  - Crossover: Combining traits from two parents
  - Heavy mutation: Large changes to escape local optima
  
  Different problems may need specialized genetic operations.
  """
  
  fun apply_mutation(random_generator: Rand, parent_genome: Array[U8] val): Array[U8] val
    """
    Creates a slightly modified copy of a genome.
    Introduces small random changes to maintain population diversity.
    """
  
  fun apply_heavy_mutation(random_generator: Rand, parent_genome: Array[U8] val): Array[U8] val
    """
    Creates a heavily modified copy of a genome.
    Used when population becomes too similar (stagnation).
    """
  
  fun perform_crossover(random_generator: Rand, parent_a: Array[U8] val, parent_b: Array[U8] val): (Array[U8] val, Array[U8] val)
    """
    Combines two parent genomes to create two offspring.
    Simulates sexual reproduction by mixing genetic material.
    Returns a tuple of (offspring_1, offspring_2).
    """

interface tag EvolutionProgressReporter
  """
  Actor interface for receiving and handling evolution progress updates.
  
  The GA controller sends updates to reporters which can:
  - Display progress to users
  - Save genomes and metrics to files  
  - Log evolution statistics
  - Trigger early stopping conditions
  """
  
  be report_generation_progress(generation_number: USize, best_fitness: F64, average_fitness: F64, best_genome: Array[U8] val)
    """
    Called every generation to report evolution progress.
    Used for real-time monitoring and logging.
    """
  
  be save_elite_genome(generation_number: USize, fitness_score: F64, elite_genome: Array[U8] val)
    """
    Called to save particularly good genomes for later use.
    Typically called for the best genome of each generation.
    """

interface tag ParallelFitnessCollector
  """
  Actor interface for collecting fitness evaluation results from parallel workers.
  
  When using multiple worker actors to evaluate fitness in parallel,
  this interface handles receiving the results and coordinating the GA.
  """
  
  be receive_fitness_result(genome_identifier: USize, calculated_fitness: F64)
    """
    Receives a fitness score from a parallel evaluation worker.
    The genome_identifier matches the genome to its fitness score.
    """

trait EvolutionParameterConfiguration
  """
  Interface defining all configurable parameters for genetic algorithm evolution.
  
  These parameters control the evolution process:
  - Population dynamics (size, selection pressure)
  - Genetic operation rates (mutation, crossover frequency)
  - Parallel processing (worker count)
  - Elite preservation (how many best solutions to keep)
  """
  
  fun total_population_size(): USize
    """Number of genomes that evolve simultaneously each generation."""
  
  fun tournament_selection_size(): USize
    """Number of genomes competing in each selection tournament."""
  
  fun parallel_worker_count(): USize
    """Number of actor workers for parallel fitness evaluation."""
  
  fun genome_mutation_probability(): F64
    """Probability (0.0 to 1.0) that a genome will be mutated."""
  
  fun parent_crossover_probability(): F64
    """Probability (0.0 to 1.0) that two parents will produce offspring via crossover."""
  
  fun elite_preservation_count(): USize
    """Number of best genomes automatically preserved each generation (elitism)."""

// Legacy aliases for backward compatibility with existing code
trait ProblemDomain
  """Legacy alias maintaining the original interface that implementations expect."""
  fun genome_size(): USize
  fun random_genome(rng: Rand): Array[U8] val
  fun evaluate(genome: Array[U8] val): F64
  fun perfect_fitness(): F64
  fun display_result(genome: Array[U8] val): String

trait GenomeOperations
  """Legacy alias maintaining the original interface that implementations expect."""
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val)

interface tag ReportSink
  """Legacy alias maintaining the original interface that implementations expect."""
  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val)
  be save_best(gen: USize, fitness: F64, genome: Array[U8] val)

interface tag FitnessReceiver
  """Legacy alias maintaining the original interface that implementations expect."""
  be got_fit(id: USize, fitness: F64)

trait GAConfiguration
  """Legacy alias maintaining the original interface that implementations expect."""
  fun population_size(): USize
  fun tournament_size(): USize
  fun worker_count(): USize
  fun mutation_rate(): F64
  fun crossover_rate(): F64
  fun elitism_count(): USize