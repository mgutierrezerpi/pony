// Sentiment analysis problem domain using neural network evolution

use "random"
use "collections"
use "time"
use ".."
use "../_framework"

class SentimentDomain is ProblemDomain
  """
  Problem domain for evolving neural network weights for multilingual sentiment classification.
  Classifies text as positive, negative, or neutral.
  Supports both Spanish and English text.
  """
  let _all_training_data: Array[(String, USize)] val
  let _test_cases: Array[(String, USize)] val
  let _english_lexicon: Map[String, (Bool, Bool)] val
  let _spanish_lexicon: Map[String, (Bool, Bool)] val
  
  new val create(env: Env) =>
    """
    Initialize the domain by loading all training data from NRC lexicon files.
    """
    _all_training_data = DatasetBuilder.load_all_sentiment_samples(env)
    _test_cases = DatasetBuilder.get_test_cases()
    _english_lexicon = FileReader.read_nrc_lexicon(env, "sentiment/data/English-NRC-EmoLex.txt")
    _spanish_lexicon = FileReader.read_nrc_lexicon(env, "sentiment/data/Spanish-NRC-EmoLex.txt")
  
  fun genome_size(): USize => 
    // Input layer: 50 sentiment features + 1 bias
    // Hidden layer: 15 neurons + 1 bias  
    // Output layer: 3 neurons (positive, negative, neutral) + 1 bias
    // Total weights: (50+1)*15 + (15+1)*3 = 765 + 48 = 813
    813
  
  fun random_genome(rng: Rand): Array[U8] val =>
    """
    Generate random neural network weights.
    Each byte represents a weight scaled to [-2.0, 2.0] range.
    """
    recover val
      let arr = Array[U8](genome_size())
      for _ in Range[USize](0, genome_size()) do
        arr.push(rng.next().u8())
      end
      arr
    end
  
  fun evaluate(genome: Array[U8] val): F64 =>
    """
    Evaluate fitness using random subsets from pre-loaded NRC lexicon data.
    Each evaluation gets a different random subset to prevent overfitting.
    """
    // Create a genome-based RNG for deterministic but varied sampling
    var genome_hash: USize = 0
    for b in genome.values() do
      genome_hash = ((genome_hash * 31) + b.usize()) % 1000000
    end
    let rng = Rand(genome_hash.u64(), Time.nanos())
    
    let training_size = _all_training_data.size()
    let subset_size: USize = training_size.min(30)
    
    // Select random subset of training data
    var training_correct: USize = 0
    for i in Range[USize](0, subset_size) do
      let sample_idx = rng.next().usize() % training_size
      try
        let sample = _all_training_data(sample_idx)?
        let features = extract_sentiment_features(sample._1)  // text
        let predictions = forward_pass(genome, features)
        
        // Find the predicted class (highest confidence)
        var predicted_class: USize = 0
        var max_confidence: F64 = 0.0
        for j in Range[USize](0, 3) do
          try
            if predictions(j)? > max_confidence then
              max_confidence = predictions(j)?
              predicted_class = j
            end
          end
        end
        
        // Check if prediction matches ground truth
        if predicted_class == sample._2 then  // sentiment_class
          training_correct = training_correct + 1
        end
      end
    end
    
    // Test on fixed test cases for consistent evaluation
    var test_correct: USize = 0
    for sample in _test_cases.values() do
      let features = extract_sentiment_features(sample._1)  // text
      let predictions = forward_pass(genome, features)
      
      // Find the predicted class (highest confidence)
      var predicted_class: USize = 0
      var max_confidence: F64 = 0.0
      for k in Range[USize](0, 3) do
        try
          if predictions(k)? > max_confidence then
            max_confidence = predictions(k)?
            predicted_class = k
          end
        end
      end
      
      // Check if prediction matches ground truth
      if predicted_class == sample._2 then  // sentiment_class
        test_correct = test_correct + 1
      end
    end
    
    // Combine training subset accuracy (70%) and test accuracy (30%)
    let test_size = _test_cases.size()
    
    if (subset_size > 0) and (test_size > 0) then
      let training_accuracy = training_correct.f64() / subset_size.f64()
      let test_accuracy = test_correct.f64() / test_size.f64()
      (training_accuracy * 0.7) + (test_accuracy * 0.3)
    else
      0.0  // Return 0 if no data available
    end
  
  fun perfect_fitness(): F64 => 0.95  // 95% accuracy is considered perfect
  
  fun display_result(genome: Array[U8] val): String =>
    """
    Test the sentiment classifier on example sentences in Spanish and English.
    """
    let examples = [
      "I love this movie, it's amazing!"
      "Me encanta esta película, es increíble!"
      "This film is terrible and boring."
      "Esta película es terrible y aburrida."
      "The weather is okay today."
      "El clima está bien hoy."
      "I'm so excited about tomorrow!"
      "¡Estoy tan emocionado por mañana!"
    ]
    
    let sentiment_names: Array[String] = ["Positive"; "Negative"; "Neutral"]
    
    var result = "Sentiment predictions:\n"
    for text in examples.values() do
      let features = extract_sentiment_features(text)
      let predictions = forward_pass(genome, features)
      
      // Find highest confidence prediction
      var best_class: USize = 0
      var best_confidence: F64 = 0.0
      for i in Range[USize](0, 3) do
        try
          if predictions(i)? > best_confidence then
            best_confidence = predictions(i)?
            best_class = i
          end
        end
      end
      
      try
        let sentiment = sentiment_names(best_class)?
        result = result + "\"" + text + "\" -> " + sentiment + " (" + (best_confidence * 100).string() + "%)\n"
      end
    end
    result
  
  fun extract_sentiment_features(text: String): Array[F64] val =>
    """
    Extract sentiment-focused features from multilingual text using loaded NRC lexicon.
    Returns 50 features focused on positive/negative/neutral classification.
    """
    recover val
      let features = Array[F64](50)
      let lower_text = text.lower()
      let words_iso = lower_text.split(" ")
      let words = recover val consume words_iso end
      
      // Get sentiment counts from loaded NRC lexicon data
      let sentiment_counts = _count_nrc_sentiment_words(words)
      
      // Features 0-2: Raw sentiment word counts (normalized)
      for idx in Range[USize](0, 3) do
        try
          features.push(sentiment_counts(idx)? / words.size().f64())
        else
          features.push(0.0)
        end
      end
      
      // Features 3-5: Binary indicators (>0 words found)
      for bin_idx in Range[USize](0, 3) do
        try
          features.push(if sentiment_counts(bin_idx)? > 0 then 1.0 else 0.0 end)
        else
          features.push(0.0)
        end
      end
      
      // Features 6-8: Squared counts (emphasizes strong sentiment)
      for sq_idx in Range[USize](0, 3) do
        try
          let count = sentiment_counts(sq_idx)?
          features.push((count * count) / (words.size().f64() * words.size().f64()))
        else
          features.push(0.0)
        end
      end
      
      // Features 9-11: Language-adjusted scores
      let is_spanish = detect_spanish_from_nrc(words)
      for lang_idx in Range[USize](0, 3) do
        try
          let base_score = sentiment_counts(lang_idx)? / words.size().f64()
          features.push(if is_spanish then (base_score * 1.1) else (base_score * 0.9) end)
        else
          features.push(0.0)
        end
      end
      
      // Features 12-20: Text characteristics
      features.push(words.size().f64() / 20.0)  // Text length
      features.push(if text.contains("!") then 1.0 else 0.0 end)  // Exclamation
      features.push(if text.contains("?") then 1.0 else 0.0 end)  // Question  
      features.push(if text.contains("¡") then 1.0 else 0.0 end)  // Spanish exclamation
      features.push(if text.contains("¿") then 1.0 else 0.0 end)  // Spanish question
      features.push(if is_spanish then 1.0 else 0.0 end)  // Language indicator
      features.push(_count_capitals(text) / words.size().f64())  // Capital letters ratio
      features.push(if text.contains("very") or text.contains("muy") then 1.0 else 0.0 end)  // Intensifiers
      features.push(if text.contains("not") or text.contains("no") then 1.0 else 0.0 end)  // Negations
      
      // Features 21-49: Additional contextual and ratio features
      for pad_idx in Range[USize](21, 50) do
        features.push(0.0)  // Zero padding for additional features
      end
      
      features
    end

  fun extract_nrc_features(text: String): Array[F64] val =>
    """
    Extract NRC Emotion Lexicon based features from multilingual text.
    """
    recover val
      let features = Array[F64](100)  // 100 feature dimensions
      let lower_text = text.lower()
      let words_iso = lower_text.split(" ")
      let words = recover val consume words_iso end
      
      // Get emotion counts for each category (simplified to sentiment only)
      let emotion_counts = _count_nrc_sentiment_words(words)
      
      // Features 0-2: Raw sentiment word counts (normalized)
      for idx in Range[USize](0, 3) do
        try
          features.push(emotion_counts(idx)? / words.size().f64())
        else
          features.push(0.0)
        end
      end
      
      // Features 3-5: Binary indicators (>0 words found)
      for binary_idx in Range[USize](0, 3) do
        try
          features.push(if emotion_counts(binary_idx)? > 0 then 1.0 else 0.0 end)
        else
          features.push(0.0)
        end
      end
      
      // Features 6-8: Squared counts (emphasizes strong sentiment)
      for squared_idx in Range[USize](0, 3) do
        try
          let count = emotion_counts(squared_idx)?
          features.push((count * count) / (words.size().f64() * words.size().f64()))
        else
          features.push(0.0)
        end
      end
      
      // Features 9-11: Language detection features
      let is_spanish = detect_spanish_from_nrc(words)
      for lang_idx in Range[USize](0, 3) do
        try
          let base_score = emotion_counts(lang_idx)? / words.size().f64()
          features.push(if is_spanish then (base_score * 1.2) else (base_score * 0.8) end)
        else
          features.push(0.0)
        end
      end
      
      // Features 12-17: Additional contextual features
      // Text statistics
      features.push(words.size().f64() / 20.0)  // Text length
      features.push(if text.contains("!") then 1.0 else 0.0 end)  // Exclamation
      features.push(if text.contains("?") then 1.0 else 0.0 end)  // Question  
      features.push(if text.contains("¡") then 1.0 else 0.0 end)  // Spanish exclamation
      features.push(if text.contains("¿") then 1.0 else 0.0 end)  // Spanish question
      features.push(if is_spanish then 1.0 else 0.0 end)  // Language indicator
      
      // Features 18-99: Zero padding for additional features
      for pad_idx in Range[USize](18, 100) do
        features.push(0.0)  // Zero padding for additional features
      end
      
      features
    end
  
  fun forward_pass(genome: Array[U8] val, features: Array[F64] val): Array[F64] val =>
    """
    Neural network forward pass for sentiment classification.
    Returns 3 outputs: positive, negative, neutral.
    """
    // Convert genome bytes to weights in [-2.0, 2.0] range
    let weights = recover val
      let w = Array[F64](genome.size())
      for b in genome.values() do
        let normalized = (b.f64() - 127.5) / 63.75  // Scale to [-2.0, 2.0]
        w.push(normalized)
      end
      w
    end
    
    // Input to hidden layer (50 inputs + bias -> 15 hidden)
    let hidden = recover val
      let h_array = Array[F64](15)
      for h in Range[USize](0, 15) do
        var sum: F64 = 0.0
        
        // Add weighted inputs
        for feat_idx in Range[USize](0, 50) do
          try
            let weight_idx = (h * 51) + feat_idx  // 51 = 50 features + 1 bias per hidden neuron
            sum = sum + (features(feat_idx)? * weights(weight_idx)?)
          end
        end
        
        // Add bias weight
        try
          let bias_idx = (h * 51) + 50
          sum = sum + weights(bias_idx)?
        end
        
        // Apply sigmoid activation
        h_array.push(_sigmoid(sum))
      end
      h_array
    end
    
    // Hidden to output layer (15 hidden + bias -> 3 outputs)
    recover val
      let outputs = Array[F64](3)
      for o in Range[USize](0, 3) do
        var output_sum: F64 = 0.0
        
        // Add weighted hidden layer outputs
        for hid_idx in Range[USize](0, 15) do
          try
            let weight_idx = 765 + (o * 16) + hid_idx  // Offset past input->hidden weights (50+1)*15 = 765
            output_sum = output_sum + (hidden(hid_idx)? * weights(weight_idx)?)
          end
        end
        
        // Add output bias
        try
          let bias_idx = 765 + (o * 16) + 15
          output_sum = output_sum + weights(bias_idx)?
        end
        
        // Apply sigmoid activation
        outputs.push(_sigmoid(output_sum))
      end
      outputs
    end
  
  fun _count_capitals(text: String): F64 =>
    """
    Count uppercase letters in text.
    """
    var count: F64 = 0.0
    for char in text.values() do
      if (char >= 'A') and (char <= 'Z') then
        count = count + 1.0
      end
    end
    count
  
  fun _count_nrc_sentiment_words(words: Array[String] val): Array[F64] val =>
    """
    Count sentiment words using loaded NRC lexicon: [positive, negative, neutral]
    """
    recover val
      let counts = Array[F64](3)  // [positive, negative, neutral]
      for _ in Range[USize](0, 3) do
        counts.push(0.0)
      end
      
      // Check each word against loaded NRC lexicon
      for word in words.values() do
        let clean_word = word.clone()
        clean_word.strip(" .,!?¡¿\"")
        let lower_word = recover val clean_word.lower() end
        
        // Check English lexicon first
        try
          let sentiment = _english_lexicon(lower_word)?
          (let is_positive, let is_negative) = sentiment
          if is_positive and not is_negative then
            counts(0)? = counts(0)? + 1.0  // Positive
          elseif is_negative and not is_positive then
            counts(1)? = counts(1)? + 1.0  // Negative
          elseif not is_positive and not is_negative then
            counts(2)? = counts(2)? + 1.0  // Neutral
          end
          // Skip ambiguous words (both positive and negative)
        end
        
        // Check Spanish lexicon if not found in English
        try
          let sentiment = _spanish_lexicon(lower_word)?
          (let is_positive, let is_negative) = sentiment
          if is_positive and not is_negative then
            counts(0)? = counts(0)? + 1.0  // Positive
          elseif is_negative and not is_positive then
            counts(1)? = counts(1)? + 1.0  // Negative
          elseif not is_positive and not is_negative then
            counts(2)? = counts(2)? + 1.0  // Neutral
          end
          // Skip ambiguous words (both positive and negative)
        end
      end
      
      counts
    end
  
  fun _sigmoid(x: F64): F64 =>
    """
    Sigmoid activation function.
    """
    1.0 / (1.0 + _exp(-x))
  
  fun _exp(x: F64): F64 =>
    """
    Simple exponential approximation (since Pony might not have math library).
    """
    if x < -10.0 then
      0.0001
    elseif x > 10.0 then
      10000.0
    else
      // Taylor series approximation for e^x
      var result: F64 = 1.0
      var term: F64 = x
      var i: USize = 1
      while (i < 10) and (term.abs() > 0.001) do
        result = result + term
        i = i + 1
        term = (term * x) / i.f64()
      end
      result.max(0.0001).min(10000.0)  // Clamp to reasonable range
    end
  
  fun _get_lexicon_scores(features: Array[F64] val): Array[F64] val =>
    """
    Get direct emotion scores based on lexicon word counts from features.
    Features 0-9 contain normalized emotion word counts.
    Start at 0% and only assign scores when actual matches are found.
    """
    recover val
      let scores = Array[F64](10)
      for i in Range[USize](0, 10) do
        try
          // Features 0-9 are normalized word counts for each emotion
          let raw_count = features(i)?
          
          // Only assign a score if we actually found matching words
          let scaled_score: F64 = if raw_count > 0.0 then
            // Scale raw count to meaningful probability
            // Multiple words of same emotion = higher confidence
            let base_confidence: F64 = 0.6  // 60% confidence for single word match
            let word_multiplier: F64 = raw_count * 4.0  // Boost for multiple words
            (base_confidence + word_multiplier).min(0.95)  // Cap at 95%
          else
            0.0  // No matches = 0%
          end
          
          scores.push(scaled_score)
        else
          scores.push(0.0)
        end
      end
      scores
    end
  
  
  fun detect_spanish_from_nrc(words: Array[String] val): Bool =>
    """
    Spanish language detection based on which lexicon contains more words.
    """
    var spanish_found: USize = 0
    var english_found: USize = 0
    
    for word in words.values() do
      let clean_word = word.clone()
      clean_word.strip(" .,!?¡¿\"")
      let lower_word = recover val clean_word.lower() end
      
      // Check if word exists in English lexicon
      if _english_lexicon.contains(lower_word) then
        english_found = english_found + 1
      end
      
      // Check if word exists in Spanish lexicon
      if _spanish_lexicon.contains(lower_word) then
        spanish_found = spanish_found + 1
      end
    end
    
    // If more words found in Spanish lexicon, consider it Spanish
    spanish_found > english_found


primitive SentimentGenomeOps is GenomeOperations
  """
  Neural network specific genetic operations.
  """
  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Mutate neural network weights with small random changes.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 1-5% of weights
      let mutation_count = 1 + (rng.next().usize() % (genome.size() / 20))
      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % arr.size()
          let current = arr(pos)?
          // Small random change (+/- up to 20)
          let delta = (rng.next().i32() % 41) - 20
          let new_val = (current.i32() + delta).max(0).min(255)
          arr(pos)? = new_val.u8()
        end
      end
      arr
    end
  
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val =>
    """
    Heavy mutation for escaping local optima.
    """
    recover val
      let arr = Array[U8](genome.size())
      for v in genome.values() do
        arr.push(v)
      end
      
      // Mutate 10-30% of weights
      let mutation_count = (genome.size() / 10) + (rng.next().usize() % (genome.size() / 5))
      for _ in Range[USize](0, mutation_count) do
        try
          let pos = rng.next().usize() % arr.size()
          arr(pos)? = rng.next().u8()  // Completely random new weight
        end
      end
      arr
    end
  
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) =>
    """
    Layer-aware crossover - swap entire layers between networks.
    """
    let size = a.size().min(b.size())
    
    // Choose crossover points at layer boundaries
    // Layer 1: 0 to 764 (input to hidden weights: 50*15 + 15 biases = 765)
    // Layer 2: 765 to 812 (hidden to output weights: 15*3 + 3 biases = 48)
    let crossover_points: Array[USize] val = recover val [765] end  // Crossover between layers
    
    (recover val
      let c1 = Array[U8](size)
      var use_a = true
      var point_idx: USize = 0
      
      for i in Range[USize](0, size) do
        // Switch parent when we hit a crossover point
        try
          if (point_idx < crossover_points.size()) and (i >= crossover_points(point_idx)?) then
            use_a = not use_a
            point_idx = point_idx + 1
          end
        end
        
        try
          if use_a then
            c1.push(a(i)?)
          else
            c1.push(b(i)?)
          end
        end
      end
      c1
    end,
    recover val
      let c2 = Array[U8](size)
      var use_a = false  // Start with opposite parent
      var point_idx: USize = 0
      
      for i in Range[USize](0, size) do
        try
          if (point_idx < crossover_points.size()) and (i >= crossover_points(point_idx)?) then
            use_a = not use_a
            point_idx = point_idx + 1
          end
        end
        
        try
          if use_a then
            c2.push(a(i)?)
          else
            c2.push(b(i)?)
          end
        end
      end
      c2
    end)

primitive SentimentConfig is GAConfiguration
  """
  Configuration for sentiment analysis GA.
  """
  fun population_size(): USize => 30
  fun tournament_size(): USize => 5
  fun worker_count(): USize => 11
  fun mutation_rate(): F64 => 0.1
  fun crossover_rate(): F64 => 0.8
  fun elitism_count(): USize => 3