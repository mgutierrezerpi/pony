// Reusable binary decoder for converting genomes to integer values
// Useful for problems like powers of two, numeric optimization, etc.

primitive BinaryDecoder
  """
  Decodes a byte array genome into an unsigned integer.

  Supports multiple decoding strategies:
  - Little-endian (LSB first)
  - Big-endian (MSB first)
  - Gray code (prevents large jumps between adjacent values)

  Usage:
    let genome: Array[U8] val = [0xFF; 0x00; 0x12; 0x34]
    let value = BinaryDecoder.decode_le(genome)  // Little-endian
    let value2 = BinaryDecoder.decode_be(genome) // Big-endian
    let value3 = BinaryDecoder.decode_gray(genome) // Gray code
  """

  fun decode_le(genome: Array[U8] val): U64 =>
    """
    Decode genome as little-endian unsigned integer.
    First byte is least significant.
    """
    var result: U64 = 0
    var shift: U64 = 0

    for byte in genome.values() do
      result = result or (byte.u64() << shift)
      shift = shift + 8
      if shift >= 64 then break end
    end

    result

  fun decode_be(genome: Array[U8] val): U64 =>
    """
    Decode genome as big-endian unsigned integer.
    First byte is most significant.
    """
    var result: U64 = 0

    for byte in genome.values() do
      result = (result << 8) or byte.u64()
    end

    result

  fun decode_gray(genome: Array[U8] val): U64 =>
    """
    Decode genome using Gray code encoding.
    Gray code ensures adjacent values differ by only 1 bit,
    making evolution smoother (no Hamming cliffs).
    """
    let binary = decode_be(genome)
    _gray_to_binary(binary)

  fun decode_range(genome: Array[U8] val, min: F64, max: F64): F64 =>
    """
    Decode genome to a real value in [min, max] range.
    Useful for continuous optimization problems.
    """
    let int_val = decode_le(genome)
    let max_val = _max_value(genome.size())
    let ratio = int_val.f64() / max_val.f64()

    min + (ratio * (max - min))

  fun _gray_to_binary(gray: U64): U64 =>
    """Convert Gray code to binary."""
    var binary = gray
    var shift: U64 = 1

    while shift < 64 do
      binary = binary xor (gray >> shift)
      shift = shift << 1
    end

    binary

  fun _max_value(byte_count: USize): U64 =>
    """Calculate maximum value for N bytes."""
    if byte_count >= 8 then
      U64.max_value()
    else
      (1 << (byte_count.u64() * 8)) - 1
    end
