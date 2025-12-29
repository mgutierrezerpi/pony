// Genome Disassembler - Inspect evolved VM programs
// Shows what the genome actually does instruction by instruction

use "files"
use "../core"
use "../../_framework"

actor Main
  new create(env: Env) =>
    let args = env.args

    if args.size() < 2 then
      env.out.print("Usage: disassemble <generation_number>")
      env.out.print("Example: disassemble 983")
      return
    end

    try
      let gen = args(1)?.usize()?
      disassemble_genome(env, gen)
    else
      env.out.print("Error: Invalid generation number")
    end

  fun disassemble_genome(env: Env, gen: USize) =>
    // Load the genome from file
    (let loaded_gen, let genome_opt) = GenomePersistence.find_latest_generation(env, "powers_of_two/bin/")

    match genome_opt
    | let genome: Array[U8] val =>
      env.out.print("=== Genome Disassembly: Generation " + loaded_gen.string() + " ===")
      env.out.print("Fitness: " + (PowersDomain.evaluate(genome) * 100).string() + "%")
      env.out.print("")
      env.out.print("VM Program (48 bytes = 16 nucleos):")
      env.out.print("─────────────────────────────────────────────────────")

      // Disassemble each nucleo
      var pc: USize = 0
      while pc < 16 do
        let byte_offset = pc * 3
        try
          let opcode = genome(byte_offset)?
          let dest = genome(byte_offset + 1)?
          let src = genome(byte_offset + 2)?

          // Clamp to valid ranges
          let valid_opcode = opcode % 12
          let valid_dest = dest % 4
          let valid_src = src % 4

          let instruction = format_instruction(valid_opcode, valid_dest, valid_src)
          let comment = get_instruction_comment(valid_opcode)

          env.out.print(format_nucleo(pc, valid_opcode, valid_dest, valid_src, instruction, comment))
        end
        pc = pc + 1
      end

      env.out.print("─────────────────────────────────────────────────────")
      env.out.print("")

      // Test execution trace
      env.out.print("=== Execution Trace for n=5 (expecting 2^5 = 32) ===")
      trace_execution(env, genome, 5)

    | None =>
      env.out.print("No genome found in powers_of_two/bin/")
    end

  fun format_nucleo(pc: USize, opcode: U8, dest: U8, src: U8, instruction: String, comment: String): String =>
    let pc_str = if pc < 10 then " " + pc.string() else pc.string() end
    let bytes = "[" + opcode.string() + "," + dest.string() + "," + src.string() + "]"
    let padding_size = if bytes.size() < 10 then 10 - bytes.size() else 0 end
    let bytes_padded = bytes + String.from_array(recover val Array[U8].init(' ', padding_size) end).clone()
    pc_str + ": " + consume bytes_padded + instruction + "  // " + comment

  fun format_instruction(opcode: U8, dest: U8, src: U8): String =>
    match opcode
    | 0 => "NOP              "
    | 1 => "ZERO    R" + dest.string() + "       "
    | 2 => "INC     R" + dest.string() + "       "
    | 3 => "MOV     R" + dest.string() + ", R" + src.string() + "   "
    | 4 => "ADD     R" + dest.string() + ", R" + src.string() + "   "
    | 5 => "SWAP    R" + dest.string() + ", R" + src.string() + "   "
    | 6 => "LOADN   R" + dest.string() + "       "
    | 7 => "CONST1  R" + dest.string() + "       "
    | 8 => "CONST0  R" + dest.string() + "       "
    | 9 => "DEC     R" + dest.string() + "       "
    | 10 => "DOUBLE  R" + dest.string() + "       "
    | 11 => "LOOP    #" + dest.string() + ", R" + src.string() + "   "
    else "UNKNOWN         "
    end

  fun get_instruction_comment(opcode: U8): String =>
    match opcode
    | 0 => "Do nothing"
    | 1 => "Set register to 0"
    | 2 => "Increment register by 1"
    | 3 => "Copy value between registers"
    | 4 => "Add registers"
    | 5 => "Swap register values"
    | 6 => "Load input N into register"
    | 7 => "Load constant 1"
    | 8 => "Load constant 0"
    | 9 => "Decrement register by 1"
    | 10 => "Multiply register by 2 ⭐"
    | 11 => "Loop if register > 0"
    else "Unknown opcode"
    end

  fun trace_execution(env: Env, genome: Array[U8] val, n: USize) =>
    env.out.print("Input: n = " + n.string())
    env.out.print("Expected output: 2^" + n.string() + " = " + PowersOfTwoCalculator.compute_power_of_2(n).string())

    let result = VM.run(genome, n)
    env.out.print("Actual output: " + result.string())

    if result == PowersOfTwoCalculator.compute_power_of_2(n) then
      env.out.print("✓ CORRECT!")
    else
      env.out.print("✗ INCORRECT")
    end
