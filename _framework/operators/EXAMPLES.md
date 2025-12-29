# Operators Library - Complete Examples

This file contains complete, runnable examples demonstrating how to use the operators library across different GA problems.

## Example 1: Binary Classifier with Weighted Voting

**Problem**: Classify text sentiment (positive/negative) using evolved feature weights.

**Implementation** (see `sentiment_analysis/core/weighted_classifier.pony`):

```pony
// Sentiment-specific wrapper for the generic WeightedVotingClassifier
use "../../_framework/operators/classifiers"

primitive WeightedClassifier
  """
  Sentiment analysis classifier using the generic WeightedVotingClassifier operator.

  Genome size: 50 bytes (one weight per feature)
  Returns: 0 = Positive, 1 = Negative
  """

  fun genome_size(): USize => 50

  fun classify(genome: Array[U8] val, features: Array[F64] val): USize =>
    """Classify sentiment using the generic weighted voting operator."""
    WeightedVotingClassifier.classify(genome, features)

  fun get_scores(genome: Array[U8] val, features: Array[F64] val): (F64, F64) =>
    """Get raw class scores (class0_score, class1_score)"""
    WeightedVotingClassifier.get_scores(genome, features)
```

**Domain Integration**:

```pony
class SentimentDomain is ProblemDomain
  fun genome_size(): USize => WeightedClassifier.genome_size()

  fun evaluate(genome: Array[U8] val): F64 =>
    // Extract features from text
    let features = FeatureExtractor.extract(text, lexicons...)

    // Use generic operator for classification
    let predicted = WeightedClassifier.classify(genome, features)

    // Calculate fitness based on accuracy
    if predicted == expected_class then 1.0 else 0.0 end
```

**Benefits**:
- ✅ 50 weights vs 797 for neural network (98% reduction)
- ✅ Prevents degenerate solutions naturally
- ✅ Easy to understand and debug
- ✅ Reusable across any binary classification problem

## Example 2: Integer Decoding for Numeric Problems

**Problem**: Evolve genomes to represent specific integer values.

**Using Little-Endian Decoder**:

```pony
use "../../_framework/operators/decoders"

class IntegerSearchDomain is ProblemDomain
  let _target: U64 = 42

  fun genome_size(): USize => 2  // 2 bytes = 0-65535 range

  fun evaluate(genome: Array[U8] val): F64 =>
    // Decode genome to integer using little-endian
    let value = BinaryDecoder.decode_le(genome)

    // Fitness: closer to target = higher score
    let distance = if value > _target then
      value - _target
    else
      _target - value
    end

    1.0 / (1.0 + distance.f64())
```

**Using Gray Code Decoder** (smoother evolution):

```pony
class GrayCodeSearchDomain is ProblemDomain
  let _target: U64 = 12345

  fun genome_size(): USize => 4  // 4 bytes = 32-bit integer

  fun evaluate(genome: Array[U8] val): F64 =>
    // Gray code prevents Hamming cliffs (adjacent values differ by 1 bit)
    let value = BinaryDecoder.decode_gray(genome)

    let distance = if value > _target then
      value - _target
    else
      _target - value
    end

    1.0 / (1.0 + distance.f64())
```

**Why Gray Code?**
- Adjacent integers differ by only 1 bit
- Smoother fitness landscape for genetic algorithms
- No "Hamming cliffs" where one bit flip causes large value change

## Example 3: Continuous Optimization

**Problem**: Find optimal real value in continuous range.

```pony
use "../../_framework/operators/decoders"

class ContinuousOptimization is ProblemDomain
  """
  Find x in [0, 100] that minimizes f(x) = (x - 42)^2
  """

  fun genome_size(): USize => 8  // 8 bytes for precision

  fun evaluate(genome: Array[U8] val): F64 =>
    // Decode genome to real value in range [0.0, 100.0]
    let x = BinaryDecoder.decode_range(genome, 0.0, 100.0)

    // Fitness function: minimize squared error
    let error = (x - 42.0).abs()
    let max_error = 42.0

    1.0 - (error / max_error)  // 1.0 = perfect, 0.0 = worst

  fun display_result(genome: Array[U8] val): String =>
    let x = BinaryDecoder.decode_range(genome, 0.0, 100.0)
    "Optimal x = " + x.string() + " (target: 42.0)"
```

**Real-World Applications**:
- Parameter tuning (learning rates, temperatures)
- Physics simulations (finding equilibrium points)
- Engineering design (optimal dimensions, ratios)

## Example 4: Using Standard Mutation Operators

**Problem**: Implement mutation operations using reusable operators instead of custom code.

**Before** (custom mutation):

```pony
primitive MyGenomeOperations is GenomeOperations
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    recover val
      let result = Array[U8](genome.size())
      for byte in genome.values() do
        result.push(byte)
      end

      // Custom mutation logic - specific to this domain
      let mutation_count = 1 + (rng.next().usize() % (genome.size() / 20))
      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % result.size()
          let current = result(pos)?
          let delta = (rng.next().i32() % 41) - 20
          let new_val = (current.i32() + delta).max(0).min(255)
          result(pos)? = new_val.u8()
        end
      end

      result
    end
```

**After** (using generic operator):

```pony
use "../../_framework/operators/mutations"

primitive MyGenomeOperations is GenomeOperations
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Use generic Gaussian mutation - much simpler!
    StandardMutations.gaussian_mutate(rng, genome, 0.05, 10.0)

  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    // Combine multiple mutation strategies
    var result = genome

    // First: scramble a segment (exploration)
    result = StandardMutations.scramble_mutate(rng, result)

    // Second: mutate random bytes (exploitation)
    result = StandardMutations.byte_mutate(rng, result, 0.2)

    result
```

**Benefits**:
- ✅ Less code to write and maintain
- ✅ Well-tested mutation strategies
- ✅ Easy to experiment with different approaches
- ✅ Consistent behavior across projects

**Choosing Mutation Strategy**:

| Operator | Best For | Strength |
|----------|----------|----------|
| `point_mutate` | Fine-tuning evolved solutions | Very weak |
| `creep_mutate` | Incremental improvements | Weak |
| `uniform_delta` | General-purpose mutation | Medium |
| `gaussian_mutate` | Weight tuning (classifiers) | Medium |
| `byte_mutate` | Escaping local optima | Strong |
| `inversion_mutate` | Gene ordering problems | Medium |
| `scramble_mutate` | Breaking out of stagnation | Very strong |

**Example**: Adaptive mutation (weak → strong over time)

```pony
primitive AdaptiveMutations
  fun mutate_adaptive(
    rng: Rand,
    genome: Array[U8] val,
    generation: USize,
    max_generations: USize): Array[U8] val =>

    // Start with Gaussian (exploitation), gradually add scramble (exploration)
    let progress = generation.f64() / max_generations.f64()

    if progress < 0.3 then
      // Early: strong mutation for exploration
      StandardMutations.byte_mutate(rng, genome, 0.15)
    elseif progress < 0.7 then
      // Middle: balanced mutation
      StandardMutations.gaussian_mutate(rng, genome, 0.1, 8.0)
    else
      // Late: fine-tuning
      StandardMutations.gaussian_mutate(rng, genome, 0.05, 3.0)
    end
```

## Example 5: Multi-Class Classification

**Problem**: Extend weighted voting to N classes.

```pony
use "../../_framework/operators/classifiers"

primitive MultiClassVoting
  """
  Extend binary classifier to multi-class using one-vs-all strategy.
  For N classes, use N binary classifiers.
  """

  fun classify_multi(
    genomes: Array[Array[U8] val] val,  // N genomes, one per class
    features: Array[F64] val): USize =>

    var best_class: USize = 0
    var best_score: F64 = 0.0

    for i in Range[USize](0, genomes.size()) do
      try
        let genome = genomes(i)?
        (let score_negative, let score_positive) =
          WeightedVotingClassifier.get_scores(genome, features)

        if score_positive > best_score then
          best_score = score_positive
          best_class = i
        end
      end
    end

    best_class
```

## Design Patterns

### Pattern 1: Thin Wrapper
Create domain-specific primitives that wrap generic operators:

```pony
// Generic operator (in _framework/operators/)
primitive WeightedVotingClassifier
  fun classify(genome, features) => ...

// Domain-specific wrapper (in your project)
primitive SentimentClassifier
  fun classify(genome, features) =>
    WeightedVotingClassifier.classify(genome, features)
```

### Pattern 2: Direct Usage
Use operators directly in domain evaluation:

```pony
class MyDomain is ProblemDomain
  fun evaluate(genome: Array[U8] val): F64 =>
    let value = BinaryDecoder.decode_le(genome)
    // ... fitness calculation
```

### Pattern 3: Composition
Combine multiple operators:

```pony
class HybridDomain is ProblemDomain
  fun evaluate(genome: Array[U8] val): F64 =>
    // First half: decode to integer
    let int_part = genome.slice(0, 4)
    let n = BinaryDecoder.decode_le(int_part)

    // Second half: classify features
    let classifier_part = genome.slice(4, 54)
    let predicted = WeightedVotingClassifier.classify(classifier_part, features)

    // Combined fitness
    fitness_from_integer(n) + fitness_from_classification(predicted)
```

## Performance Considerations

### Memory Efficiency
All operators are **primitives** (no allocation):
- `BinaryDecoder`: Pure function, no state
- `WeightedVotingClassifier`: Pure function, no state

### Computation Cost
- `BinaryDecoder.decode_le()`: O(n) where n = genome size
- `BinaryDecoder.decode_gray()`: O(n) decode + O(64) Gray-to-binary
- `WeightedVotingClassifier.classify()`: O(n) where n = feature count

All operators run in tight loops during evolution - they're optimized for speed.

## Testing Operators

Operators are framework-independent, so they're easy to unit test:

```pony
actor Main
  new create(env: Env) =>
    // Test binary decoder
    let genome = recover val [0xFF; 0x00; 0x12; 0x34] end
    let value = BinaryDecoder.decode_le(genome)
    env.out.print("Decoded value: " + value.string())

    // Test weighted classifier
    let weights = recover val Array[U8].init(128, 50) end  // All 0.5
    let features = recover val [1.0; 2.0; 3.0] end
    let predicted = WeightedVotingClassifier.classify(weights, features)
    env.out.print("Predicted class: " + predicted.string())
```

## Adding New Operators

When creating a new operator:

1. **Keep it pure**: No side effects, no state
2. **Make it generic**: Work for broad class of problems
3. **Document clearly**: Show usage examples
4. **Consider performance**: Runs in tight loops
5. **Test independently**: Unit test without framework

Example template:

```pony
primitive MyNewOperator
  """
  Brief description of what this operator does.

  Usage:
    let result = MyNewOperator.operate(genome, params)
  """

  fun operate(genome: Array[U8] val, param: F64): SomeResult =>
    """Detailed description of this function."""
    // Pure implementation
    // No framework dependencies
    // Return computed result
```

## Summary

The operators library enables:

✅ **Code reuse** - Write once, use across multiple problems
✅ **Separation of concerns** - Framework handles evolution, operators handle domain logic
✅ **Easy testing** - Test operators independently from GA
✅ **Composition** - Mix and match operators as needed
✅ **Performance** - Optimized primitives with no allocation overhead

See `README.md` for directory structure and philosophy.
