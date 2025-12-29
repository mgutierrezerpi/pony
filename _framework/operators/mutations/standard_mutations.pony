// Reusable mutation operators for genetic algorithms
// Can be used across any GA problem that uses byte array genomes

use "random"
use "collections"

primitive StandardMutations
  """
  Collection of standard mutation strategies for byte array genomes.

  All mutations are pure functions that take a genome and return a new mutated genome.
  They never modify the input genome (follow Pony's val semantics).

  Usage:
    let rng = Rand(seed)
    let mutated = StandardMutations.point_mutate(rng, genome, 0.01)
  """

  fun point_mutate(rng: Rand, genome: Array[U8] val, rate: F64): Array[U8] val =>
    """
    Point mutation: flip individual bits with given probability.

    Args:
      rng: Random number generator
      genome: Original genome
      rate: Mutation rate (0.0 = no mutation, 1.0 = mutate everything)

    Returns: New mutated genome

    Example:
      // Mutate ~1% of bits on average
      let mutated = StandardMutations.point_mutate(rng, genome, 0.01)
    """
    recover val
      let result = Array[U8](genome.size())

      for byte in genome.values() do
        var mutated_byte = byte

        // Check each bit
        for bit in Range[U8](0, 8) do
          if (rng.next().f64() / U64.max_value().f64()) < rate then
            // Flip this bit
            mutated_byte = mutated_byte xor (1 << bit)
          end
        end

        result.push(mutated_byte)
      end

      result
    end

  fun byte_mutate(rng: Rand, genome: Array[U8] val, rate: F64): Array[U8] val =>
    """
    Byte mutation: replace entire bytes with random values.

    Stronger than point mutation - replaces whole bytes instead of individual bits.

    Args:
      rng: Random number generator
      genome: Original genome
      rate: Mutation rate (0.0 = no mutation, 1.0 = mutate all bytes)

    Returns: New mutated genome

    Example:
      // Mutate ~5% of bytes
      let mutated = StandardMutations.byte_mutate(rng, genome, 0.05)
    """
    recover val
      let result = Array[U8](genome.size())

      for byte in genome.values() do
        if (rng.next().f64() / U64.max_value().f64()) < rate then
          // Replace with random byte
          result.push(rng.next().u8())
        else
          // Keep original
          result.push(byte)
        end
      end

      result
    end

  fun gaussian_mutate(
    rng: Rand,
    genome: Array[U8] val,
    rate: F64,
    sigma: F64 = 10.0): Array[U8] val =>
    """
    Gaussian mutation: add Gaussian noise to byte values.

    Good for fine-tuning - makes small adjustments around current values.

    Args:
      rng: Random number generator
      genome: Original genome
      rate: Probability of mutating each byte (0.0-1.0)
      sigma: Standard deviation of Gaussian noise (default: 10.0)

    Returns: New mutated genome

    Example:
      // Fine-tune weights with small adjustments
      let mutated = StandardMutations.gaussian_mutate(rng, genome, 0.1, 5.0)
    """
    recover val
      let result = Array[U8](genome.size())

      for byte in genome.values() do
        if (rng.next().f64() / U64.max_value().f64()) < rate then
          // Add Gaussian noise (using Box-Muller transform)
          let u1 = rng.next().f64() / U64.max_value().f64()
          let u2 = rng.next().f64() / U64.max_value().f64()

          // Box-Muller: generates standard normal distribution
          let z = ((-2.0 * u1.log()).sqrt() * (2.0 * 3.14159265359 * u2).cos())

          // Scale by sigma and add to current value
          let noise = (z * sigma).i32()
          let new_val = (byte.i32() + noise).max(0).min(255)

          result.push(new_val.u8())
        else
          result.push(byte)
        end
      end

      result
    end

  fun uniform_delta(
    rng: Rand,
    genome: Array[U8] val,
    rate: F64,
    max_delta: U8 = 20): Array[U8] val =>
    """
    Uniform delta mutation: add/subtract random values within range.

    Similar to Gaussian but with uniform distribution (simpler, no tails).

    Args:
      rng: Random number generator
      genome: Original genome
      rate: Probability of mutating each byte
      max_delta: Maximum change magnitude (default: 20)

    Returns: New mutated genome

    Example:
      // Adjust values by +/- 10
      let mutated = StandardMutations.uniform_delta(rng, genome, 0.1, 10)
    """
    recover val
      let result = Array[U8](genome.size())

      for byte in genome.values() do
        if (rng.next().f64() / U64.max_value().f64()) < rate then
          // Random delta in range [-max_delta, +max_delta]
          let delta = (rng.next().i32() % ((max_delta.i32() * 2) + 1)) - max_delta.i32()
          let new_val = (byte.i32() + delta).max(0).min(255)
          result.push(new_val.u8())
        else
          result.push(byte)
        end
      end

      result
    end

  fun creep_mutate(rng: Rand, genome: Array[U8] val, count: USize): Array[U8] val =>
    """
    Creep mutation: increment/decrement specific number of bytes by 1.

    Very conservative mutation - makes minimal changes.

    Args:
      rng: Random number generator
      genome: Original genome
      count: Number of bytes to mutate

    Returns: New mutated genome

    Example:
      // Adjust 3 random bytes by +1 or -1
      let mutated = StandardMutations.creep_mutate(rng, genome, 3)
    """
    recover val
      let result = Array[U8](genome.size())

      // Copy genome
      for byte in genome.values() do
        result.push(byte)
      end

      // Mutate 'count' random positions
      for _ in Range[USize](0, count) do
        try
          let pos = rng.next().usize() % result.size()
          let current = result(pos)?

          // +1 or -1
          let new_val = if (rng.next() % 2) == 0 then
            (current + 1).min(255)
          else
            (current - 1).max(0)
          end

          result(pos)? = new_val
        end
      end

      result
    end

  fun inversion_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Inversion mutation: reverse a random segment of the genome.

    Good for exploring different gene orderings.

    Args:
      rng: Random number generator
      genome: Original genome

    Returns: New genome with inverted segment

    Example:
      // Reverse a random segment
      let mutated = StandardMutations.inversion_mutate(rng, genome)
    """
    if genome.size() < 2 then
      return genome  // Nothing to invert
    end

    recover val
      let result = Array[U8](genome.size())

      // Copy genome
      for byte in genome.values() do
        result.push(byte)
      end

      // Pick two random points
      let pos1 = rng.next().usize() % genome.size()
      let pos2 = rng.next().usize() % genome.size()

      let start = pos1.min(pos2)
      let stop = pos1.max(pos2)

      // Reverse the segment [start, stop]
      try
        var i = start
        var j = stop
        while i < j do
          let temp = result(i)?
          result(i)? = result(j)?
          result(j)? = temp
          i = i + 1
          j = j - 1
        end
      end

      result
    end

  fun scramble_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Scramble mutation: randomly shuffle a segment of the genome.

    More disruptive than inversion - good for escaping local optima.

    Args:
      rng: Random number generator
      genome: Original genome

    Returns: New genome with scrambled segment

    Example:
      let mutated = StandardMutations.scramble_mutate(rng, genome)
    """
    if genome.size() < 2 then
      return genome
    end

    recover val
      let result = Array[U8](genome.size())

      // Copy genome
      for byte in genome.values() do
        result.push(byte)
      end

      // Pick segment to scramble
      let pos1 = rng.next().usize() % genome.size()
      let pos2 = rng.next().usize() % genome.size()

      let start = pos1.min(pos2)
      let stop = pos1.max(pos2)

      // Fisher-Yates shuffle on segment
      try
        var i = stop
        while i > start do
          let j = start + (rng.next().usize() % ((i - start) + 1))
          let temp = result(i)?
          result(i)? = result(j)?
          result(j)? = temp
          i = i - 1
        end
      end

      result
    end
