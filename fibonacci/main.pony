// Fibonacci Genetic Algorithm
//
// Terminology:
// - Genome: Raw bytes representing an evolvable VM program
// - Execution: Running the VM instructions for a given input n
// - Fitness: How well the genome's execution matches expected results
//
// This project evolves VM programs that learn to compute Fibonacci numbers
// through genetic algorithms, without knowing the algorithm beforehand.

actor Main
  new create(env: Env) =>
    GAController(env)