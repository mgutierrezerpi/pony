// Genome disassembler for powers of 2 VM programs
// Displays human-readable representation of nucleos and execution traces

use "../_framework"

primitive PowersDisassembler is GenomeDisassembler
  """
  Disassembles VM genomes into human-readable format.

  Shows:
  - Individual nucleos (VM instructions) with decoded mnemonics
  - Execution trace showing test results
  - Comments explaining what each nucleo does
  """

  fun disassemble_genome(env: Env, genome: Array[U8] val, fitness: F64) =>
    """
    Display complete disassembly of a powers of 2 VM genome.
    """
    env.out.print("=== Genome Disassembly ===")
    env.out.print("Fitness: " + (fitness * 100).string() + "%")
    env.out.print("")
    env.out.print("VM Program (48 bytes = 16 nucleos):")
    env.out.print("Nucleo  Bytes       Instruction      Comment")
    env.out.print("──────────────────────────────────────────────────────────────")

    // Disassemble each nucleo (instruction)
    var pc: USize = 0
    while pc < 16 do
      let byte_offset = pc * 3
      try
        let raw_opcode = genome(byte_offset)?
        let raw_dest = genome(byte_offset + 1)?
        let raw_src = genome(byte_offset + 2)?

        // Clamp to valid ranges (same as VM does)
        let opcode = raw_opcode % 12
        let dest = raw_dest % 4
        let src = raw_src % 4

        // Format instruction
        let pc_str = if pc < 10 then " " + pc.string() else pc.string() end
        let bytes_str = "[" + opcode.string() + "," + dest.string() + "," + src.string() + "]"

        // Get instruction name and comment
        (let inst_name, let comment) = _get_instruction_info(opcode, dest, src)

        // Build the line in parts to avoid reference capability issues
        let line = recover val
          let s = String
          s.append(consume pc_str)
          s.append(":     ")
          s.append(consume bytes_str)
          s.append("        ")
          s.append(consume inst_name)
          s.append("    # ")
          s.append(consume comment)
          s
        end
        env.out.print(line)
      end
      pc = pc + 1
    end

    env.out.print("──────────────────────────────────────────────────────────────")
    env.out.print("")

    // Show execution trace
    env.out.print("=== Execution Trace ===")
    let test_values: Array[USize] = [0; 1; 2; 3; 4; 5; 6; 7]
    for n in test_values.values() do
      let result = VM.run(genome, n)
      let expected = PowersOfTwoCalculator.compute_power_of_2(n)
      let status = if result == expected then "✓" else "✗" end

      let trace_line = recover val
        let s = String
        s.append("n=")
        s.append(n.string())
        s.append(": 2^")
        s.append(n.string())
        s.append(" = ")
        s.append(result.string())
        s.append(" (expected ")
        s.append(expected.string())
        s.append(") ")
        s.append(status)
        s
      end
      env.out.print(trace_line)
    end

  fun _get_instruction_info(opcode: U8, dest: U8, src: U8): (String, String) =>
    """
    Returns (instruction_mnemonic, comment) for a given nucleo.

    Each nucleo is one of 12 atomic operations that can combine into codons
    to achieve the overall computation.
    """
    match opcode
    | 0 => ("NOP             ", "Do nothing")
    | 1 => ("ZERO    R" + dest.string() + "      ", "Set R" + dest.string() + " = 0")
    | 2 => ("INC     R" + dest.string() + "      ", "R" + dest.string() + " = R" + dest.string() + " + 1")
    | 3 => ("MOV     R" + dest.string() + ", R" + src.string() + "  ", "R" + dest.string() + " = R" + src.string())
    | 4 => ("ADD     R" + dest.string() + ", R" + src.string() + "  ", "R" + dest.string() + " = R" + dest.string() + " + R" + src.string())
    | 5 => ("SWAP    R" + dest.string() + ", R" + src.string() + "  ", "Swap R" + dest.string() + " and R" + src.string())
    | 6 => ("LOADN   R" + dest.string() + "      ", "R" + dest.string() + " = input N")
    | 7 => ("CONST1  R" + dest.string() + "      ", "R" + dest.string() + " = 1")
    | 8 => ("CONST0  R" + dest.string() + "      ", "R" + dest.string() + " = 0")
    | 9 => ("DEC     R" + dest.string() + "      ", "R" + dest.string() + " = R" + dest.string() + " - 1")
    | 10 => ("DOUBLE  R" + dest.string() + "      ", "R" + dest.string() + " = R" + dest.string() + " * 2 ⭐")
    | 11 => ("LOOP    #" + dest.string() + ", R" + src.string() + "  ", "If R" + src.string() + " > 0: R" + src.string() + "--, PC=" + dest.string())
    else ("UNKNOWN        ", "Invalid opcode")
    end
