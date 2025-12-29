// Parallel Fitness Evaluation Worker
// Evaluates genomes in parallel using Pony's actor model

actor FitnessWorker[T: ProblemDomain val]
  """
  Worker actor that evaluates genome fitness in parallel.

  Multiple workers run concurrently, each evaluating different genomes.
  Results are sent back to the controller asynchronously.
  """
  let _domain: T
  let _receiver: FitnessReceiver tag

  new create(domain: T, receiver: FitnessReceiver tag) =>
    """
    Create a fitness worker.

    Parameters:
    - domain: Problem domain for fitness evaluation
    - receiver: Controller that receives fitness results
    """
    _domain = domain
    _receiver = receiver

  be evaluate(id: USize, genome: Array[U8] val) =>
    """
    Evaluate a genome's fitness and send result back to controller.

    This runs asynchronously in parallel with other workers.
    """
    let fitness = _domain.evaluate(genome)
    _receiver.got_fit(id, fitness)
