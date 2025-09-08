// Virtual Machine configuration and instruction set
// Defines the opcodes and VM architecture for powers of 2 evolution

primitive VMInstructionSet
  """
  Defines all available VM opcodes and their numeric values.
  
  The VM has 12 different instructions that genomes can use:
  - NOP: No operation (do nothing)
  - ZERO: Set register to 0  
  - INC: Increment register by 1
  - MOV: Copy value between registers
  - ADD: Add one register to another
  - SWAP: Exchange values between two registers
  - LOADN: Load the input value n into a register
  - CONST1: Load constant 1 into a register
  - CONST0: Load constant 0 into a register
  - DEC: Decrement register by 1 (enables counting down)
  - DOUBLE: Multiply register by 2 (key for powers of 2!)
  - LOOP: If src register > 0, decrement it and jump back to dst instruction
  """
  
  // Instruction opcodes (0-11)
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
  - 16 instructions maximum per program
  - 3 bytes per instruction (opcode + 2 operands)
  - Total genome size: 16 × 3 = 48 bytes
  """
  
  fun register_count(): U8 => 4           // Number of available registers (R0-R3)
  fun instructions_per_program(): USize => 16    // Maximum instructions in a genome
  fun bytes_per_instruction(): USize => 3        // [opcode, destination, source]
  fun total_genome_bytes(): USize => instructions_per_program() * bytes_per_instruction()

primitive InstructionValidator
  """
  Utilities to ensure instruction bytes are within valid ranges.
  Prevents invalid opcodes or register references that could crash the VM.
  """
  
  fun clamp_register_index(raw_register: U8): U8 =>
    """Ensures register index is valid (0-3)."""
    raw_register % VMArchitecture.register_count()
  
  fun clamp_opcode(raw_opcode: U8): U8 =>
    """Ensures opcode is valid (0-11)."""
    let total_opcodes: U8 = 12
    raw_opcode % total_opcodes

// Legacy aliases for backwards compatibility with existing code
primitive OPCODE
  """Legacy aliases for instruction opcodes to maintain compatibility."""
  fun nop(): U8 => VMInstructionSet.no_operation()
  fun zero(): U8 => VMInstructionSet.zero_register()
  fun inc(): U8 => VMInstructionSet.increment()
  fun mov(): U8 => VMInstructionSet.move_register()
  fun add(): U8 => VMInstructionSet.add_registers()
  fun swap(): U8 => VMInstructionSet.swap_registers()
  fun loadn(): U8 => VMInstructionSet.load_input()
  fun const1(): U8 => VMInstructionSet.load_constant_1()
  fun const0(): U8 => VMInstructionSet.load_constant_0()
  fun dec(): U8 => VMInstructionSet.decrement()
  fun double(): U8 => VMInstructionSet.double_value()
  fun loop(): U8 => VMInstructionSet.loop_if_nonzero()

primitive VMConfig
  """Legacy aliases for VM configuration to maintain compatibility."""
  fun reg_count(): U8 => VMArchitecture.register_count()
  fun prog_len(): USize => VMArchitecture.instructions_per_program()
  fun instr_bytes(): USize => VMArchitecture.bytes_per_instruction()
  fun genome_len(): USize => VMArchitecture.total_genome_bytes()

primitive _Clamp
  """Legacy validator functions to maintain compatibility."""
  fun reg(register_byte: U8): U8 => InstructionValidator.clamp_register_index(register_byte)
  fun opc(opcode_byte: U8): U8 => InstructionValidator.clamp_opcode(opcode_byte)