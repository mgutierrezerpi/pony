actor Main
  new create(env: Env) =>
    env.out.print("Starting actor-based model tests...")
    
    test_actor_creation(env)
    test_actor_communication(env)
    test_actor_concurrency(env)
    
    env.out.print("All tests initiated!")

  fun test_actor_creation(env: Env) =>
    env.out.print("Test 1: Actor Creation")
    let counter = Counter(env)
    counter.increment()
    counter.get_count({(count: U32) =>
      env.out.print("Counter value: " + count.string())
    })

  fun test_actor_communication(env: Env) =>
    env.out.print("Test 2: Actor Communication")
    let ping_actor = PingActor(env)
    let pong_actor = PongActor(env)
    
    ping_actor.start_ping(pong_actor, 3)

  fun test_actor_concurrency(env: Env) =>
    env.out.print("Test 3: Actor Concurrency")
    
    var i: U32 = 0
    while i < 5 do
      let worker = Worker(env, i)
      worker.do_work(100)
      i = i + 1
    end

actor Counter
  let _env: Env
  var _count: U32 = 0
  
  new create(env: Env) =>
    _env = env
    _env.out.print("Counter actor created")
  
  be increment() =>
    _count = _count + 1
  
  be get_count(callback: {(U32)} val) =>
    callback(_count)

actor PingActor
  let _env: Env
  
  new create(env: Env) =>
    _env = env
  
  be start_ping(pong: PongActor, count: U32) =>
    _env.out.print("Ping! (remaining: " + count.string() + ")")
    if count > 0 then
      pong.pong(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end
  
  be ping(pong: PongActor, count: U32) =>
    _env.out.print("Ping! (remaining: " + count.string() + ")")
    if count > 0 then
      pong.pong(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end

actor PongActor
  let _env: Env
  
  new create(env: Env) =>
    _env = env
  
  be pong(ping: PingActor, count: U32) =>
    _env.out.print("Pong! (remaining: " + count.string() + ")")
    if count > 0 then
      ping.ping(this, count - 1)
    else
      _env.out.print("Ping-pong complete!")
    end

actor Worker
  let _env: Env
  let _id: U32
  
  new create(env: Env, id: U32) =>
    _env = env
    _id = id
  
  be do_work(iterations: U32) =>
    var sum: U64 = 0
    var i: U32 = 0
    while i < iterations do
      sum = sum + i.u64()
      i = i + 1
    end
    
    _env.out.print("Worker " + _id.string() + " computed sum: " + sum.string())