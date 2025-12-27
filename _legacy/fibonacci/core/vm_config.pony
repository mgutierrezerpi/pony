// VM instruction set and configuration

primitive OPCODE
  fun nop(): U8 => 0
  fun zero(): U8 => 1       // ZERO dst         -> R[dst] = 0
  fun inc(): U8 => 2        // INC  dst         -> R[dst] = 1 + R[dst]
  fun mov(): U8 => 3        // MOV  dst, src    -> R[dst] = R[src]
  fun add(): U8 => 4        // ADD  dst, src    -> R[dst] = R[dst] + R[src]
  fun swap(): U8 => 5       // SWAP a, b        -> swap R[a], R[b]
  fun loadn(): U8 => 6      // LOADN dst        -> R[dst] = n (loop count)
  fun const1(): U8 => 7     // CONST1 dst       -> R[dst] = 1
  fun const0(): U8 => 8     // CONST0 dst       -> R[dst] = 0

primitive VMConfig
  fun reg_count(): U8 => 4          // R0..R3
  fun prog_len(): USize => 16       // instructions per genome
  fun instr_bytes(): USize => 3     // [opcode, dst, src_or_b]
  fun genome_len(): USize => prog_len() * instr_bytes()

// Decode helpers
primitive _Clamp
  fun reg(i: U8): U8 => i % VMConfig.reg_count()
  fun opc(x: U8): U8 =>
    let m: U8 = 9
    x % m