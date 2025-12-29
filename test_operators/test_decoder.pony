// Test demonstration of BinaryDecoder operator
// Shows how to decode genomes to integers using different strategies

use "../_framework/operators/decoders"
use "collections"

actor Main
  new create(env: Env) =>
    env.out.print("=== Binary Decoder Operator Demo ===")
    env.out.print("")

    // Test genome: [0xFF, 0x00, 0x12, 0x34]
    let genome: Array[U8] val = recover val [as U8: 0xFF; 0x00; 0x12; 0x34] end

    // Little-endian decoding (LSB first)
    let le_value = BinaryDecoder.decode_le(genome)
    env.out.print("Little-endian: " + le_value.string())
    env.out.print("  Binary: 0xFF 0x00 0x12 0x34")
    env.out.print("  Value: " + le_value.string() + " (decimal)")
    env.out.print("")

    // Big-endian decoding (MSB first)
    let be_value = BinaryDecoder.decode_be(genome)
    env.out.print("Big-endian: " + be_value.string())
    env.out.print("  Binary: 0xFF 0x00 0x12 0x34")
    env.out.print("  Value: " + be_value.string() + " (decimal)")
    env.out.print("")

    // Gray code decoding (smoother evolution)
    let gray_value = BinaryDecoder.decode_gray(genome)
    env.out.print("Gray code: " + gray_value.string())
    env.out.print("  Prevents Hamming cliffs in evolution")
    env.out.print("  Value: " + gray_value.string() + " (decimal)")
    env.out.print("")

    // Range decoding (map to continuous values)
    let range_value = BinaryDecoder.decode_range(genome, 0.0, 100.0)
    env.out.print("Range [0.0, 100.0]: " + range_value.string())
    env.out.print("  Useful for continuous optimization")
    env.out.print("")

    // Demonstrate use case: powers of 2
    env.out.print("=== Powers of 2 Use Case ===")

    // Decode genome to get n (0-15)
    let small_genome: Array[U8] val = recover val [as U8: 0x05; 0x00] end
    let n = BinaryDecoder.decode_le(small_genome) % 16

    env.out.print("Genome bytes: [0x05, 0x00]")
    env.out.print("Decoded value: " + BinaryDecoder.decode_le(small_genome).string())
    env.out.print("Modulo 16: " + n.string())
    env.out.print("Computing 2^" + n.string() + " = " + _pow2(n).string())
    env.out.print("")

    // Show how different genomes map to values
    env.out.print("=== Genome Evolution Demo ===")
    _show_genome_sequence(env)

  fun _pow2(n: U64): U64 =>
    if n == 0 then return 1 end
    var result: U64 = 1
    for _ in Range[U64](0, n) do
      result = result * 2
    end
    result

  fun _show_genome_sequence(env: Env) =>
    """Show how adjacent genomes map to values (demonstrates Gray code benefit)"""

    env.out.print("Adjacent genome values (standard binary):")
    for i in Range[U8](0, 8) do
      let genome: Array[U8] val = recover val [as U8: i; 0x00] end
      let value = BinaryDecoder.decode_le(genome)
      env.out.print("  Genome [" + i.string() + "]: " + value.string())
    end
    env.out.print("")

    env.out.print("Adjacent genome values (Gray code):")
    for i in Range[U8](0, 8) do
      let genome: Array[U8] val = recover val [as U8: i; 0x00] end
      let value = BinaryDecoder.decode_gray(genome)
      env.out.print("  Genome [" + i.string() + "]: " + value.string())
    end
    env.out.print("")
    env.out.print("Note: Gray code values change smoothly, better for GA!")
