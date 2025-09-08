# Powers of Two Genetic Algorithm

A sophisticated genetic algorithm implementation that evolves Virtual Machine programs to compute powers of 2 (2^n). This project demonstrates the nucleo/codon genetic framework concepts defined in CLAUDE.md.

## Project Overview

This project evolves VM programs that can correctly compute 2^n for any input n. Each genome represents a 16-instruction VM program where:

- **Nucleos**: Individual VM instructions (ADD, MOV, LOADN, DOUBLE, etc.)
- **Codons**: Functional sequences of nucleos that perform specific computations
- **Evolution**: The process of combining nucleos into effective codons that solve 2^n

## Architecture

```
powers_of_two/
├── main.pony              # Application entry point with CLI interface
├── core/                  # Problem-specific implementations
│   ├── execution.pony     # Virtual Machine that executes evolved genomes
│   ├── powers_domain.pony # Fitness evaluation and genetic operations
│   └── vm_config.pony     # VM architecture and nucleo definitions
├── _framework/            # Reusable genetic algorithm framework
├── test/                  # Test suite (separate from main source)
│   ├── test_vm.pony       # Comprehensive VM and evolution tests
│   └── test_main.pony     # Test runner entry point
└── bin/                   # Compiled binaries
```

## Virtual Machine Architecture

The evolved programs run on a specialized VM with:

- **4 registers** (R0, R1, R2, R3) for data storage
- **16 nucleos maximum** per genome (48 bytes total: 16 × 3 bytes)
- **12 different nucleo types** for various atomic operations:

### Available Nucleos

| Nucleo | Function | Description |
|--------|----------|-------------|
| NOP | No operation | Do nothing (skip cycle) |
| ZERO | Zero register | Set register to 0 |
| INC | Increment | Add 1 to register |
| MOV | Move | Copy value between registers |
| ADD | Add | Add one register to another |
| SWAP | Swap | Exchange values between registers |
| LOADN | Load input | Load input value n into register |
| CONST1 | Load 1 | Load constant 1 into register |
| CONST0 | Load 0 | Load constant 0 into register |
| DEC | Decrement | Subtract 1 from register |
| DOUBLE | Double | Multiply register by 2 (key for powers!) |
| LOOP | Loop control | Conditional jump for loops |

## Genetic Evolution Strategy

The system uses adaptive evolution with:

### Nucleo-Aware Genetic Operations
- **Light Mutation**: Small changes preserving codon structure
- **Heavy Mutation**: Large changes breaking codons for exploration
- **Crossover**: Combines nucleo sequences from successful parents
- **Fresh Injection**: Introduces random nucleos when evolution stagnates

### Adaptive Diversity Management
The system detects stagnation and responds with:
- **Normal operation**: 10% heavy mutations, 5% random genomes
- **Stagnation (100+ gens)**: 40% heavy mutations, 20% random genomes
- **Critical stagnation (1000+ gens)**: 80% heavy mutations, 50% random genomes

### Fitness Evaluation
Tests genomes on both fixed and random test cases:
- **Fixed cases**: 2^0 through 2^7 (must get these right)
- **Random cases**: 4 additional tests (2^0 through 2^9)
- **Scoring**: Percentage of test cases passed correctly

## Usage

### Training a New Model
```bash
# Start unlimited evolution (runs until perfect solution)
./pony run powers_of_two train

# Train with generation limit
./pony run powers_of_two resume 1000
```

### Using a Trained Model
```bash
# Compute 2^8 using best evolved genome
./pony run powers_of_two 8

# Test VM functionality
./pony run powers_of_two test 5
```

### Testing and Development
```bash
# Compile the project
./pony compile powers_of_two

# Run comprehensive test suite
./pony test powers_of_two

# Clear saved evolution data
./pony run powers_of_two clear
```

## Evolution Results

Successful evolution produces genomes that:
1. **Learn the doubling pattern**: Use DOUBLE nucleo effectively
2. **Handle base cases**: Correctly compute 2^0 = 1 and 2^1 = 2
3. **Form effective codons**: Combine nucleos like LOADN, LOOP, and DOUBLE
4. **Generalize well**: Work on unseen test cases beyond training data

## Technical Details

### VM Execution Model
- Programs execute sequentially through nucleos
- R0 serves as the primary result register
- R1 initialized to 1 (useful for multiplication operations)
- Maximum 1000 execution steps (prevents infinite loops)

### Evolution Parameters
- **Population**: 200 individuals
- **Tournament size**: 3 (moderate selection pressure)
- **Mutation rate**: 15% (high for exploration)
- **Crossover rate**: 70% (moderate recombination)
- **Elitism**: Top 3 genomes preserved each generation

### File Persistence
The system automatically saves:
- `bin/gen_XXXXX.bytes`: Raw genome binary data
- `bin/gen_XXXXX.yaml`: Human-readable metrics (when available)
- `bin/evolution_summary.yaml`: Complete run summary

## Framework Integration

This project serves as a comprehensive example of the `_framework/` genetic algorithm system, demonstrating:

- **ProblemDomain implementation**: PowersDomain with VM-specific fitness
- **GenomeOperations specialization**: Nucleo-aware genetic operators
- **GAConfiguration tuning**: Parameters optimized for VM evolution
- **Custom reporting**: Progress tracking and genome persistence

## Testing

The test suite validates:
- **VM correctness**: All 12 nucleo types work properly
- **Mathematical accuracy**: Powers of 2 calculation reference
- **Genetic operations**: Mutation and crossover preserve genome structure
- **Evolution components**: Fitness evaluation and genome generation
- **Integration**: End-to-end system functionality

Run tests with: `./pony test powers_of_two`

## Research Applications

This implementation demonstrates key concepts in:
- **Genetic Programming**: Evolving executable programs
- **Virtual Machine Design**: Minimal instruction sets for evolution
- **Adaptive Evolution**: Dynamic response to population stagnation
- **Nucleo/Codon Biology**: Biological-inspired genetic structures
- **Parallel Evolution**: Actor-based concurrent evaluation