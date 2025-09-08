// Execution represents running the genome instructions
// This is the VM that executes a genome for a given input n

primitive VM
  fun run(genome: Array[U8] box, n: USize): I64 =>
    // Initialize registers: R0=0, R1=1, R2=0, R3=0
    let registers = _init_registers()
    
    // Execute the program n times (allows loops to emerge)
    _execute_n_times(genome, registers, n, n)
    
    // Return the result from register 0
    try registers(0)? else 0 end
  
  fun _init_registers(): Array[I64] =>
    let r = Array[I64](VMConfig.reg_count().usize())
    r.push(0); r.push(1); r.push(0); r.push(0)
    r
  
  fun _execute_n_times(genome: Array[U8] box, registers: Array[I64], n: USize, remaining: USize) =>
    if remaining == 0 then return end
    
    _execute_program(genome, registers, n)
    _execute_n_times(genome, registers, n, remaining - 1)
  
  fun _execute_program(genome: Array[U8] box, registers: Array[I64], n: USize) =>
    let prog_len = VMConfig.prog_len().usize()
    _execute_instructions(genome, registers, n, 0, prog_len)
  
  fun _execute_instructions(genome: Array[U8] box, registers: Array[I64], n: USize, 
                           ip: USize, prog_len: USize) =>
    if ip >= prog_len then return end
    
    _execute_single_instruction(genome, registers, n, ip)
    _execute_instructions(genome, registers, n, ip + 1, prog_len)
  
  fun _execute_single_instruction(genome: Array[U8] box, registers: Array[I64], 
                                  n: USize, ip: USize) =>
    // Decode instruction
    let base = ip * VMConfig.instr_bytes().usize()
    let op = _Clamp.opc(try genome(base)? else 0 end)
    let a = _Clamp.reg(try genome(base + 1)? else 0 end)
    let b = _Clamp.reg(try genome(base + 2)? else 0 end)
    
    // Execute operation
    _execute_opcode(registers, op, a, b, n)
  
  fun _execute_opcode(r: Array[I64], op: U8, a: U8, b: U8, n: USize) =>
    match op
    | OPCODE.nop()    => None
    | OPCODE.zero()   => try r(a.usize())? = 0 end
    | OPCODE.inc()    => try r(a.usize())? = r(a.usize())? + 1 end
    | OPCODE.mov()    => try r(a.usize())? = r(b.usize())? end
    | OPCODE.add()    => try r(a.usize())? = r(a.usize())? + r(b.usize())? end
    | OPCODE.swap()   => _swap_registers(r, a, b)
    | OPCODE.loadn()  => try r(a.usize())? = n.i64() end
    | OPCODE.const1() => try r(a.usize())? = 1 end
    | OPCODE.const0() => try r(a.usize())? = 0 end
    else None
    end
  
  fun _swap_registers(r: Array[I64], a: U8, b: U8) =>
    try
      let tmp = r(a.usize())?
      r(a.usize())? = r(b.usize())?
      r(b.usize())? = tmp
    end

// Ground truth for comparison
primitive Fib
  fun fib(n: USize): I64 =>
    """
    Efficient iterative Fibonacci calculation.
    Avoids exponential recursion for large values.
    """
    if n == 0 then
      return 0
    elseif n == 1 then
      return 1
    end
    
    var a: I64 = 0
    var b: I64 = 1
    var i: USize = 2
    
    while i <= n do
      let c = a + b
      a = b
      b = c
      i = i + 1
    end
    
    b