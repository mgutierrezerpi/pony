// Execution represents running the genome instructions
// This is the VM that executes a genome for a given input n

primitive VM
  fun run(genome: Array[U8] box, n: USize): I64 =>
    var r: Array[I64] = Array[I64](VMConfig.reg_count().usize())
    r.push(0); r.push(1); r.push(0); r.push(0)  // R0=0, R1=1, R2=0, R3=0
    let l = VMConfig.prog_len().usize()
    let step_bytes = VMConfig.instr_bytes().usize()

    // Execute program body for n steps (so loops can emerge)
    var t: USize = 0
    while t < n do
      var ip: USize = 0
      while ip < l do
        let base = ip * step_bytes
        let op: U8  = _Clamp.opc(try genome(base)? else 0 end)
        let a: U8   = _Clamp.reg(try genome(base + 1)? else 0 end)
        let b: U8   = _Clamp.reg(try genome(base + 2)? else 0 end)

        match op
        | OPCODE.nop() => None
        | OPCODE.zero() => try r(a.usize())? = 0 end
        | OPCODE.inc() => try r(a.usize())? = r(a.usize())? + 1 end
        | OPCODE.mov() => try r(a.usize())? = r(b.usize())? end
        | OPCODE.add() => try r(a.usize())? = r(a.usize())? + r(b.usize())? end
        | OPCODE.swap() =>
          try
            let tmp: I64 = r(a.usize())?
            r(a.usize())? = r(b.usize())?
            r(b.usize())? = tmp
          end
        | OPCODE.loadn() => try r(a.usize())? = n.i64() end
        | OPCODE.const1() => try r(a.usize())? = 1 end
        | OPCODE.const0() => try r(a.usize())? = 0 end
        else None
        end
        ip = ip + 1
      end
      t = t + 1
    end
    // Output register:
    try r(0)? else 0 end

// Ground truth for comparison
primitive Fib
  fun fib(n: USize): I64 =>
    if n < 2 then n.i64() end
    var a: I64 = 0
    var b: I64 = 1
    var i: USize = 1
    while i < n do
      let tmp: I64 = a + b
      a = b
      b = tmp
      i = i + 1
    end
    b