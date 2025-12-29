# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

Always use the `./stables` script for all compilation and execution:

```bash
# Compile a project
./stables compile <project_name>

# Run a compiled project
./stables run <project_name> [args...]

# Run tests
./stables test <project_name>

# Show help
./stables help
```

**NEVER use `ponyc` directly** - the script handles proper output paths and binary naming.

## Testing

For projects with test files (e.g., `test_vm.pony`):
```bash
./stables test fibonacci
```

This compiles and runs the test suite, which includes unit tests and validation with trained genomes.

## Genetic Framework - Vision

### 1. DEFINE FITNESS
Fitness is measured as % of confidence based on a set of fixed and variable test case results. Before starting to train a genome, define the expectations to hold it against. This involves:
- Creating a comprehensive test suite with known inputs/outputs
- Defining success metrics (accuracy, RMSE, classification rate)
- Establishing minimum acceptable performance thresholds

### 2. DIVIDE & CONQUER GENES
Define different gene bucketing variations through responsibility splitting - breaking complex tasks into smaller, manageable components. Different splitting strategies can yield different performance:
- **Single responsibility**: One gene type for the entire task
- **Functional separation**: Different genes for different operations (e.g., arithmetic vs control flow)
- **Hierarchical**: Genes that coordinate other genes
- Try multiple alternatives to find optimal gene organization

### 3. DEFINE EACH GENE NUCLEO
A NUCLEO is an atomic operation that can be:
- **Stand-alone**: Complete functional unit by itself
- **Part of a CODON**: Combined with other nucleos to form small functional units

Example: In Fibonacci, nucleos are VM instructions (ADD, MOV, LOADN) that combine into codons (sequences performing additions and register management) to achieve the complete algorithm.

### 4. EVOLUTION CYCLE
The core loop powered by Pony actors (parallel execution is mandatory):
1. **Execute**: Run genomes against test cases
2. **Measure**: Calculate fitness scores
3. **Select**: Choose best performers for reproduction
4. **Reproduce**: Create next generation via crossover/mutation
5. **Persist**: Save `.yaml` files (performance stats, gene composition) and `.bytes` files (genome binary data)

This cycle continues until target fitness is achieved or generation limit is reached.

## Project Architecture

The repository follows a monorepo-style structure:

```
stables/
├── packages/              # Reusable framework code
│   └── _framework/        # Core GA framework
├── apps/                  # Applications
│   ├── powers_of_two/     # Powers of 2 evolution
│   ├── sentiment_analysis/# Sentiment classifier
│   └── web_server/        # REST API for models
├── stables                # Build script
├── README.md
└── CLAUDE.md
```

### Core Framework Structure

The codebase implements genetic algorithms (GA) using Pony's actor model for parallel evolution:

1. **`packages/_framework/` directory**: Reusable GA framework components
   - `interfaces.pony`: Core traits (ProblemDomain, GenomeOperations, GAConfiguration)
   - `ga_controller.pony`: Main evolution logic and selection algorithms
   - `parallel_ga.pony`: Actor-based parallel fitness evaluation
   - `persistence.pony`: Binary genome storage (.bytes files)
   - `metrics_persistence.pony`: YAML metrics tracking
   - `reporter.pony`: Progress reporting and logging
   - `operators/`: Reusable genetic operators (mutations, classifiers, decoders)

2. **`apps/` directory**: Complete applications using the framework
   - Each app has its own `core/` directory with domain-specific implementations
   - Problem-specific domain classes implementing framework interfaces
   - VM configurations and execution engines
   - Neural network implementations

3. **Actor Model Usage**:
   - Main actor coordinates evolution
   - FitnessWorker actors evaluate genomes in parallel
   - Supervisor pattern for robust parallel execution

### Key Applications

**powers_of_two/**: Evolves VM programs to compute powers of 2
- Virtual machine with 4 registers and 12 opcodes
- Genome = 16 instructions × 3 bytes = 48 bytes
- Test suite in `test/` directory
- Uses VM-aware mutation operators

**sentiment_analysis/**: Multilingual sentiment classification
- 50-feature extraction from text (NRC emotion lexicon)
- Weighted voting classifier (50 weights)
- Supports English and Spanish text analysis
- IMDB dataset training (50,000 reviews)
- Parallel evaluation with worker actors

**web_server/**: REST API for trained models
- Exposes sentiment analysis via HTTP endpoints
- JSON request/response format
- Configurable via environment variables

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
./stables run <project> resume [generations]
```

## Common Development Tasks

### Adding a New Genetic Algorithm Project

1. Create project directory in `apps/` with standard structure:
   ```
   apps/project_name/
   ├── main.pony           # Entry point
   ├── core/               # Domain implementation
   └── bin/                # Compiled binaries (auto-created)
   ```

2. Import framework from packages:
   ```pony
   use "../../packages/_framework"
   use "../../packages/_framework/operators/mutations"
   ```

3. Implement domain traits in `core/` directory

4. Projects are automatically discovered by `./stables` script in `apps/` folder

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