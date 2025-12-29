# GA Operators Library

This directory contains **reusable components** for genetic algorithm problems.

## Philosophy

The framework provides the **evolution engine**, but problems need **domain-specific logic** like:
- How to interpret genomes (decoders)
- How to make decisions (classifiers)
- How to vary genomes (mutations)

These operators are **plug-and-play** components you can use across different GA problems.

## Directory Structure

### `classifiers/`
Binary and multi-class classifiers that can be evolved:
- `weighted_voting.pony` - Simple weighted voting for binary classification
- (Future: decision trees, linear separators, etc.)

### `decoders/`
Ways to interpret byte arrays as meaningful values:
- `binary_decoder.pony` - Convert genomes to integers or real numbers
- (Future: instruction decoders for VM programs, graph decoders, etc.)

### `mutations/`
Reusable mutation strategies for byte array genomes:

**`standard_mutations.pony`** - General-purpose mutations for any byte array:
  - Point mutation (flip individual bits)
  - Byte mutation (replace entire bytes)
  - Gaussian mutation (add Gaussian noise)
  - Uniform delta (add/subtract within range)
  - Creep mutation (increment/decrement by 1)
  - Inversion mutation (reverse segments)
  - Scramble mutation (shuffle segments)

**`vm_mutations.pony`** - Specialized mutations for VM instruction genomes:
  - Instruction-aware mutations (respect instruction boundaries)
  - Constraint-based mutations (enforce opcode/register limits)
  - Heavy mutation (randomize entire instructions)
  - Instruction-level crossover
  - Instruction inversion (reverse sequences)

## Usage Examples

### Example 1: Sentiment Analysis with Weighted Voting

```pony
use "../../_framework"
use "../../_framework/operators/classifiers"

class MySentimentDomain is ProblemDomain
  fun evaluate(genome: Array[U8] val): F64 =>
    let features = extract_features(some_text)
    let predicted = WeightedVotingClassifier.classify(genome, features)
    // ... compare with expected label
```

### Example 2: Powers of Two with Binary Decoder

```pony
use "../../_framework"
use "../../_framework/operators/decoders"

primitive PowersOfTwoDomain is ProblemDomain
  fun evaluate(genome: Array[U8] val): F64 =>
    let n = BinaryDecoder.decode_le(genome)
    let result = compute_power_of_two(n)
    // ... fitness based on result
```

### Example 3: Continuous Optimization

```pony
use "../../_framework/operators/decoders"

// Evolve a value in range [0.0, 100.0] to minimize f(x) = (x - 42)^2
class MyOptimizationDomain is ProblemDomain
  fun genome_size(): USize => 8  // 8 bytes for precision

  fun evaluate(genome: Array[U8] val): F64 =>
    // Decode genome to value in [0, 100]
    let x = BinaryDecoder.decode_range(genome, 0.0, 100.0)

    // Fitness: how close to 42? (minimize squared error)
    let error = (x - 42.0).abs()
    let max_error = 42.0
    1.0 - (error / max_error)  // Higher fitness = closer to 42
```

### Example 4: Integer Search with Gray Code

```pony
use "../../_framework/operators/decoders"

// Find integer closest to target using Gray code (smoother evolution)
class GrayCodeSearch is ProblemDomain
  fun genome_size(): USize => 4  // 4 bytes = 32-bit integer

  fun evaluate(genome: Array[U8] val): F64 =>
    let target: U64 = 12345
    let value = BinaryDecoder.decode_gray(genome)

    // Fitness based on distance from target
    let distance = if value > target then
      value - target
    else
      target - value
    end

    1.0 / (1.0 + distance.f64())  // Closer = higher fitness
```

## Design Goals

✅ **Framework-independent** - Operators don't depend on GA framework
✅ **Composable** - Mix and match operators as needed
✅ **Reusable** - Use the same operator across different problems
✅ **Tested** - Each operator can be unit tested independently

## Contributing New Operators

When adding a new operator:
1. Keep it **pure** - no framework dependencies
2. Make it **generic** - work for broad class of problems
3. **Document** with examples
4. Consider **performance** - these run in tight loops
