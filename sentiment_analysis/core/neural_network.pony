// Neural network for sentiment classification
// 50 input features -> 15 hidden neurons -> 3 output classes

use "collections"

primitive NeuralNetwork
  """
  Feed-forward neural network for sentiment classification.

  Architecture:
  - Input: 50 features
  - Hidden: 15 neurons (sigmoid activation)
  - Output: 2 classes (positive, negative) (sigmoid activation)

  Total weights: (50+1)*15 + (15+1)*2 = 765 + 32 = 797
  """

  fun genome_size(): USize => 797

  fun forward_pass(genome: Array[U8] val, features: Array[F64] val): Array[F64] val =>
    """
    Perform forward propagation through the network.
    Returns array of 2 outputs (positive, negative).
    """
    // Convert genome bytes to weights in [-2.0, 2.0] range
    let weights = _bytes_to_weights(genome)

    // Input to hidden layer (50 inputs + 1 bias -> 15 hidden)
    let hidden = _compute_hidden_layer(features, weights)

    // Hidden to output layer (15 hidden + 1 bias -> 3 outputs)
    _compute_output_layer(hidden, weights)

  fun _bytes_to_weights(genome: Array[U8] val): Array[F64] val =>
    """
    Convert genome bytes to normalized weights.
    Maps [0, 255] -> [-2.0, 2.0]
    """
    recover val
      let weights = Array[F64](genome.size())
      for byte in genome.values() do
        // Scale from [0, 255] to [-2.0, 2.0]
        let normalized = (byte.f64() - 127.5) / 63.75
        weights.push(normalized)
      end
      weights
    end

  fun _compute_hidden_layer(features: Array[F64] val, weights: Array[F64] val): Array[F64] val =>
    """
    Compute hidden layer activations.
    """
    recover val
      let hidden = Array[F64](15)

      for h in Range[USize](0, 15) do
        var sum: F64 = 0.0

        // Add weighted inputs (50 features)
        for f in Range[USize](0, 50) do
          try
            let weight_idx = (h * 51) + f  // 51 = 50 features + 1 bias
            sum = sum + (features(f)? * weights(weight_idx)?)
          end
        end

        // Add bias weight
        try
          let bias_idx = (h * 51) + 50
          sum = sum + weights(bias_idx)?
        end

        // Apply sigmoid activation
        hidden.push(_sigmoid(sum))
      end

      hidden
    end

  fun _compute_output_layer(hidden: Array[F64] val, weights: Array[F64] val): Array[F64] val =>
    """
    Compute output layer activations for 2 classes.
    """
    recover val
      let outputs = Array[F64](2)

      for o in Range[USize](0, 2) do
        var sum: F64 = 0.0

        // Add weighted hidden layer outputs (15 neurons)
        for h in Range[USize](0, 15) do
          try
            // Offset: (50+1)*15 = 765 past input->hidden weights
            let weight_idx = 765 + (o * 16) + h  // 16 = 15 hidden + 1 bias
            sum = sum + (hidden(h)? * weights(weight_idx)?)
          end
        end

        // Add bias weight
        try
          let bias_idx = 765 + (o * 16) + 15
          sum = sum + weights(bias_idx)?
        end

        // Apply sigmoid activation
        outputs.push(_sigmoid(sum))
      end

      outputs
    end

  fun _sigmoid(x: F64): F64 =>
    """
    Sigmoid activation function: 1 / (1 + e^(-x))
    """
    1.0 / (1.0 + _exp(-x))

  fun _exp(x: F64): F64 =>
    """
    Exponential function approximation using Taylor series.
    """
    if x < -10.0 then
      return 0.0001
    elseif x > 10.0 then
      return 10000.0
    end

    // Taylor series: e^x = 1 + x + x^2/2! + x^3/3! + ...
    var result: F64 = 1.0
    var term: F64 = x
    var i: USize = 1

    while (i < 10) and (term.abs() > 0.001) do
      result = result + term
      i = i + 1
      term = (term * x) / i.f64()
    end

    result.max(0.0001).min(10000.0)

  fun classify(outputs: Array[F64] val): USize =>
    """
    Convert network outputs to class prediction.
    Returns index of highest output (0=positive, 1=negative).
    """
    var best_class: USize = 0
    var best_score: F64 = 0.0

    for i in Range[USize](0, 2) do
      try
        let score = outputs(i)?
        if score > best_score then
          best_score = score
          best_class = i
        end
      end
    end

    best_class
