# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

Always use the `./pony` script for all compilation and execution:

```bash
# Compile a project
./pony compile <project_name>

# Run a compiled project
./pony run <project_name> [args...]

# Run tests
./pony test <project_name>

# Show help
./pony help
```

**NEVER use `ponyc` directly** - the script handles proper output paths and binary naming.

## Testing

For projects with test files (e.g., `test_vm.pony`):
```bash
./pony test fibonacci
```

This compiles and runs the test suite, which includes unit tests and validation with trained genomes.

## Project Architecture

### Core Framework Structure

The codebase implements genetic algorithms (GA) using Pony's actor model for parallel evolution:

1. **`_framework/` directory**: Reusable GA framework components
   - `interfaces.pony`: Core traits (ProblemDomain, GenomeOperations, GAConfiguration)
   - `ga_controller.pony`: Main evolution logic and selection algorithms
   - `parallel_ga.pony`: Actor-based parallel fitness evaluation (sentiment only)
   - `persistence.pony`: Binary genome storage (.bytes files)
   - `metrics_persistence.pony`: YAML metrics tracking (sentiment only)
   - `reporter.pony`: Progress reporting and logging

2. **`core/` directory**: Domain-specific implementations
   - Problem-specific domain classes implementing framework interfaces
   - VM configurations and execution engines (fibonacci)
   - Neural network implementations (sentiment)

3. **Actor Model Usage**:
   - Main actor coordinates evolution
   - FitnessWorker actors evaluate genomes in parallel (11 workers in sentiment)
   - Supervisor pattern demonstrated in `supervisor/` project

### Key Projects

**fibonacci/**: Evolves VM programs to compute Fibonacci sequence
- Virtual machine with 4 registers and 9 opcodes
- Genome = 16 instructions × 3 bytes = 48 bytes
- Test suite in `test_vm.pony`

**sentiment/**: Multilingual sentiment classification using evolved neural networks
- 50-feature extraction from text (NRC emotion lexicon)
- Neural network: 50→15→3 architecture (813 weights)
- Supports English and Spanish text analysis
- Parallel evaluation with 11 worker actors

**actors/** and **supervisor/**: Actor model demonstrations

## Domain Implementation Pattern

When implementing a new GA problem:

1. Create a class implementing `ProblemDomain` trait:
   - `genome_size()`: Return byte array size
   - `evaluate()`: Calculate fitness for a genome
   - `random_genome()`: Generate initial random genome

2. Implement `GenomeOperations` for genetic operators:
   - `mutate()`: Standard mutation
   - `heavy_mutate()`: Aggressive mutation
   - `crossover()`: Two-parent recombination

3. Configure via `GAConfiguration` trait implementation

## File Persistence

The framework saves genomes and metrics:
- `bin/gen_XXXXX.bytes`: Raw genome bytes
- `bin/gen_XXXXX.yaml`: Evaluation metrics (sentiment project)
- `bin/evolution_summary.yaml`: Complete run summary

To resume training from saved state:
```bash
./pony run <project> resume [generations]
```

## Common Development Tasks

### Adding a New Genetic Algorithm Project

1. Create project directory with standard structure:
   ```
   project_name/
   ├── main.pony           # Entry point
   ├── core/               # Domain implementation
   └── _framework/         # Copy or symlink framework
   ```

2. Implement domain traits in `core/` directory

3. Update `./pony` script if needed for new commands

### Modifying GA Parameters

Edit configuration in domain implementation:
- Population size: `GAConf.pop()`
- Generations: `GAConf.gens()`
- Mutation rate: `GAConf.mutation_rate()`
- Tournament size: `GAConf.tournament_k()`

## Important Notes

- All projects use Pony's reference capabilities for memory safety
- Genomes are `Array[U8] val` (immutable byte arrays)
- Use `recover val` blocks when creating new genomes
- Actor messages use `be` (behavior) methods
- The framework heavily uses pattern matching with `match` expressions