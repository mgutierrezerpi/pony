// VM-specific mutation operators for genetic algorithms that evolve VM programs
// Specialized for genomes representing VM instruction sequences

use "random"
use "collections"

primitive VMMutations
  """
  Mutation operators specialized for VM instruction genomes.

  Assumes genome structure:
  - Genome = sequence of instructions (nucleos)
  - Each instruction = fixed number of bytes
  - Bytes have constrained value ranges (opcode limits, register limits, etc.)

  These mutations respect instruction boundaries and value constraints.

  Usage:
    let mutated = VMMutations.mutate_instructions(
      rng, genome,
      instruction_size = 3,
      mutation_count = 2,
      byte_constraints = [(0, 11); (0, 3); (0, 3)]  // opcode 0-11, regs 0-3
    )
  """

  fun mutate_instructions(
    rng: Rand,
    genome: Array[U8] val,
    instruction_size: USize,
    mutation_count: USize,
    byte_constraints: Array[(U8, U8)] val): Array[U8] val =>
    """
    Mutate random instructions while respecting byte value constraints.

    Args:
      rng: Random number generator
      genome: Original genome (instruction sequence)
      instruction_size: Bytes per instruction (e.g., 3 for [opcode, dest, src])
      mutation_count: Number of instructions to mutate
      byte_constraints: (min, max) pairs for each byte in instruction
                       Example: [(0, 11), (0, 3), (0, 3)] for VM with:
                         - 12 opcodes (0-11)
                         - 4 registers (0-3) for dest and src

    Returns: New mutated genome
    """
    if (genome.size() % instruction_size) != 0 then
      // Genome size doesn't match instruction size - return unchanged
      return genome
    end

    let num_instructions = genome.size() / instruction_size

    recover val
      let result = Array[U8](genome.size())
      for byte in genome.values() do
        result.push(byte)
      end

      // Mutate specified number of instructions
      for _ in Range[USize](0, mutation_count.min(num_instructions)) do
        try
          // Pick random instruction
          let instr_idx = rng.next().usize() % num_instructions
          let byte_start = instr_idx * instruction_size

          // Pick random byte within that instruction
          let byte_offset = rng.next().usize() % instruction_size
          let byte_idx = byte_start + byte_offset

          // Get constraints for this byte position
          let constraint_idx = byte_offset % byte_constraints.size()
          (let min_val, let max_val) = byte_constraints(constraint_idx)?

          // Generate new value within constraints
          let range_size = (max_val - min_val).u64() + 1
          let new_val = min_val + (rng.next() % range_size).u8()

          result(byte_idx)? = new_val
        end
      end

      result
    end

  fun heavy_mutate_instructions(
    rng: Rand,
    genome: Array[U8] val,
    instruction_size: USize,
    mutation_count: USize,
    byte_constraints: Array[(U8, U8)] val): Array[U8] val =>
    """
    Heavy mutation: completely randomize entire instructions.

    Similar to mutate_instructions but randomizes ALL bytes in selected instructions.
    """
    if (genome.size() % instruction_size) != 0 then
      return genome
    end

    let num_instructions = genome.size() / instruction_size

    recover val
      let result = Array[U8](genome.size())
      for byte in genome.values() do
        result.push(byte)
      end

      // Randomize entire instructions
      for _ in Range[USize](0, mutation_count.min(num_instructions)) do
        try
          let instr_idx = rng.next().usize() % num_instructions
          let byte_start = instr_idx * instruction_size

          // Randomize all bytes in this instruction
          for byte_offset in Range[USize](0, instruction_size) do
            let byte_idx = byte_start + byte_offset
            let constraint_idx = byte_offset % byte_constraints.size()
            (let min_val, let max_val) = byte_constraints(constraint_idx)?

            let range_size = (max_val - min_val).u64() + 1
            let new_val = min_val + (rng.next() % range_size).u8()

            result(byte_idx)? = new_val
          end
        end
      end

      result
    end

  fun crossover_instructions(
    rng: Rand,
    parent_a: Array[U8] val,
    parent_b: Array[U8] val,
    instruction_size: USize): (Array[U8] val, Array[U8] val) =>
    """
    Crossover that respects instruction boundaries.

    Swaps a contiguous block of instructions between parents.
    """
    if (parent_a.size() != parent_b.size()) or
       ((parent_a.size() % instruction_size) != 0) then
      // Incompatible sizes - return parents unchanged
      return (parent_a, parent_b)
    end

    let num_instructions = parent_a.size() / instruction_size

    // Choose two random instruction positions
    let point1 = rng.next().usize() % num_instructions
    let point2 = rng.next().usize() % num_instructions
    let start_instr = point1.min(point2)
    let end_instr = point1.max(point2)

    // Convert to byte positions
    let start_byte = start_instr * instruction_size
    let end_byte = end_instr * instruction_size

    // Create offspring
    let child1 = recover val
      let result = Array[U8](parent_a.size())
      for i in Range[USize](0, parent_a.size()) do
        try
          if (i >= start_byte) and (i < end_byte) then
            result.push(parent_b(i)?)
          else
            result.push(parent_a(i)?)
          end
        end
      end
      result
    end

    let child2 = recover val
      let result = Array[U8](parent_a.size())
      for i in Range[USize](0, parent_a.size()) do
        try
          if (i >= start_byte) and (i < end_byte) then
            result.push(parent_a(i)?)
          else
            result.push(parent_b(i)?)
          end
        end
      end
      result
    end

    (child1, child2)

  fun inversion_mutation(
    rng: Rand,
    genome: Array[U8] val,
    instruction_size: USize): Array[U8] val =>
    """
    Reverse a random sequence of instructions.

    Good for exploring different instruction orderings.
    """
    if (genome.size() % instruction_size) != 0 then
      return genome
    end

    let num_instructions = genome.size() / instruction_size
    if num_instructions < 2 then
      return genome
    end

    recover val
      let result = Array[U8](genome.size())
      for byte in genome.values() do
        result.push(byte)
      end

      // Pick two instruction positions
      let pos1 = rng.next().usize() % num_instructions
      let pos2 = rng.next().usize() % num_instructions
      let start_instr = pos1.min(pos2)
      let end_instr = pos1.max(pos2)

      // Reverse the instruction sequence
      try
        var i = start_instr
        var j = end_instr
        while i < j do
          // Swap entire instructions
          for byte_offset in Range[USize](0, instruction_size) do
            let idx_i = (i * instruction_size) + byte_offset
            let idx_j = (j * instruction_size) + byte_offset
            let temp = result(idx_i)?
            result(idx_i)? = result(idx_j)?
            result(idx_j)? = temp
          end
          i = i + 1
          j = j - 1
        end
      end

      result
    end
