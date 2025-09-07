// Test runner for VM verification
// Standalone executable for running unit tests

use "collections"

actor Main
  new create(env: Env) =>
    env.out.print("=== VM Unit Tests ===")
    VMTests.run_tests(env)

primitive VMTests
  fun run_tests(env: Env) =>
    env.out.print("Testing refactored VM...")
    
    // Test 1: Simple NOP genome returns 0
    let nop_genome = recover val
      let arr = Array[U8](48)
      for i in Range[USize](0, 48) do
        arr.push(0)  // All NOPs
      end
      arr
    end
    
    if VM.run(nop_genome, 5) == 0 then
      env.out.print("✓ NOP test passed")
    else
      env.out.print("✗ NOP test failed")
    end
    
    // Test 2: CONST1 instruction
    let const_genome = recover val
      let arr = Array[U8](48)
      arr.push(OPCODE.const1()); arr.push(0); arr.push(0)
      for i in Range[USize](3, 48) do
        arr.push(0)
      end
      arr
    end
    
    if VM.run(const_genome, 1) == 1 then
      env.out.print("✓ CONST1 test passed")
    else
      env.out.print("✗ CONST1 test failed")
    end
    
    // Test 3: ADD instruction
    let add_genome = recover val
      let arr = Array[U8](48)
      // Set R0 = 1, R1 = 1 (from initial state), then ADD
      arr.push(OPCODE.const1()); arr.push(0); arr.push(0)
      arr.push(OPCODE.add()); arr.push(0); arr.push(1)
      for i in Range[USize](6, 48) do
        arr.push(0)
      end
      arr
    end
    
    if VM.run(add_genome, 1) == 2 then
      env.out.print("✓ ADD test passed")
    else
      env.out.print("✗ ADD test failed: got " + VM.run(add_genome, 1).string())
    end
    
    // Test 4: LOADN instruction
    let loadn_genome = recover val
      let arr = Array[U8](48)
      arr.push(OPCODE.loadn()); arr.push(0); arr.push(0)
      for i in Range[USize](3, 48) do
        arr.push(0)
      end
      arr
    end
    
    if VM.run(loadn_genome, 7) == 7 then
      env.out.print("✓ LOADN test passed")
    else
      env.out.print("✗ LOADN test failed")
    end
    
    // Test that it works with evolved genome
    env.out.print("\nTesting with Fibonacci values:")
    env.out.print("F(0) = " + Fib.fib(0).string() + " (expected 0)")
    env.out.print("F(1) = " + Fib.fib(1).string() + " (expected 1)")
    env.out.print("F(5) = " + Fib.fib(5).string() + " (expected 5)")
    env.out.print("F(10) = " + Fib.fib(10).string() + " (expected 55)")
    
    env.out.print("\n✅ All VM tests completed!")