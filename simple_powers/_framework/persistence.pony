// Generic persistence utilities for saving and loading genomes

use "files"

primitive GenomePersistence
  """
  Utilities for saving and loading genomes to/from disk.
  """
  
  fun save_genome(env: Env, path: String, genome: Array[U8] val): Bool =>
    """
    Save a genome to a file.
    """
    let auth = FileAuth(env.root)
    let file_path = FilePath(auth, path)
    
    let file = File(file_path)
    file.write(genome)
    file.sync()
    file.dispose()
    true
  
  fun load_genome(env: Env, path: String, expected_size: USize): (Array[U8] val | None) =>
    """
    Load a genome from a file.
    """
    let auth = FileAuth(env.root)
    let file_path = FilePath(auth, path)
    
    if not file_path.exists() then
      return None
    end
    
    let file = File.open(file_path)
    let bytes = file.read(expected_size)
    file.dispose()
    
    if bytes.size() == expected_size then
      recover val
        let arr = Array[U8](expected_size)
        for b in (consume bytes).values() do
          arr.push(b)
        end
        arr
      end
    else
      None
    end
  
  fun find_latest_generation(env: Env, base_path: String, prefix: String = "best_genome_gen_", 
                            suffix: String = ".bytes", max_search: USize = 100000): (USize, Array[U8] val | None) =>
    """
    Find the latest saved generation and load its genome.
    """
    let auth = FileAuth(env.root)
    var gen: USize = max_search
    
    while gen > 0 do
      let gen_padded = _pad_generation(gen)
      let path = FilePath(auth, base_path + prefix + gen_padded + suffix)
      if path.exists() then
        // Found the latest generation
        let file = File.open(path)
        let bytes = file.read(1024) // Read up to 1KB
        file.dispose()
        
        if bytes.size() > 0 then
          let genome = recover val
            let arr = Array[U8](bytes.size())
            for b in (consume bytes).values() do
              arr.push(b)
            end
            arr
          end
          return (gen, genome)
        end
      end
      gen = gen - 1
    end
    
    (0, None)
  
  fun clear_all_generations(env: Env, base_path: String, prefix: String = "best_genome_gen_",
                           suffix: String = ".bytes", max_search: USize = 100000): USize =>
    """
    Clear all saved generation files.
    """
    let auth = FileAuth(env.root)
    var deleted: USize = 0
    var gen: USize = 1
    
    while gen <= max_search do
      let gen_padded = _pad_generation(gen)
      let path = FilePath(auth, base_path + prefix + gen_padded + suffix)
      if path.exists() then
        if path.remove() then
          deleted = deleted + 1
        end
      end
      gen = gen + 1
    end
    
    deleted
  
  fun _pad_generation(gen: USize): String =>
    if gen < 10 then
      "00" + gen.string()
    elseif gen < 100 then
      "0" + gen.string()
    else
      gen.string()
    end