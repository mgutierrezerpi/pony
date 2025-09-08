# Generic Genetic Algorithm Framework

This framework provides a reusable genetic algorithm implementation that can be adapted to solve various optimization problems.

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

```pony
// Define your problem domain
primitive MyProblem is ProblemDomain
  fun genome_size(): USize => 100
  fun evaluate(genome: Array[U8] val): F64 =>
    // Calculate fitness score
    ...
  // Implement other required methods

// Define genetic operators
primitive MyGenomeOps is GenomeOperations
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Implement mutation
    ...
  // Implement other operators

// Define configuration
primitive MyConfig is GAConfiguration
  fun population_size(): USize => 50
  // Set other parameters

// Run the GA
let reporter = GenericReporter(env, "output/")
GenericGAController[MyProblem val, MyGenomeOps val, MyConfig val]
  (env, MyProblem, MyGenomeOps, MyConfig, reporter)
```

## Included Examples

- **Fibonacci Sequence**: Evolve VM programs using nucleos (atomic operations) to compute Fibonacci numbers (see `core/fibonacci_domain.pony`)
- **Text Matching**: Evolve strings to match a target text (see `examples/text_matching.pony`)

## Extending the Framework

To use this framework for a new problem:

1. Create implementations of `ProblemDomain`, `GenomeOperations`, and `GAConfiguration`
2. Optionally customize the reporter for domain-specific logging
3. Create a main actor that instantiates the GA controller with your implementations

The framework handles all the evolutionary mechanics, allowing you to focus on problem-specific aspects.