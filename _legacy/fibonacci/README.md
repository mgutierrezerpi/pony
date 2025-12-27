# Fibonacci Genetic Algorithm in Pony

This project implements a genetic algorithm that evolves a virtual machine program to compute the Fibonacci sequence without knowing the algorithm beforehand.

## Overview

The genetic algorithm evolves "genomes" (sequences of VM instructions) that are executed to predict Fibonacci numbers. Through mutation, crossover, and selection over many generations, the algorithm discovers a program that correctly computes the Fibonacci sequence.

### Key Concepts

- **Genome**: Raw bytes representing an evolvable VM program
- **Execution**: Running the VM instructions for a given input `n`
- **Fitness**: How closely the genome's output matches the true Fibonacci values

### VM Architecture

The virtual machine has:
- 4 registers (R0-R3)
- 9 opcodes: NOP, ZERO, INC, MOV, ADD, SWAP, LOADN, CONST1, CONST0
- Programs of 16 instructions (3 bytes each)

## Building

From the fibonacci directory:

```bash
../pony compile .
```

This will create an executable at `./bin/.1`

## Running

To run the genetic algorithm:

```bash
./bin/.1
```

The program will:
1. Start with a population of 250 random genomes
2. Evolve for 400 generations
3. Output progress every generation showing:
   - Generation number
   - Best fitness score (max 1.0)
   - Average population fitness
   - Holdout set RMSE (should approach 0 for good solutions)
   - Sample prediction for F(12)
4. Save the best genome periodically to console output

## Configuration

You can adjust parameters in the code:

- `GAConf.pop()`: Population size (default: 250)
- `GAConf.gens()`: Number of generations (default: 400)
- `GAConf.mutation_rate()`: Probability of mutation per byte (default: 0.06)
- `GAConf.tournament_k()`: Tournament selection size (default: 5)

## Expected Output

A successful run will show the fitness improving over generations until it reaches ~0.768 with a holdout RMSE of 0.0, indicating the evolved program correctly computes Fibonacci numbers for the test cases.

Example output:
```
gen=7 best=0.76834 avg=0.06236
  holdout_rmse=0.00000 | sample: F(12)=144, got=144
```

This shows the algorithm has found a perfect solution by generation 7!

## How It Works

1. **Initialization**: Creates random genome programs
2. **Evaluation**: Each genome is executed for n=0 to n=10, comparing outputs to true Fibonacci values
3. **Selection**: Tournament selection picks better performers
4. **Reproduction**: Selected genomes undergo crossover and mutation
5. **Iteration**: Process repeats for specified generations

The algorithm typically discovers a working Fibonacci implementation within the first 10-50 generations.