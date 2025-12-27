// Generic genome operations for byte-array genomes
// Can be extended or replaced for different nucleo/codon representations
// Standard operations that work with any nucleo-based genome structure

use "random"
use "collections"

primitive ByteGenomeOps is GenomeOperations
  """
  Standard genetic operations for byte-array genomes.
  Generic operations that work with any nucleo-based genome without
  specific knowledge of nucleo boundaries or codon structure.
  """
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Standard mutation - changes a small number of bytes.
    Note: This generic mutation doesn't respect nucleo boundaries.
    Domain-specific implementations should override for codon-aware mutations.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 1-3 positions
      let mutations = 1 + (rng.next().usize() % 3)
      for _ in Range[USize](0, mutations) do
        try
          let pos = rng.next().usize() % arr.size()
          arr(pos)? = rng.next().u8()
        end
      end
      arr
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation - changes many positions for escaping local optima.
    Note: This generic mutation may break codon structures.
    Use for exploration when codon preservation is less important.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 20-40% of positions
      let mutation_count = (arr.size() / 5) + (rng.next().usize() % (arr.size() / 5))
      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % arr.size()
          arr(pos)? = rng.next().u8()
        end
      end
      arr
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Two-point crossover for byte arrays.
    Note: This generic crossover doesn't respect nucleo boundaries.
    Domain-specific implementations should align crossover points with nucleos.
    """
    let size = a.size().min(b.size())
    let p1 = rng.next().usize() % size
    let p2 = rng.next().usize() % size
    let start = if p1 < p2 then p1 else p2 end
    let end' = if p1 < p2 then p2 else p1 end
    
    (recover val
      let c1 = Array[U8](size)
      var i: USize = 0
      while i < size do
        try
          if (i >= start) and (i < end') then
            c1.push(b(i)?)
          else
            c1.push(a(i)?)
          end
        end
        i = i + 1
      end
      c1
    end,
    recover val
      let c2 = Array[U8](size)
      var i: USize = 0
      while i < size do
        try
          if (i >= start) and (i < end') then
            c2.push(a(i)?)
          else
            c2.push(b(i)?)
          end
        end
        i = i + 1
      end
      c2
    end)