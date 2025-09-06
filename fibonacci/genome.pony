use "random"
use "collections"

// Genome represents the evolvable program (raw bytes)
// This module handles genome creation, mutation, and crossover

primitive GAConf
  fun pop(): USize => 250
  fun gens(): USize => 400
  fun workers(): USize => 8
  fun tournament_k(): USize => 5
  fun mutation_rate(): F64 => 0.06       // prob per byte to mutate
  fun mutation_sigma(): U8 => 8          // random tweak scale
  fun elite(): USize => 2

primitive GAOps
  fun random_genome(rng: Rand): Array[U8] val =>
    let n = VMConfig.genome_len().usize()
    recover val
      let buf = Array[U8](n)
      var i: USize = 0
      while i < n do
        buf.push(rng.next().u8())
        i = i + 1
      end
      buf
    end

  fun mutate(rng: Rand, g: Array[U8] box): Array[U8] val =>
    let n = g.size()
    let bytes = recover iso Array[U8 val](n) end
    for i in Range[USize](0, n) do
      var b: U8 = try g(i)? else 0 end
      // With some probability, tweak this byte slightly (or random flip)
      let p: F64 = (rng.next().f64() / U64.max_value().f64())
      if p < GAConf.mutation_rate() then
        let delta: U8 = (rng.next().u8() % GAConf.mutation_sigma())
        if (rng.next().u8() and 1) == 1 then
          b = b + delta
        else
          b = b - delta
        end
      end
      bytes.push(b)
    end
    consume bytes

  fun crossover(rng: Rand, a: Array[U8] box, b: Array[U8] box): (Array[U8] val, Array[U8] val) =>
    let n = a.size()
    if n == 0 then
      (recover val Array[U8] end, recover val Array[U8] end)
    else
      let cut: USize = (rng.next().usize() % n)
      let c1 = recover iso Array[U8 val](n) end
      let c2 = recover iso Array[U8 val](n) end
      for i in Range[USize](0, n) do
        if i < cut then
          c1.push(try a(i)? else 0 end)
          c2.push(try b(i)? else 0 end)
        else
          c1.push(try b(i)? else 0 end)
          c2.push(try a(i)? else 0 end)
        end
      end
      (consume c1, consume c2)
    end