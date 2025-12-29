// Sentiment analysis problem domain using modern framework
// Evolves neural network weights for multilingual sentiment classification

use "random"
use "collections"
use "../../_framework"

primitive SentimentDomain is ProblemDomain
  """
  Problem domain for evolving neural network weights for sentiment analysis.

  Classifies text as:
  - Class 0: Positive
  - Class 1: Negative
  - Class 2: Neutral

  Supports English and Spanish text using NRC Emotion Lexicon.
  """

  fun genome_size(): USize => NeuralNetwork.genome_size()

  fun random_genome(rng: Rand): Array[U8] val =>
    """
    Generate random neural network weights.
    Each byte represents a weight that will be scaled to [-2.0, 2.0].
    """
    recover val
      let genome = Array[U8](genome_size())
      for _ in Range[USize](0, genome_size()) do
        genome.push(rng.next().u8())
      end
      genome
    end

  fun evaluate(genome: Array[U8] val): F64 =>
    """
    Evaluate fitness on test cases.
    Returns accuracy (0.0 to 1.0).
    """
    // Note: We'll need to load lexicons in main and pass them somehow
    // For now, this is a simplified version
    // In practice, the domain would need lexicons passed at creation
    let test_cases = TestDataset.get_test_cases()

    var correct: USize = 0

    // Dummy lexicons for compilation (will be replaced with real ones)
    let empty_lex: Map[String, (Bool, Bool)] val = recover val Map[String, (Bool, Bool)] end

    for sample in test_cases.values() do
      (let text, let expected_class) = sample

      // Extract features
      let features = FeatureExtractor.extract(text, empty_lex, empty_lex)

      // Forward pass through network
      let outputs = NeuralNetwork.forward_pass(genome, features)

      // Get predicted class
      let predicted_class = NeuralNetwork.classify(outputs)

      // Check if correct
      if predicted_class == expected_class then
        correct = correct + 1
      end
    end

    // Return accuracy
    correct.f64() / test_cases.size().f64()

  fun perfect_fitness(): F64 => 0.95  // 95% accuracy is considered excellent

  fun display_result(genome: Array[U8] val): String =>
    """
    Show example predictions on test sentences.
    """
    let examples = [
      "I love this amazing movie"
      "This is terrible and awful"
      "The table is brown"
      "Me encanta esta película"
      "Esto es horrible"
      "La mesa es marrón"
    ]

    let class_names: Array[String] val = ["Positive"; "Negative"; "Neutral"]
    let empty_lex: Map[String, (Bool, Bool)] val = recover val Map[String, (Bool, Bool)] end

    var result = "Sentiment predictions:\n"

    for text in examples.values() do
      let features = FeatureExtractor.extract(text, empty_lex, empty_lex)
      let outputs = NeuralNetwork.forward_pass(genome, features)
      let predicted = NeuralNetwork.classify(outputs)

      try
        let class_name = class_names(predicted)?
        var confidence: F64 = 0.0
        try confidence = outputs(predicted)? end

        result = result + "\"" + text + "\" -> " + class_name
        result = result + " (" + (confidence * 100).string() + "%)\n"
      end
    end

    result

class SentimentDomainWithLexicons is ProblemDomain
  """
  Sentiment domain that holds lexicon data for feature extraction.
  Uses IMDB movie reviews dataset for training (50,000 real reviews!).
  """
  let _english_lexicon: Map[String, (Bool, Bool)] val
  let _spanish_lexicon: Map[String, (Bool, Bool)] val
  let _training_data: Array[(String, USize)] val
  let _test_cases: Array[(String, USize)] val

  new val create(
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val,
    training_data: Array[(String, USize)] val) =>
    """
    Create domain with pre-loaded lexicons and training data.
    """
    _english_lexicon = english_lex
    _spanish_lexicon = spanish_lex
    _training_data = training_data
    _test_cases = TestDataset.get_test_cases()

  fun genome_size(): USize => WeightedClassifier.genome_size()

  fun random_genome(rng: Rand): Array[U8] val =>
    """
    Generate feature weights with smart initialization.

    Feature 0 (positive word count) gets high weight for positive contribution.
    Feature 1 (negative word count) gets low weight (contributes to negative).
    All other features start random and evolve naturally.
    """
    recover val
      let genome = Array[U8](genome_size())
      for i in Range[USize](0, genome_size()) do
        let weight: U8 = if i == 0 then
          // Feature 0 = positive_count: bias towards high (favors positive class)
          // Range: 150-255 (average ~200, which maps to weight ~0.78)
          150 + (rng.next().u8() % 106)
        elseif i == 1 then
          // Feature 1 = negative_count: bias towards low (contributes to negative class)
          // Range: 0-105 (average ~52, which maps to weight ~0.20)
          rng.next().u8() % 106
        else
          // All other features: completely random (will evolve naturally)
          rng.next().u8()
        end
        genome.push(weight)
      end
      genome
    end

  fun evaluate(genome: Array[U8] val): F64 =>
    """
    Evaluate fitness using weighted classifier.
    Simple accuracy-based fitness - no diversity penalty needed!
    The weighted voting structure naturally prevents degenerate solutions.
    """
    // Create genome-based RNG for consistent but varied sampling
    var genome_hash: USize = 0
    for b in genome.values() do
      genome_hash = ((genome_hash * 31) + b.usize()) % 1000000
    end
    let rng = Rand(genome_hash.u64())

    // Sample from training data
    let sample_size = _training_data.size().min(200)
    var training_correct: USize = 0

    for _ in Range[USize](0, sample_size) do
      try
        let idx = rng.next().usize() % _training_data.size()
        (let text, let expected_class) = _training_data(idx)?

        let features = FeatureExtractor.extract(text, _english_lexicon, _spanish_lexicon)
        let predicted = WeightedClassifier.classify(genome, features)

        if predicted == expected_class then
          training_correct = training_correct + 1
        end
      end
    end

    // Return simple accuracy - let evolution figure out the best weights!
    training_correct.f64() / sample_size.f64()

  fun perfect_fitness(): F64 => 0.95

  fun display_result(genome: Array[U8] val): String =>
    """Show example predictions using weighted classifier."""
    let examples = [
      "I love this wonderful movie"
      "This is terrible and awful"
      "The table is brown"
      "Me encanta esta película"
      "Esto es horrible"
      "La mesa es marrón"
    ]

    let class_names: Array[String] val = ["Positive"; "Negative"]

    var result = "Sentiment predictions:\n"
    result = result + "Training data size: " + _training_data.size().string() + " samples\n\n"

    for text in examples.values() do
      let features = FeatureExtractor.extract(text, _english_lexicon, _spanish_lexicon)
      let predicted = WeightedClassifier.classify(genome, features)
      (let pos_score, let neg_score) = WeightedClassifier.get_scores(genome, features)

      try
        let class_name = class_names(predicted)?
        let total_score = pos_score + neg_score
        let confidence = if total_score > 0.0 then
          if predicted == 0 then
            (pos_score / total_score) * 100.0
          else
            (neg_score / total_score) * 100.0
          end
        else
          50.0
        end

        result = result + "\"" + text + "\" -> " + class_name
        result = result + " (" + confidence.string() + "%)\n"
      end
    end

    result

primitive SentimentGenomeOperations is GenomeOperations
  """
  Genetic operations for neural network genomes.
  """

  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Light mutation: modify 1-5% of weights with small changes.
    """
    recover val
      let mutated = Array[U8](genome.size())
      for byte in genome.values() do
        mutated.push(byte)
      end

      // Mutate 1-5% of weights
      let mutation_count = 1 + (rng.next().usize() % (genome.size() / 20))

      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % mutated.size()
          let current = mutated(pos)?
          // Small change: +/- up to 20
          let delta = (rng.next().i32() % 41) - 20
          let new_val = (current.i32() + delta).max(0).min(255)
          mutated(pos)? = new_val.u8()
        end
      end

      mutated
    end

  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation: randomize 10-30% of weights completely.
    """
    recover val
      let mutated = Array[U8](genome.size())
      for byte in genome.values() do
        mutated.push(byte)
      end

      // Mutate 10-30% of weights
      let mutation_count = (genome.size() / 10) + (rng.next().usize() % (genome.size() / 5))

      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % mutated.size()
          mutated(pos)? = rng.next().u8()  // Completely random
        end
      end

      mutated
    end

  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Layer-aware crossover: swap at neural network layer boundaries.

    Boundaries:
    - 0-764: Input->Hidden weights (50*15 + 15 biases)
    - 765-812: Hidden->Output weights (15*3 + 3 biases)
    """
    let size = a.size().min(b.size())
    let layer_boundary: USize = 765  // Between hidden and output layers

    (recover val
      let child1 = Array[U8](size)
      for i in Range[USize](0, size) do
        try
          if i < layer_boundary then
            child1.push(a(i)?)
          else
            child1.push(b(i)?)
          end
        end
      end
      child1
    end,
    recover val
      let child2 = Array[U8](size)
      for i in Range[USize](0, size) do
        try
          if i < layer_boundary then
            child2.push(b(i)?)
          else
            child2.push(a(i)?)
          end
        end
      end
      child2
    end)

primitive SentimentEvolutionConfig is GAConfiguration
  """
  Configuration parameters for sentiment analysis evolution.
  """
  fun population_size(): USize => 50       // Larger population for better exploration
  fun tournament_size(): USize => 7        // Stronger selection pressure
  fun worker_count(): USize => 8           // Parallel fitness evaluation
  fun mutation_rate(): F64 => 0.1          // 10% mutation rate
  fun crossover_rate(): F64 => 0.8         // 80% crossover rate
  fun elitism_count(): USize => 3          // Preserve top 3 genomes
