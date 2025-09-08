# Nucleo/Codon Genetic Algorithm Framework

A sophisticated, reusable genetic algorithm framework implementing the nucleo/codon genetic concepts defined in CLAUDE.md. This framework can be adapted to solve various optimization problems while respecting biological-inspired genetic structures.

## Architecture

The framework is built around several key abstractions:

### 1. ProblemDomain Trait
Defines the problem-specific aspects:
- `genome_size()`: Size of the genome representation
- `random_genome(rng)`: Generate a random genome
- `evaluate(genome)`: Calculate fitness score (0.0 to 1.0)
- `perfect_fitness()`: Target fitness value
- `display_result(genome)`: Human-readable result display

### 2. GenomeOperations Trait
Defines genetic operators:
- `mutate(rng, genome)`: Standard mutation
- `heavy_mutate(rng, genome)`: Aggressive mutation for escaping local optima
- `crossover(rng, a, b)`: Combine two parent genomes

### 3. GAConfiguration Trait
Defines algorithm parameters:
- `population_size()`: Number of individuals
- `tournament_size()`: Tournament selection size
- `worker_count()`: Parallel evaluation workers
- `mutation_rate()`: Mutation probability
- `crossover_rate()`: Crossover probability
- `elitism_count()`: Number of elite individuals to preserve

### 4. GenericGAController Actor
The main GA engine that:
- Manages population evolution
- Handles selection, crossover, and mutation
- Implements adaptive diversity mechanisms
- Detects and responds to stagnation
- Reports progress via ReportSink

## Genetic Framework Concepts

This framework implements the genetic approach defined in CLAUDE.md:

- **Nucleos**: Atomic operations that serve as the basic building blocks (e.g., VM instructions like ADD, MOV, LOADN)
- **Codons**: Functional sequences formed by combining nucleos to achieve specific behaviors
- **Genomes**: Complete sequences of nucleos that combine into codons to solve problems
- **Evolution**: The process of evolving nucleos and their combinations into effective codons

## Features

- **Adaptive Diversity**: Automatically adjusts mutation rates and introduces random individuals when evolution stagnates
- **Elitism**: Preserves best individuals across generations
- **Tournament Selection**: Efficient selection mechanism
- **Parallel Evaluation**: Supports concurrent fitness evaluation
- **Persistence**: Save and load genomes to/from disk
- **Progress Reporting**: Real-time monitoring of evolution progress
- **Nucleo-Aware Operations**: Genetic operators respect nucleo boundaries to maintain codon integrity

## Usage Example

## Quick Start Example

```pony
// Minimal working example
use "random"

primitive SimpleProblem is ProblemDomain
  fun genome_size(): USize => 10
  fun random_genome(rng: Rand): Array[U8] val =>
    recover val
      let g = Array[U8](10)
      for _ in Range[USize](0, 10) do g.push(rng.next().u8()) end
      g
    end
  fun evaluate(genome: Array[U8] val): F64 =>
    // Example: fitness = percentage of bytes > 128
    var count: F64 = 0
    for b in genome.values() do
      if b > 128 then count = count + 1 end
    end
    count / genome.size().f64()
  fun perfect_fitness(): F64 => 0.99
  fun display_result(g: Array[U8] val): String => "Genome result"

// Use framework's generic operations
let ops = ByteGenomeOps
let config = DefaultGAConfig  // You'll need to define this

actor Main
  new create(env: Env) =>
    let reporter = GenericReporter(env, "output/")
    GenericGAController[SimpleProblem val, ByteGenomeOps val, DefaultGAConfig val]
      .create(env, SimpleProblem, ops, config, reporter)
```

## Framework Components

### Core Files

- **`interfaces.pony`**: Core traits defining the framework contracts
- **`ga_controller.pony`**: Main evolution engine with adaptive diversity
- **`genome_ops.pony`**: Generic genetic operations for byte-array genomes
- **`persistence.pony`**: Genome storage and loading system
- **`metrics_persistence.pony`**: YAML-based evolution metrics tracking
- **`reporter.pony`**: Progress reporting and logging infrastructure

### Key Features by File

| File | Primary Features |
|------|------------------|
| `ga_controller.pony` | Adaptive diversity, elitism, tournament selection, stagnation detection |
| `genome_ops.pony` | Generic mutations and crossover (can be overridden for nucleo-aware ops) |
| `persistence.pony` | Binary genome storage with generation tracking |
| `metrics_persistence.pony` | Human-readable YAML metrics for analysis |
| `interfaces.pony` | Type-safe contracts with nucleo/codon documentation |
| `reporter.pony` | Real-time progress updates and logging |

## Implementation Examples

The framework is used in several working projects:

- **Powers of Two** (`../core/`): Evolves VM programs to compute 2^n
- **Fibonacci** (`../../fibonacci/`): Evolves VM programs for Fibonacci sequences
- **Sentiment Analysis** (`../../sentiment/`): Evolves neural networks for text classification

## Creating a New Problem Domain

### Step 1: Define Your Problem Domain
```pony
primitive MyProblem is ProblemDomain
  fun genome_size(): USize => 64  // Size in bytes
  
  fun random_genome(rng: Rand): Array[U8] val =>
    // Generate random nucleo sequence
    recover val
      let genome = Array[U8](genome_size())
      for i in Range[USize](0, genome_size()) do
        genome.push(rng.next().u8())
      end
      genome
    end
  
  fun evaluate(genome: Array[U8] val): F64 =>
    // Your fitness evaluation logic here
    // Return 0.0 to 1.0 (higher = better)
    0.5
  
  fun perfect_fitness(): F64 => 0.99
  fun display_result(genome: Array[U8] val): String => "Result here"
```

### Step 2: Implement Nucleo-Aware Genetic Operations
```pony
primitive MyGenomeOps is GenomeOperations
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Light mutation preserving codon structure
    // Your nucleo-aware mutation logic
    genome
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Heavy mutation for exploration (may break codons)
    // Your aggressive mutation logic
    genome
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    // Crossover respecting nucleo boundaries
    // Your crossover logic here
    (a, b)
```

### Step 3: Configure Evolution Parameters
```pony
primitive MyConfig is GAConfiguration
  fun population_size(): USize => 100
  fun tournament_size(): USize => 3
  fun worker_count(): USize => 8
  fun mutation_rate(): F64 => 0.1
  fun crossover_rate(): F64 => 0.8
  fun elitism_count(): USize => 2
```

### Step 4: Run the Evolution
```pony
actor Main
  new create(env: Env) =>
    let reporter = GenericReporter(env, "output/")
    GenericGAController[MyProblem val, MyGenomeOps val, MyConfig val]
      .create(env, MyProblem, MyGenomeOps, MyConfig, reporter)
```

## Advanced Features

### Adaptive Diversity System
The framework automatically detects evolutionary stagnation and responds with:
- Increased mutation rates
- Fresh genome injection
- Reduced elitism
- More random exploration

### Nucleo-Aware Design Patterns

1. **Preserve Codon Boundaries**: Align mutations and crossovers with functional units
2. **Respect Nucleo Types**: Different nucleos may need different mutation strategies
3. **Functional Grouping**: Keep related nucleos together during crossover
4. **Progressive Disruption**: Light mutations for refinement, heavy for exploration

### Custom Reporting
Extend the reporter for domain-specific logging:
```pony
actor MyReporter is ReportSink
  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val) =>
    // Custom progress reporting
    None
  
  be save_best(gen: USize, fitness: F64, genome: Array[U8] val) =>
    // Custom genome persistence
    None
```

## Framework Philosophy

This framework treats evolution as a biological-inspired process where:
- **Nucleos** are the fundamental building blocks (like DNA bases)
- **Codons** are functional units formed by nucleo combinations (like genetic codons)
- **Genomes** are complete sequences that define individual solutions
- **Evolution** optimizes both nucleos and their combinations into effective codons

The framework handles all evolutionary mechanics (selection, reproduction, diversity management) while you focus on problem-specific nucleo definitions and codon formation rules.

## Development and Testing

### Framework Testing
The framework is thoroughly tested in the powers_of_two implementation:
```bash
# Run comprehensive framework tests
./pony test powers_of_two

# Test individual components
./pony compile powers_of_two  # Compile without conflicts
```

### Framework Integration Patterns
When integrating this framework:

1. **Copy the `_framework/` directory** to your project
2. **Implement the three core traits** (ProblemDomain, GenomeOperations, GAConfiguration)
3. **Create a main actor** that instantiates the GA controller
4. **Define your nucleo types** and codon formation rules
5. **Test with small populations first** to validate your fitness function

### Debugging Evolution
The framework provides extensive logging through:
- **Real-time progress**: Generation, best fitness, average fitness
- **Stagnation tracking**: Automatic detection of evolutionary plateaus
- **Genome persistence**: Save/load elite genomes for analysis
- **YAML metrics**: Human-readable evolution statistics

### Performance Considerations
- **Population size**: Start small (50-100), scale up based on problem complexity
- **Genome size**: Larger genomes need more generations to explore effectively
- **Mutation rates**: Higher rates for exploration, lower for exploitation
- **Stagnation thresholds**: Adjust based on your problem's convergence behavior

The framework is designed to be both powerful for research and practical for real applications.