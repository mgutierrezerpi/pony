// Test runner for VM verification
// Standalone executable for running unit tests

use "collections"
use "random"
use "time"
use "files"
use "core"
use "_framework"

actor Main
  new create(env: Env) =>
    env.out.print("=== VM Unit Tests ===")
    let rng = Rand(Time.nanos(), Time.millis())
    VMTests.run_tests(env, rng)

primitive VMTests
  fun run_tests(env: Env, rng: Rand) =>
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
    
    // Test with the best trained genome and random inputs
    env.out.print("\nTesting trained genome with random inputs:")
    
    // Use the persistence helper to find the latest genome
    (let found_gen, let loaded_genome) = GenomePersistence.find_latest_generation(env, "fibonacci/bin/")
    
    match loaded_genome
    | let genome: Array[U8] val =>
      env.out.print("  Using trained genome from generation " + found_gen.string())
      
      // Test with 10 random values
      for test_num in Range[USize](1, 11) do
        // Generate a random n value between 0 and 30
        let n = rng.next().usize() % 31
        let expected = Fib.fib(n)
        let result = VM.run(genome, n)
        let is_correct = result == expected
        
        env.out.print("  Test " + test_num.string() + ": F(" + n.string() + ") = " + 
                     result.string() + " (expected " + expected.string() + ") " +
                     if is_correct then "✓" else "✗" end)
      end
      
      // Also test some edge cases
      env.out.print("\n  Edge cases:")
      let edge_cases: Array[USize] = [0; 1; 2; 50; 100]
      for n in edge_cases.values() do
        let expected = Fib.fib(n)
        let result = VM.run(genome, n)
        let is_correct = result == expected
        env.out.print("    F(" + n.string() + ") = " + result.string() + 
                     " (expected " + expected.string() + ") " +
                     if is_correct then "✓" else "✗" end)
      end
    | None =>
      env.out.print("  No trained genome found - skipping random input tests")
      env.out.print("  Run './pony run fibonacci train' first to generate a trained genome")
    end
    
    // Test with larger random values to verify Fib calculation speed
    env.out.print("\nTesting Fibonacci calculation performance:")
    let large_n = 100 + (rng.next().usize() % 900) // Random between 100 and 999
    let start_time = Time.nanos()
    let large_result = Fib.fib(large_n)
    let elapsed = Time.nanos() - start_time
    env.out.print("  F(" + large_n.string() + ") computed in " + 
                 (elapsed / 1000000).string() + "ms")
    env.out.print("  Result has " + large_result.string().size().string() + " digits")
    
    // Test a random genome's fitness evaluation
    env.out.print("\nTesting genome fitness evaluation:")
    let test_genome = recover val
      let arr = Array[U8](48)
      // Create a semi-structured genome with some valid operations
      arr.push(OPCODE.loadn()); arr.push(0); arr.push(0)  // Load n into R0
      arr.push(OPCODE.const1()); arr.push(1); arr.push(0) // Load 1 into R1
      arr.push(OPCODE.add()); arr.push(0); arr.push(1)    // Add R0 + R1
      // Fill rest with random
      for _ in Range[USize](9, 48) do
        arr.push(rng.next().u8())
      end
      arr
    end
    
    // Test the genome on several values
    env.out.print("  Testing semi-structured genome:")
    let test_values: Array[USize] = [0; 1; 2; 3; 5]
    for test_n in test_values.values() do
      let result = VM.run(test_genome, test_n)
      let expected = Fib.fib(test_n)
      env.out.print("    F(" + test_n.string() + "): got " + result.string() + 
                   ", expected " + expected.string())
    end
    
    env.out.print("\n✅ All VM tests completed!")