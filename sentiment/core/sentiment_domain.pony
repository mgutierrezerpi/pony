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
  
  new val create(env: Env) =>
    """
    Initialize the domain by loading all training data from NRC lexicon files.
    """
    _all_training_data = DatasetBuilder.load_all_sentiment_samples(env)
    _test_cases = DatasetBuilder.get_test_cases()
  
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
      for i in Range[USize](0, 3) do
        try
          if predictions(i)? > max_confidence then
            max_confidence = predictions(i)?
            predicted_class = i
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
    Extract sentiment-focused features from multilingual text.
    Returns 50 features focused on positive/negative/neutral classification.
    """
    recover val
      let features = Array[F64](50)
      let lower_text = text.lower()
      let words_iso = lower_text.split(" ")
      let words = recover val consume words_iso end
      
      // Get basic sentiment counts
      let sentiment_counts = _count_sentiment_words(words)
      
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
      let is_spanish = detect_spanish(words)
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
      
      // Get emotion counts for each category
      let emotion_counts = _count_emotion_words(words)
      
      // Features 0-9: Raw emotion word counts (normalized)
      for idx in Range[USize](0, 10) do
        try
          features.push(emotion_counts(idx)? / words.size().f64())
        else
          features.push(0.0)
        end
      end
      
      // Features 10-19: Binary indicators (>0 words found)
      for binary_idx in Range[USize](0, 10) do
        try
          features.push(if emotion_counts(binary_idx)? > 0 then 1.0 else 0.0 end)
        else
          features.push(0.0)
        end
      end
      
      // Features 20-29: Squared counts (emphasizes strong emotions)
      for squared_idx in Range[USize](0, 10) do
        try
          let count = emotion_counts(squared_idx)?
          features.push((count * count) / (words.size().f64() * words.size().f64()))
        else
          features.push(0.0)
        end
      end
      
      // Features 30-39: Language detection features
      let is_spanish = detect_spanish(words)
      for lang_idx in Range[USize](0, 10) do
        try
          let base_score = emotion_counts(lang_idx)? / words.size().f64()
          features.push(if is_spanish then (base_score * 1.2) else (base_score * 0.8) end)
        else
          features.push(0.0)
        end
      end
      
      // Features 40-99: Additional contextual features
      // Text statistics
      features.push(words.size().f64() / 20.0)  // Text length
      features.push(if text.contains("!") then 1.0 else 0.0 end)  // Exclamation
      features.push(if text.contains("?") then 1.0 else 0.0 end)  // Question  
      features.push(if text.contains("¡") then 1.0 else 0.0 end)  // Spanish exclamation
      features.push(if text.contains("¿") then 1.0 else 0.0 end)  // Spanish question
      features.push(if is_spanish then 1.0 else 0.0 end)  // Language indicator
      
      // Emotion combination features (features 46-99)
      for pad_idx in Range[USize](46, 100) do
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
  
  fun _count_sentiment_words(words: Array[String] val): Array[F64] val =>
    """
    Count sentiment words: [positive, negative, neutral_indicators]
    """
    recover val
      let counts = Array[F64](3)  // [positive, negative, neutral]
      for _ in Range[USize](0, 3) do
        counts.push(0.0)
      end
      
      // Check each word against sentiment categories
      for word in words.values() do
        let clean_word = word.clone()
        clean_word.strip(" .,!?¡¿\"")
        let lower_word = clean_word.lower()
        
        // Check positive words
        let positive_words = NRCLexicon.positive_words()
        for pos_word in positive_words.values() do
          if lower_word == pos_word then
            try counts(0)? = counts(0)? + 1.0 end
            break
          end
        end
        
        // Check negative words  
        let negative_words = NRCLexicon.negative_words()
        for neg_word in negative_words.values() do
          if lower_word == neg_word then
            try counts(1)? = counts(1)? + 1.0 end
            break
          end
        end
        
        // Neutral indicators (common neutral words)
        let neutral_words: Array[String] val = recover val ["the"; "is"; "was"; "are"; "were"; "have"; "has"; "had"; "do"; "does"; "did"; "will"; "would"; "could"; "should"; "may"; "might"; "can"; "today"; "yesterday"; "tomorrow"; "here"; "there"; "this"; "that"; "these"; "those"; "okay"; "fine"; "normal"; "regular"; "usual"; "typical"; "standard"] end
        for neu_word in neutral_words.values() do
          if lower_word == neu_word then
            try counts(2)? = counts(2)? + 1.0 end
            break
          end
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
  
  fun _count_emotion_words(words: Array[String] val): Array[F64] val =>
    """
    Count emotion words based on NRC Emotion Lexicon.
    Returns counts for: [anger, anticipation, disgust, fear, joy, sadness, surprise, trust, positive, negative]
    """
    recover val
      let counts = Array[F64](10)  // Initialize with zeros
      for _ in Range[USize](0, 10) do
        counts.push(0.0)
      end
      
      // Check each word against all emotion categories
      for word in words.values() do
        let clean_word = word.clone()
        clean_word.strip(" .,!?¡¿\"")
        let lower_word = clean_word.lower()
        
        // Check against each emotion's word list
        for emotion_idx in Range[USize](0, 10) do
          let emotion_words = NRCLexicon.get_emotion_words(emotion_idx)
          for emotion_word in emotion_words.values() do
            if lower_word == emotion_word then
              try counts(emotion_idx)? = counts(emotion_idx)? + 1.0 end
              break // Found match for this emotion, move to next
            end
          end
        end
      end
      
      counts
    end
  
  fun detect_spanish(words: Array[String] val): Bool =>
    """
    Simple Spanish language detection based on common words and patterns.
    """
    let spanish_indicators: Array[String] = ["el"; "la"; "de"; "que"; "y"; "es"; "en"; "un"; "una"; "con"; "no"; "te"; "lo"; "le"; "da"; "su"; "por"; "son"; "como"; "pero"; "me"; "se"; "si"; "o"; "ya"; "muy"; "mi"; "más"; "este"; "esta"; "siento"; "estoy"; "tengo"; "soy"; "película"; "increíble"]
    
    var spanish_count: USize = 0
    for word in words.values() do
      for indicator in spanish_indicators.values() do
        if word == indicator then  // Exact match only
          spanish_count = spanish_count + 1
          break
        end
      end
    end
    
    // If more than 20% of words are Spanish indicators, consider it Spanish
    spanish_count.f64() > (words.size().f64() * 0.2)

// Training data structure for sentiment classification
class SentimentSample
  let text: String
  let sentiment_class: USize  // 0 = positive, 1 = negative, 2 = neutral
  
  new create(t: String, s: USize) =>
    text = t
    sentiment_class = s

primitive SentimentData
  """
  Static training data for sentiment classification.
  Uses a curated subset from NRC lexicon for fast evaluation.
  """
  
  fun get_training_samples(): Array[SentimentSample] val =>
    """
    Get a fixed set of training samples for neural network evaluation.
    Each generation uses a random subset from this data.
    """
    recover val
      let data = Array[SentimentSample](100)
      
      // Positive samples from NRC lexicon
      data.push(SentimentSample("love", 0))
      data.push(SentimentSample("happy", 0))
      data.push(SentimentSample("joy", 0))
      data.push(SentimentSample("excellent", 0))
      data.push(SentimentSample("wonderful", 0))
      data.push(SentimentSample("amazing", 0))
      data.push(SentimentSample("perfect", 0))
      data.push(SentimentSample("beautiful", 0))
      data.push(SentimentSample("fantastic", 0))
      data.push(SentimentSample("great", 0))
      data.push(SentimentSample("good", 0))
      data.push(SentimentSample("brilliant", 0))
      data.push(SentimentSample("outstanding", 0))
      data.push(SentimentSample("superb", 0))
      data.push(SentimentSample("pleased", 0))
      data.push(SentimentSample("delighted", 0))
      data.push(SentimentSample("cheerful", 0))
      data.push(SentimentSample("elated", 0))
      data.push(SentimentSample("ecstatic", 0))
      data.push(SentimentSample("blissful", 0))
      // Spanish positive
      data.push(SentimentSample("amor", 0))
      data.push(SentimentSample("feliz", 0))
      data.push(SentimentSample("alegría", 0))
      data.push(SentimentSample("excelente", 0))
      data.push(SentimentSample("maravilloso", 0))
      data.push(SentimentSample("increíble", 0))
      data.push(SentimentSample("perfecto", 0))
      data.push(SentimentSample("hermoso", 0))
      data.push(SentimentSample("fantástico", 0))
      data.push(SentimentSample("bueno", 0))
      
      // Negative samples from NRC lexicon
      data.push(SentimentSample("hate", 1))
      data.push(SentimentSample("sad", 1))
      data.push(SentimentSample("angry", 1))
      data.push(SentimentSample("terrible", 1))
      data.push(SentimentSample("awful", 1))
      data.push(SentimentSample("horrible", 1))
      data.push(SentimentSample("disgusting", 1))
      data.push(SentimentSample("worst", 1))
      data.push(SentimentSample("bad", 1))
      data.push(SentimentSample("evil", 1))
      data.push(SentimentSample("cruel", 1))
      data.push(SentimentSample("nasty", 1))
      data.push(SentimentSample("vile", 1))
      data.push(SentimentSample("wicked", 1))
      data.push(SentimentSample("depressed", 1))
      data.push(SentimentSample("miserable", 1))
      data.push(SentimentSample("furious", 1))
      data.push(SentimentSample("enraged", 1))
      data.push(SentimentSample("livid", 1))
      data.push(SentimentSample("outraged", 1))
      // Spanish negative
      data.push(SentimentSample("odio", 1))
      data.push(SentimentSample("triste", 1))
      data.push(SentimentSample("enojado", 1))
      data.push(SentimentSample("terrible", 1))
      data.push(SentimentSample("horrible", 1))
      data.push(SentimentSample("malo", 1))
      data.push(SentimentSample("pésimo", 1))
      data.push(SentimentSample("furioso", 1))
      data.push(SentimentSample("deprimido", 1))
      data.push(SentimentSample("molesto", 1))
      
      // Neutral samples
      data.push(SentimentSample("table", 2))
      data.push(SentimentSample("chair", 2))
      data.push(SentimentSample("book", 2))
      data.push(SentimentSample("car", 2))
      data.push(SentimentSample("house", 2))
      data.push(SentimentSample("street", 2))
      data.push(SentimentSample("city", 2))
      data.push(SentimentSample("country", 2))
      data.push(SentimentSample("today", 2))
      data.push(SentimentSample("yesterday", 2))
      data.push(SentimentSample("tomorrow", 2))
      data.push(SentimentSample("regular", 2))
      data.push(SentimentSample("normal", 2))
      data.push(SentimentSample("typical", 2))
      data.push(SentimentSample("standard", 2))
      data.push(SentimentSample("usual", 2))
      data.push(SentimentSample("common", 2))
      data.push(SentimentSample("average", 2))
      data.push(SentimentSample("ordinary", 2))
      data.push(SentimentSample("plain", 2))
      // Spanish neutral
      data.push(SentimentSample("mesa", 2))
      data.push(SentimentSample("silla", 2))
      data.push(SentimentSample("libro", 2))
      data.push(SentimentSample("casa", 2))
      data.push(SentimentSample("calle", 2))
      data.push(SentimentSample("ciudad", 2))
      data.push(SentimentSample("hoy", 2))
      data.push(SentimentSample("ayer", 2))
      data.push(SentimentSample("mañana", 2))
      data.push(SentimentSample("normal", 2))
      
      data
    end
  
  fun get_test_cases(): Array[SentimentSample] val =>
    """
    Fixed test cases for consistent evaluation across generations.
    """
    recover val
      let test_cases = Array[SentimentSample](30)
      
      // Test cases that should be learned correctly
      test_cases.push(SentimentSample("me gusta", 0))      // I like it
      test_cases.push(SentimentSample("love", 0))
      test_cases.push(SentimentSample("happy", 0))
      test_cases.push(SentimentSample("excellent", 0))
      test_cases.push(SentimentSample("fantástico", 0))
      test_cases.push(SentimentSample("increíble", 0))
      test_cases.push(SentimentSample("perfecto", 0))
      test_cases.push(SentimentSample("wonderful", 0))
      test_cases.push(SentimentSample("amazing", 0))
      test_cases.push(SentimentSample("excelente", 0))
      
      test_cases.push(SentimentSample("no me gusta", 1))   // I don't like it
      test_cases.push(SentimentSample("hate", 1))
      test_cases.push(SentimentSample("terrible", 1))
      test_cases.push(SentimentSample("awful", 1))
      test_cases.push(SentimentSample("odio", 1))
      test_cases.push(SentimentSample("horrible", 1))
      test_cases.push(SentimentSample("malo", 1))
      test_cases.push(SentimentSample("pésimo", 1))
      test_cases.push(SentimentSample("disgusting", 1))
      test_cases.push(SentimentSample("worst", 1))
      
      test_cases.push(SentimentSample("table", 2))
      test_cases.push(SentimentSample("chair", 2))
      test_cases.push(SentimentSample("book", 2))
      test_cases.push(SentimentSample("today", 2))
      test_cases.push(SentimentSample("mesa", 2))
      test_cases.push(SentimentSample("libro", 2))
      test_cases.push(SentimentSample("hoy", 2))
      test_cases.push(SentimentSample("normal", 2))
      test_cases.push(SentimentSample("regular", 2))
      test_cases.push(SentimentSample("típico", 2))
      
      test_cases
    end

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