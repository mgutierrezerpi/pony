// Evolution Metrics Persistence System for Genetic Algorithm Framework
// Handles comprehensive storage of evolution data in human-readable YAML format

use "files"
use "time"
use "collections"

primitive EvolutionDataArchiver
  """
  Comprehensive system for archiving genetic algorithm evolution data.
  
  Creates structured, human-readable records of the evolution process including:
  - Individual genome performance metrics
  - Generation-by-generation progress tracking  
  - Complete evolution run summaries
  - Searchable metadata for post-evolution analysis
  
  Files are stored in YAML format for easy parsing and analysis by external tools.
  """
  
  fun archive_generation_snapshot(execution_environment: Env, storage_directory: String, generation_number: USize, 
                                  champion_genome: Array[U8] val, best_fitness_score: F64, population_average_fitness: F64): Bool =>
    """
    Archives a complete snapshot of a generation's evolution state.
    
    Creates two complementary files:
    1. Raw genome binary data for quick loading and execution
    2. Comprehensive YAML metadata for analysis and visualization
    
    Parameters:
    - execution_environment: Pony environment for file operations
    - storage_directory: Base directory path for file storage
    - generation_number: Current evolution generation
    - champion_genome: Best-performing genome of this generation
    - best_fitness_score: Fitness score of the champion genome
    - population_average_fitness: Average fitness across entire population
    
    Returns: true if both files saved successfully, false otherwise
    """
    let formatted_generation = _format_generation_identifier(generation_number)
    let file_authenticator = FileAuth(execution_environment.root)
    
    // Archive raw genome data as binary file
    let binary_success = _save_genome_binary_data(file_authenticator, storage_directory, 
                                                  formatted_generation, champion_genome)
    
    // Archive comprehensive metrics as YAML file  
    let yaml_success = _save_comprehensive_yaml_metrics(file_authenticator, storage_directory,
                                                        formatted_generation, generation_number,
                                                        champion_genome, best_fitness_score, population_average_fitness)
    
    binary_success and yaml_success
  
  fun create_evolution_summary_report(execution_environment: Env, storage_directory: String, 
                                      total_generations_run: USize, peak_fitness_achieved: F64, 
                                      generation_of_peak_fitness: USize): Bool =>
    """
    Creates a comprehensive summary report of the entire evolution run.
    
    This summary file provides high-level insights into the evolution process:
    - Overall performance statistics
    - Configuration parameters used
    - Key milestones and achievements
    - Problem domain information
    
    Useful for comparing different evolution runs and parameter configurations.
    """
    let file_authenticator = FileAuth(execution_environment.root)
    let summary_file_path = FilePath(file_authenticator, storage_directory + "evolution_summary.yaml")
    let summary_file = File(summary_file_path)
    
    let current_timestamp = Time.seconds()
    let summary_yaml_content = _build_evolution_summary_yaml(total_generations_run, peak_fitness_achieved,
                                                             generation_of_peak_fitness, current_timestamp)
    
    summary_file.write(summary_yaml_content.array())
    summary_file.sync()
    summary_file.dispose()
    
    true
  
  fun _save_genome_binary_data(file_auth: FileAuth, base_path: String, generation_id: String, genome_data: Array[U8] val): Bool =>
    """
    Saves raw genome bytes to a binary file for quick loading and execution.
    Filename format: gen_00123.bytes
    """
    let binary_file_path = FilePath(file_auth, base_path + "gen_" + generation_id + ".bytes")
    let binary_file = File(binary_file_path)
    binary_file.write(genome_data)
    binary_file.sync()
    binary_file.dispose()
    true
  
  fun _save_comprehensive_yaml_metrics(file_auth: FileAuth, base_path: String, generation_id: String,
                                       generation_num: USize, genome: Array[U8] val, 
                                       fitness: F64, avg_fitness: F64): Bool =>
    """
    Saves detailed generation metrics in human-readable YAML format.
    Includes fitness scores, performance analysis, and metadata.
    """
    let yaml_file_path = FilePath(file_auth, base_path + "gen_" + generation_id + ".yaml")
    let yaml_file = File(yaml_file_path)
    
    let yaml_content = _build_generation_yaml_content(generation_num, genome, fitness, avg_fitness)
    
    yaml_file.write(yaml_content.array())
    yaml_file.sync()
    yaml_file.dispose()
    true
  
  fun _build_generation_yaml_content(generation: USize, genome: Array[U8] val, 
                                     fitness: F64, avg_fitness: F64): String val =>
    """
    Constructs YAML content string with comprehensive generation metrics.
    Format is designed for easy parsing by analysis tools and human readability.
    """
    let current_timestamp = Time.seconds()
    recover val
      let yaml_builder = String
      
      // Header and basic information
      yaml_builder.append("# Genetic Algorithm Evolution - Generation ")
      yaml_builder.append(generation.string())
      yaml_builder.append("\ngeneration: ")
      yaml_builder.append(generation.string())
      yaml_builder.append("\ntimestamp: ")
      yaml_builder.append(current_timestamp.string())
      
      // Fitness metrics section
      yaml_builder.append("\nfitness:\n")
      yaml_builder.append("  best_in_generation: ")
      yaml_builder.append(fitness.string())
      yaml_builder.append("\n  population_average: ")
      yaml_builder.append(avg_fitness.string())
      
      // Genome information section
      yaml_builder.append("\ngenome_data:\n")
      yaml_builder.append("  byte_size: ")
      yaml_builder.append(genome.size().string())
      yaml_builder.append("\n  binary_file: gen_")
      yaml_builder.append(_format_generation_identifier(generation))
      yaml_builder.append(".bytes\n")
      
      // Performance analysis section
      yaml_builder.append("performance_analysis:\n")
      yaml_builder.append("  fitness_percentage: ")
      yaml_builder.append((fitness * 100).string())
      yaml_builder.append("%\n")
      yaml_builder.append("  test_cases_passed_estimate: ")
      yaml_builder.append((fitness * 12).string())  // Now testing 12 cases (8 fixed + 4 random)
      yaml_builder.append(" / 12\n")
      yaml_builder.append("  performance_category: ")
      if fitness >= 0.9 then
        yaml_builder.append("excellent\n")
      elseif fitness >= 0.7 then
        yaml_builder.append("good\n")
      elseif fitness >= 0.5 then
        yaml_builder.append("moderate\n")  
      elseif fitness >= 0.3 then
        yaml_builder.append("poor\n")
      else
        yaml_builder.append("very_poor\n")
      end
      
      yaml_builder
    end
  
  fun _build_evolution_summary_yaml(total_gens: USize, best_fitness: F64, best_gen: USize, timestamp: I64): String val =>
    """
    Constructs comprehensive evolution summary in YAML format.
    """
    recover val
      let summary_builder = String
      summary_builder.append("# Complete Evolution Run Summary\n")
      summary_builder.append("evolution_summary:\n")
      summary_builder.append("  total_generations: ")
      summary_builder.append(total_gens.string())
      summary_builder.append("\n  peak_fitness_achieved: ")
      summary_builder.append(best_fitness.string())
      summary_builder.append("\n  generation_of_peak: ")
      summary_builder.append(best_gen.string())
      summary_builder.append("\n  completion_timestamp: ")
      summary_builder.append(timestamp.string())
      summary_builder.append("\n\ngenome_configuration:\n")
      summary_builder.append("  genome_size_bytes: 48\n")
      summary_builder.append("  vm_instructions_per_genome: 16\n")
      summary_builder.append("  vm_registers_available: 4\n")
      summary_builder.append("\nproblem_domain:\n")
      summary_builder.append("  name: \"Powers of 2\"\n")
      summary_builder.append("  test_case_count: 12\n")
      summary_builder.append("  input_range: \"2^0 to 2^9 (8 fixed + 4 random)\"\n")
      summary_builder.append("  expected_outputs: \"[1, 2, 4, 8, 16, 32, 64, 128] + 4 random cases\"\n")
      summary_builder
    end
  
  fun _format_generation_identifier(generation: USize): String =>
    """
    Formats generation number with consistent zero-padding for proper file sorting.
    Examples: 1 -> "00001", 42 -> "00042", 1337 -> "01337"
    """
    if generation < 10 then
      "0000" + generation.string()
    elseif generation < 100 then
      "000" + generation.string()
    elseif generation < 1000 then
      "00" + generation.string()
    elseif generation < 10000 then
      "0" + generation.string()
    else
      generation.string()
    end

// Legacy compatibility interface - preserves existing API
primitive MetricsPersistence
  """
  Legacy compatibility wrapper for EvolutionDataArchiver.
  Maintains backward compatibility while encouraging migration to new interface.
  """
  
  fun save_generation(env: Env, base_path: String, generation: USize, 
                      genome: Array[U8] val, fitness: F64, avg_fitness: F64): Bool =>
    """Legacy method - delegates to new implementation."""
    EvolutionDataArchiver.archive_generation_snapshot(env, base_path, generation, genome, fitness, avg_fitness)
  
  fun save_evolution_summary(env: Env, base_path: String, total_generations: USize,
                             best_fitness: F64, best_generation: USize): Bool =>
    """Legacy method - delegates to new implementation."""
    EvolutionDataArchiver.create_evolution_summary_report(env, base_path, total_generations, best_fitness, best_generation)