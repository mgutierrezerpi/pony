// Test entry point - separate from main.pony to avoid conflicts
// This file is used by the test runner script

use "pony_test"

actor Main
  new create(env: Env) => 
    // Create and run the test suite
    TestRunner.create(env)