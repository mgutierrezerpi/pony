// Evolution Progress Reporter for Genetic Algorithm Framework
// Handles real-time logging and persistent storage of evolution metrics

use "files"

actor EvolutionProgressTracker is ReportSink
  """
  Actor responsible for tracking and reporting genetic algorithm evolution progress.
  
  Responsibilities:
  - Display real-time progress to the console
  - Save comprehensive metrics to YAML files  
  - Save elite genomes as binary files
  - Implement intelligent logging (avoid spam while capturing important events)
  
  This actor receives updates from the GA controller and decides when/how to
  log progress and save data.
  """
  
  let _console_environment: Env
  let _file_save_directory: String
  var _previous_best_fitness: F64 = -1.0
  var _last_generation_logged: USize = 0
  
  new create(console_env: Env, save_directory: String = "bin/") =>
    """
    Initialize the progress tracker.
    
    Parameters:
    - console_env: Environment for console output
    - save_directory: Directory path where files should be saved
    """
    _console_environment = console_env
    _file_save_directory = save_directory
  
  be tick(current_generation: USize, best_fitness_score: F64, average_population_fitness: F64, elite_genome: Array[U8] val) =>
    """
    Called every generation to report evolution progress.
    
    Implements intelligent logging strategy:
    - Always log generation 1
    - Log every 10th generation
    - Log when fitness improves significantly (>1% improvement)
    - Log when near-perfect fitness is achieved
    """
    let fitness_improved_significantly = best_fitness_score > (_previous_best_fitness + 0.01)
    let near_perfect_fitness = best_fitness_score >= 0.99999
    let milestone_generation = (current_generation % 10) == 0
    let first_generation = current_generation == 1
    
    let should_display_progress = first_generation or milestone_generation or fitness_improved_significantly or near_perfect_fitness
    
    if should_display_progress then
      _display_generation_progress(current_generation, best_fitness_score, average_population_fitness)
      _last_generation_logged = current_generation
    end
    
    // Always save comprehensive metrics (YAML files) for analysis
    EvolutionMetricsStorage.save_generation_data(_console_environment, _file_save_directory, 
                                                 current_generation, elite_genome, 
                                                 best_fitness_score, average_population_fitness)
    
    _previous_best_fitness = best_fitness_score
  
  be save_best(generation_number: USize, fitness_score: F64, champion_genome: Array[U8] val) =>
    """
    Saves an elite genome with both comprehensive metrics and raw binary data.
    
    Called for particularly noteworthy genomes (usually the best of each generation).
    Creates two files:
    - YAML file with detailed metrics and metadata
    - Binary file with raw genome bytes for quick loading
    """
    // Save comprehensive metrics in YAML format
    EvolutionMetricsStorage.save_generation_data(_console_environment, _file_save_directory,
                                                 generation_number, champion_genome,
                                                 fitness_score, fitness_score)
    
    // Save raw genome bytes for backwards compatibility and quick loading
    _save_raw_genome_bytes(generation_number, champion_genome)
  
  fun _display_generation_progress(generation: USize, best_fitness: F64, average_fitness: F64) =>
    """
    Displays formatted progress information to the console.
    Format: gen=123 best=0.85432 avg=0.67890
    """
    let progress_message = recover val
      "gen=" + generation.string() + 
      " best=" + best_fitness.string() + 
      " avg=" + average_fitness.string()
    end
    _console_environment.out.print(consume progress_message)
  
  fun _save_raw_genome_bytes(generation: USize, genome_data: Array[U8] val) =>
    """
    Saves genome as raw binary file for quick loading and backwards compatibility.
    Filename format: best_genome_gen_001.bytes
    """
    let formatted_generation_number = _format_generation_number(generation)
    let file_authenticator = FileAuth(_console_environment.root)
    let binary_file_path = FilePath(file_authenticator, _file_save_directory + "best_genome_gen_" + formatted_generation_number + ".bytes")
    
    let binary_file = File(binary_file_path)
    binary_file.write(genome_data)
    binary_file.sync()
    binary_file.dispose()
  
  fun _format_generation_number(generation: USize): String =>
    """
    Formats generation number with leading zeros for consistent file sorting.
    Examples: 1 -> "001", 25 -> "025", 150 -> "150"
    """
    if generation < 10 then
      "00" + generation.string()
    elseif generation < 100 then
      "0" + generation.string()
    else
      generation.string()
    end

// Legacy alias for backward compatibility
actor GenericReporter is ReportSink
  """
  Legacy alias for EvolutionProgressTracker to maintain backward compatibility.
  All new code should use EvolutionProgressTracker directly.
  """
  
  let _tracker: EvolutionProgressTracker
  
  new create(env: Env, save_path: String = "bin/") =>
    _tracker = EvolutionProgressTracker(env, save_path)
  
  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val) =>
    _tracker.tick(gen, best, avg, genome)
  
  be save_best(gen: USize, fitness: F64, genome: Array[U8] val) =>
    _tracker.save_best(gen, fitness, genome)

// Alias for metrics storage to improve readability
primitive EvolutionMetricsStorage
  """Readable alias for MetricsPersistence to clarify its purpose."""
  fun save_generation_data(env: Env, base_path: String, generation: USize, 
                          genome: Array[U8] val, fitness: F64, avg_fitness: F64): Bool =>
    MetricsPersistence.save_generation(env, base_path, generation, genome, fitness, avg_fitness)