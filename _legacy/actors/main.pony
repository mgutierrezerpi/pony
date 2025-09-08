// Main actor - this is the entry point for the Pony program
// In Pony, every program starts with a Main actor
actor Main
  // Constructor - called when the program starts
  // env: Env provides access to system resources like stdout, stdin, command line args
  new create(env: Env) =>
    env.out.print("Starting actor-based model tests...")
    
    // Call our three test functions to demonstrate different actor patterns
    test_actor_creation(env)
    test_actor_communication(env)
    test_actor_concurrency(env)
    
    env.out.print("All tests initiated!")

  // Test 1: Basic actor creation and simple message passing
  fun test_actor_creation(env: Env) =>
    env.out.print("Test 1: Actor Creation")
    // Create a new Counter actor instance
    let counter = Counter(env)
    // Send an asynchronous message to increment the counter
    counter.increment()
    // Send another message with a callback lambda function
    // This demonstrates how actors can return values via callbacks
    counter.get_count({(count: U32) =>
      env.out.print("Counter value: " + count.string())
    })

  // Test 2: Inter-actor communication with message passing
  fun test_actor_communication(env: Env) =>
    env.out.print("Test 2: Actor Communication")
    // Create two actors that will communicate with each other
    let ping_actor = PingActor(env)
    let pong_actor = PongActor(env)
    
    // Start the ping-pong game with 3 rounds
    // This demonstrates how actors can send messages back and forth
    ping_actor.start_ping(pong_actor, 3)

  // Test 3: Concurrent execution with multiple actors
  fun test_actor_concurrency(env: Env) =>
    env.out.print("Test 3: Actor Concurrency")
    
    // Create 5 worker actors that will all run concurrently
    var i: U32 = 0
    while i < 5 do
      // Each worker gets a unique ID and runs independently
      let worker = Worker(env, i)
      // Send work to each actor - they all process simultaneously
      worker.do_work(100)
      i = i + 1
    end

// Counter actor - demonstrates basic state management in actors
actor Counter
  let _env: Env        // Immutable reference to environment (let = constant)
  var _count: U32 = 0  // Mutable state variable (var = mutable)
  
  // Actor constructor - called when Counter(env) is invoked
  new create(env: Env) =>
    _env = env
    _env.out.print("Counter actor created")
  
  // Behavior (be) - asynchronous message handler
  // This can be called from other actors and runs asynchronously
  be increment() =>
    _count = _count + 1
  
  // Another behavior that takes a callback function as parameter
  // The callback allows "returning" values from actors asynchronously
  be get_count(callback: {(U32)} val) =>
    callback(_count)  // Execute the callback with the current count

// PingActor - demonstrates actor-to-actor communication
actor PingActor
  let _env: Env
  
  new create(env: Env) =>
    _env = env
  
  // Behavior to start the ping-pong sequence
  // Takes another actor reference and a counter
  be start_ping(pong: PongActor, count: U32) =>
    _env.out.print("Ping! (remaining: " + count.string() + ")")
    if count > 0 then
      // Send a message to the PongActor with decremented count
      // 'this' refers to this PingActor instance
      pong.pong(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end
  
  // Behavior called by PongActor to continue the ping-pong
  be ping(pong: PongActor, count: U32) =>
    _env.out.print("Ping! (remaining: " + count.string() + ")")
    if count > 0 then
      // Continue the game by sending back to pong
      pong.pong(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end

// PongActor - the other half of the communication pair
actor PongActor
  let _env: Env
  
  new create(env: Env) =>
    _env = env
  
  // Behavior that responds to ping messages
  be pong(ping: PingActor, count: U32) =>
    _env.out.print("Pong! (remaining: " + count.string() + ")")
    if count > 0 then
      // Send message back to PingActor to continue the sequence
      ping.ping(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end

// Worker actor - demonstrates concurrent processing
actor Worker
  let _env: Env
  let _id: U32    // Each worker has a unique identifier
  
  new create(env: Env, id: U32) =>
    _env = env
    _id = id
  
  // Behavior that performs computational work
  // Multiple workers can run this simultaneously without interference
  be do_work(iterations: U32) =>
    var sum: U64 = 0  // Local variable for computation
    var i: U32 = 0
    
    // Simulate computational work by calculating a sum
    while i < iterations do
      sum = sum + i.u64()  // Convert U32 to U64 for the sum
      i = i + 1
    end
    
    // Each worker reports its result independently
    // The order of output may vary due to concurrent execution
    _env.out.print("Worker " + _id.string() + " computed sum: " + sum.string())