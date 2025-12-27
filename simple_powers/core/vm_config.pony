// Virtual Machine configuration and nucleo instruction set
// Defines the nucleos (atomic operations) and VM architecture for powers of 2 evolution

primitive VMNucleoSet
  """
  Defines all available VM nucleos (atomic operations) and their numeric values.
  
  The VM has 12 different nucleos that genomes can use:
  - NOP: No operation nucleo (do nothing)
  - ZERO: Zero register nucleo (set register to 0)  
  - INC: Increment nucleo (increment register by 1)
  - MOV: Move nucleo (copy value between registers)
  - ADD: Addition nucleo (add one register to another)
  - SWAP: Swap nucleo (exchange values between two registers)
  - LOADN: Load input nucleo (load the input value n into a register)
  - CONST1: Load constant 1 nucleo (load constant 1 into a register)
  - CONST0: Load constant 0 nucleo (load constant 0 into a register)
  - DEC: Decrement nucleo (decrement register by 1, enables counting down)
  - DOUBLE: Double nucleo (multiply register by 2, key for powers of 2!)
  - LOOP: Loop control nucleo (if src register > 0, decrement it and jump back to dst instruction)
  """
  
  // Nucleo opcodes (0-11) - each represents an atomic operation
  fun no_operation(): U8 => 0      // NOP: Do nothing
  fun zero_register(): U8 => 1     // ZERO dst         -> R[dst] = 0
  fun increment(): U8 => 2         // INC  dst         -> R[dst] = R[dst] + 1
  fun move_register(): U8 => 3     // MOV  dst, src    -> R[dst] = R[src]
  fun add_registers(): U8 => 4     // ADD  dst, src    -> R[dst] = R[dst] + R[src]
  fun swap_registers(): U8 => 5    // SWAP a, b        -> swap R[a] and R[b]
  fun load_input(): U8 => 6        // LOADN dst        -> R[dst] = n (input value)
  fun load_constant_1(): U8 => 7   // CONST1 dst       -> R[dst] = 1
  fun load_constant_0(): U8 => 8   // CONST0 dst       -> R[dst] = 0
  fun decrement(): U8 => 9         // DEC dst          -> R[dst] = R[dst] - 1 (min 0)
  fun double_value(): U8 => 10     // DOUBLE dst       -> R[dst] = R[dst] * 2
  fun loop_if_nonzero(): U8 => 11  // LOOP dst, src    -> if R[src] > 0 then R[src]--, PC = dst

primitive VMArchitecture
  """
  Defines the virtual machine architecture parameters.
  
  Architecture specifications:
  - 4 registers (R0, R1, R2, R3) for data storage
  - 16 nucleos maximum per genome (each program is a sequence of nucleos)
  - 3 bytes per nucleo (opcode + 2 operands)
  - Total genome size: 16 nucleos × 3 bytes = 48 bytes
  
  Codons are formed by combining nucleos into functional sequences.
  """
  
  fun register_count(): U8 => 4           // Number of available registers (R0-R3)
  fun nucleos_per_genome(): USize => 16    // Maximum nucleos in a genome
  fun bytes_per_nucleo(): USize => 3        // [opcode, destination, source]
  fun total_genome_bytes(): USize => nucleos_per_genome() * bytes_per_nucleo()

primitive NucleoValidator
  """
  Utilities to ensure nucleo bytes are within valid ranges.
  Prevents invalid opcodes or register references that could crash the VM.
  """
  
  fun clamp_register_index(raw_register: U8): U8 =>
    """Ensures register index is valid (0-3)."""
    raw_register % VMArchitecture.register_count()
  
  fun clamp_nucleo_opcode(raw_opcode: U8): U8 =>
    """Ensures nucleo opcode is valid (0-11)."""
    let total_nucleos: U8 = 12
    raw_opcode % total_nucleos

