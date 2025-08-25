use "time"
use "random"

// Main actor - entry point for the supervisor pattern demo
actor Main
  new create(env: Env) =>
    env.out.print("=== Supervisor Pattern Demo ===")
    env.out.print("Starting supervisor with 3 worker children...")
    
    // Create a supervisor that manages 3 worker actors
    let supervisor = Supervisor(env, 3)
    supervisor.start()

// Supervisor actor - manages child actors and restarts them when they fail
actor Supervisor
  let _env: Env
  let _worker_count: U32
  var _workers: Array[Worker] = Array[Worker]
  var _restart_timers: Array[(Worker, U64)] = Array[(Worker, U64)]
  
  new create(env: Env, worker_count: U32) =>
    _env = env
    _worker_count = worker_count
  
  // Start the supervisor and create initial workers
  be start() =>
    _env.out.print("[Supervisor] Starting supervision of " + _worker_count.string() + " workers")
    
    // Create the initial set of workers
    var i: U32 = 0
    while i < _worker_count do
      let worker = create_worker(i)
      _workers.push(worker)
      // Start the worker with some work
      worker.do_work()
      i = i + 1
    end
    
    // Start monitoring workers
    monitor_workers()
  
  // Create a new worker with the given ID
  fun create_worker(id: U32): Worker =>
    _env.out.print("[Supervisor] Creating worker " + id.string())
    Worker(_env, id, this)
  
  // Monitor workers periodically
  be monitor_workers() =>
    // Check each worker's health
    for worker in _workers.values() do
      worker.health_check()
    end
    
    // Schedule next monitoring check after 2 seconds
    let timers = Timers
    let timer = Timer(MonitorNotify(this), 2_000_000_000, 2_000_000_000)
    timers(consume timer)
  
  // Handle worker failure notification
  be worker_failed(worker_id: U32) =>
    _env.out.print("[Supervisor] Worker " + worker_id.string() + " has failed!")
    _env.out.print("[Supervisor] Scheduling restart in 3 seconds...")
    
    // Schedule restart after 3 seconds
    let timers = Timers
    let timer = Timer(RestartNotify(this, worker_id), 3_000_000_000, 0)
    timers(consume timer)
  
  // Restart a failed worker
  be restart_worker(worker_id: U32) =>
    _env.out.print("[Supervisor] Restarting worker " + worker_id.string() + "...")
    
    // Find and replace the failed worker
    try
      // Create new worker with same ID
      let new_worker = create_worker(worker_id)
      _workers(worker_id.usize())? = new_worker
      
      // Start the new worker
      new_worker.do_work()
      _env.out.print("[Supervisor] Worker " + worker_id.string() + " successfully restarted")
    else
      _env.out.print("[Supervisor] Error: Could not restart worker " + worker_id.string())
    end

// Worker actor - performs work and can fail randomly
actor Worker
  let _env: Env
  let _id: U32
  let _supervisor: Supervisor
  var _is_alive: Bool = true
  var _work_count: U32 = 0
  let _rand: Rand
  
  new create(env: Env, id: U32, supervisor: Supervisor) =>
    _env = env
    _id = id
    _supervisor = supervisor
    // Create random generator with unique seed per worker
    _rand = Rand(Time.nanos() + id.u64())
    _env.out.print("[Worker " + _id.string() + "] Created and ready to work")
  
  // Perform work (may fail randomly)
  be do_work() =>
    if not _is_alive then
      return
    end
    
    _work_count = _work_count + 1
    
    // Random chance of failure (20% chance)
    let failure_chance = _rand.int(100)
    if failure_chance < 20 then
      fail()
    else
      _env.out.print("[Worker " + _id.string() + "] Completed work item #" + _work_count.string())
      
      // Schedule next work after 1-3 seconds
      let delay = 1_000_000_000 + _rand.int(2_000_000_000)
      let timers = Timers
      let timer = Timer(WorkNotify(this), delay, 0)
      timers(consume timer)
    end
  
  // Worker failure
  fun ref fail() =>
    _is_alive = false
    _env.out.print("[Worker " + _id.string() + "] FAILED after " + _work_count.string() + " work items!")
    
    // Notify supervisor of failure
    _supervisor.worker_failed(_id)
  
  // Health check response
  be health_check() =>
    if _is_alive then
      _env.out.print("[Worker " + _id.string() + "] Health: OK (completed " + _work_count.string() + " items)")
    end

// Timer notify for monitoring
class MonitorNotify is TimerNotify
  let _supervisor: Supervisor
  
  new iso create(supervisor: Supervisor) =>
    _supervisor = supervisor
  
  fun ref apply(timer: Timer, count: U64): Bool =>
    _supervisor.monitor_workers()
    true  // Continue timer

// Timer notify for restarting workers
class RestartNotify is TimerNotify
  let _supervisor: Supervisor
  let _worker_id: U32
  
  new iso create(supervisor: Supervisor, worker_id: U32) =>
    _supervisor = supervisor
    _worker_id = worker_id
  
  fun ref apply(timer: Timer, count: U64): Bool =>
    _supervisor.restart_worker(_worker_id)
    false  // One-shot timer

// Timer notify for worker tasks
class WorkNotify is TimerNotify
  let _worker: Worker
  
  new iso create(worker: Worker) =>
    _worker = worker
  
  fun ref apply(timer: Timer, count: U64): Bool =>
    _worker.do_work()
    false  // One-shot timer