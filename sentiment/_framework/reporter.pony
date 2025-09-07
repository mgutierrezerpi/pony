// Generic progress reporter for GA
// Handles logging and saving of best genomes

use "files"

actor GenericReporter is ReportSink
  let _env: Env
  let _save_path: String
  var _last_best: F64 = -1.0
  var _last_logged_gen: USize = 0
  
  new create(env: Env, save_path: String = "bin/") =>
    _env = env
    _save_path = save_path
  
  be tick(gen: USize, best: F64, avg: F64, genome: Array[U8] val) =>
    // Log every 10 generations, or when fitness improves significantly, or when perfect
    let should_log = ((gen % 10) == 0) or (best > (_last_best + 0.01)) or (best >= 0.99999)
    
    if should_log then
      _env.out.print("gen=" + gen.string() + " best=" + best.string() + " avg=" + avg.string())
      _last_logged_gen = gen
    end
    
    _last_best = best
  
  be save_best(gen: USize, fitness: F64, genome: Array[U8] val) =>
    """
    Save the best genome to a file.
    """
    let gen_padded = _pad_generation(gen)
    let auth = FileAuth(_env.root)
    let path = FilePath(auth, _save_path + "best_genome_gen_" + gen_padded + ".bytes")
    
    let file = File(path)
    file.write(genome)
    file.sync()
    file.dispose()
  
  fun _pad_generation(gen: USize): String =>
    if gen < 10 then
      "00" + gen.string()
    elseif gen < 100 then
      "0" + gen.string()
    else
      gen.string()
    end