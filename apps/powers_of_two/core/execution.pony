// Virtual Machine execution engine for powers of 2
// Executes evolved genomes as VM programs with registers and nucleos (atomic operations)

primitive VirtualMachine
  """
  Virtual Machine that executes evolved genomes as programs.
  
  Architecture:
  - 4 registers (R0, R1, R2, R3) for storing values
  - 16 nucleos per genome (3 bytes each = 48 total bytes)
  - 12 different nucleo types for various atomic operations
  - Nucleos combine into codons (functional sequences) to compute 2^n for input n
  """
  
  fun run(program_genome: Array[U8] val, input_value: USize): USize =>
    """
    Executes a genome as a VM program with the given input.
    
    The VM starts with:
    - R0 = 0 (accumulator/result register)
    - R1 = 1 (useful for multiplication operations)  
    - R2 = 0 (general purpose)
    - R3 = 0 (general purpose)
    
    Returns the value in R0 after program execution.
    """
    // Initialize virtual machine registers
    var register_0: USize = 0   // Primary result register
    var register_1: USize = 1   // Initialized to 1 for multiplication base
    var register_2: USize = 0   // General purpose register
    var register_3: USize = 0   // General purpose register
    
    // Execute each nucleo in the genome
    var program_counter: USize = 0
    let max_nucleos: USize = VMArchitecture.nucleos_per_genome()  // 16 nucleos
    var execution_steps: USize = 0
    let max_execution_steps: USize = 1000  // Prevent infinite loops
    
    while (program_counter < max_nucleos) and (execution_steps < max_execution_steps) do
      let nucleo_byte_offset = program_counter * 3
      
      // Safety check for genome bounds
      if nucleo_byte_offset >= program_genome.size() then break end
      
      try
        // Decode the 3-byte nucleo
        let raw_opcode = program_genome(nucleo_byte_offset)?
        let raw_destination = program_genome(nucleo_byte_offset + 1)?
        let raw_source = program_genome(nucleo_byte_offset + 2)?
        
        // Clamp values to valid ranges
        let nucleo_opcode = NucleoValidator.clamp_nucleo_opcode(raw_opcode)
        let destination_register = NucleoValidator.clamp_register_index(raw_destination)
        let source_register = NucleoValidator.clamp_register_index(raw_source)
        
        // Execute the nucleo (atomic operation)
        match nucleo_opcode
        | VMNucleoSet.no_operation() => 
          // No operation - do nothing
          None
          
        | VMNucleoSet.zero_register() =>
          // Set destination register to zero
          match destination_register
          | 0 => register_0 = 0
          | 1 => register_1 = 0
          | 2 => register_2 = 0
          | 3 => register_3 = 0
          end
          
        | VMNucleoSet.increment() =>
          // Increment destination register by 1
          match destination_register
          | 0 => register_0 = register_0 + 1
          | 1 => register_1 = register_1 + 1
          | 2 => register_2 = register_2 + 1
          | 3 => register_3 = register_3 + 1
          end
          
        | VMNucleoSet.move_register() =>
          // Move value from source register to destination register
          let source_value = _RegisterAccess.read_register(source_register, register_0, register_1, register_2, register_3)
          (register_0, register_1, register_2, register_3) = 
            _RegisterAccess.write_register(destination_register, source_value, register_0, register_1, register_2, register_3)
          
        | VMNucleoSet.add_registers() =>
          // Add source register value to destination register
          let source_value = _RegisterAccess.read_register(source_register, register_0, register_1, register_2, register_3)
          match destination_register
          | 0 => register_0 = register_0 + source_value
          | 1 => register_1 = register_1 + source_value
          | 2 => register_2 = register_2 + source_value
          | 3 => register_3 = register_3 + source_value
          end
          
        | VMNucleoSet.swap_registers() =>
          // Swap values between two registers
          (register_0, register_1, register_2, register_3) = 
            _RegisterSwapper.swap_registers(destination_register, source_register, register_0, register_1, register_2, register_3)
          
        | VMNucleoSet.load_input() =>
          // Load the input value (n) into destination register
          match destination_register
          | 0 => register_0 = input_value
          | 1 => register_1 = input_value
          | 2 => register_2 = input_value
          | 3 => register_3 = input_value
          end
          
        | VMNucleoSet.load_constant_1() =>
          // Load constant 1 into destination register
          match destination_register
          | 0 => register_0 = 1
          | 1 => register_1 = 1
          | 2 => register_2 = 1
          | 3 => register_3 = 1
          end
          
        | VMNucleoSet.load_constant_0() =>
          // Load constant 0 into destination register
          match destination_register
          | 0 => register_0 = 0
          | 1 => register_1 = 0
          | 2 => register_2 = 0
          | 3 => register_3 = 0
          end
          
        | VMNucleoSet.decrement() =>
          // Decrement destination register by 1 (minimum 0)
          match destination_register
          | 0 => register_0 = if register_0 > 0 then register_0 - 1 else 0 end
          | 1 => register_1 = if register_1 > 0 then register_1 - 1 else 0 end
          | 2 => register_2 = if register_2 > 0 then register_2 - 1 else 0 end
          | 3 => register_3 = if register_3 > 0 then register_3 - 1 else 0 end
          end
          
        | VMNucleoSet.double_value() =>
          // Double (multiply by 2) the destination register - KEY INSTRUCTION!
          match destination_register
          | 0 => register_0 = register_0 * 2
          | 1 => register_1 = register_1 * 2
          | 2 => register_2 = register_2 * 2
          | 3 => register_3 = register_3 * 2
          end
          
        | VMNucleoSet.loop_if_nonzero() =>
          // Loop: if source register > 0, decrement it and jump to destination instruction
          let loop_counter_value = _RegisterAccess.read_register(source_register, register_0, register_1, register_2, register_3)
          if loop_counter_value > 0 then
            // Decrement the loop counter
            (register_0, register_1, register_2, register_3) = 
              _RegisterAccess.write_register(source_register, loop_counter_value - 1, register_0, register_1, register_2, register_3)
            
            // Jump back to the destination nucleo (if valid)
            if destination_register.usize() < max_nucleos then
              program_counter = destination_register.usize()
              program_counter = program_counter - 1  // Will be incremented at end of loop
            end
          end
        end
      end
      
      program_counter = program_counter + 1
      execution_steps = execution_steps + 1
    end
    
    // Return the final value in register 0 as the program result
    register_0

// Helper primitives for cleaner nucleo execution organization

primitive _RegisterAccess
  """Helper for reading and writing register values."""
  
  fun read_register(register_index: U8, r0: USize, r1: USize, r2: USize, r3: USize): USize =>
    """Reads the value from the specified register."""
    match register_index
    | 0 => r0
    | 1 => r1
    | 2 => r2
    | 3 => r3
    else 0  // Default case (should not occur due to clamping)
    end
  
  fun write_register(register_index: U8, new_value: USize, r0: USize, r1: USize, r2: USize, r3: USize): (USize, USize, USize, USize) =>
    """Writes a value to the specified register and returns updated register state."""
    match register_index
    | 0 => (new_value, r1, r2, r3)
    | 1 => (r0, new_value, r2, r3)  
    | 2 => (r0, r1, new_value, r3)
    | 3 => (r0, r1, r2, new_value)
    else (r0, r1, r2, r3)  // Default case
    end

primitive _RegisterSwapper
  """Helper for swapping values between registers."""
  
  fun swap_registers(reg_a: U8, reg_b: U8, r0: USize, r1: USize, r2: USize, r3: USize): (USize, USize, USize, USize) =>
    """Swaps values between two specified registers."""
    match (reg_a, reg_b)
    | (0, 1) => (r1, r0, r2, r3)  // Swap R0 ↔ R1
    | (1, 0) => (r1, r0, r2, r3)  // Same as above
    | (0, 2) => (r2, r1, r0, r3)  // Swap R0 ↔ R2  
    | (2, 0) => (r2, r1, r0, r3)  // Same as above
    | (0, 3) => (r3, r1, r2, r0)  // Swap R0 ↔ R3
    | (3, 0) => (r3, r1, r2, r0)  // Same as above
    | (1, 2) => (r0, r2, r1, r3)  // Swap R1 ↔ R2
    | (2, 1) => (r0, r2, r1, r3)  // Same as above
    | (1, 3) => (r0, r3, r2, r1)  // Swap R1 ↔ R3
    | (3, 1) => (r0, r3, r2, r1)  // Same as above
    | (2, 3) => (r0, r1, r3, r2)  // Swap R2 ↔ R3
    | (3, 2) => (r0, r1, r3, r2)  // Same as above
    else (r0, r1, r2, r3)         // No swap for invalid combinations
    end

// Create an alias for easier access from other files
primitive VM
  """Convenience alias for VirtualMachine."""
  fun run(genome: Array[U8] val, input: USize): USize =>
    VirtualMachine.run(genome, input)