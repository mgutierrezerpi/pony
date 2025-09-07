// Sentiment analysis problem domain using neural network evolution

use "random"
use "collections"
use ".."
use "../_framework"

primitive SentimentDomain is ProblemDomain
  """
  Problem domain for evolving neural network weights for multilingual emotion detection.
  Based on NRC Emotion Lexicon - detects 8 emotions + positive/negative sentiment.
  Supports both Spanish and English text.
  """
  
  fun genome_size(): USize => 
    // Input layer: 100 lexicon features (emotions + sentiment) + 1 bias
    // Hidden layer: 20 neurons + 1 bias  
    // Output layer: 10 neurons (8 emotions + 2 sentiment) + 1 bias
    // Total weights: (100+1)*20 + (20+1)*10 = 2020 + 210 = 2230
    2230
  
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
    Evaluate fitness by testing on emotion/sentiment classification dataset.
    """
    var correct: USize = 0
    let total = EmotionData.training_data().size()
    
    for sample in EmotionData.training_data().values() do
      let features = extract_nrc_features(sample.text)
      let predictions = forward_pass(genome, features)
      
      // Check if the predicted emotions/sentiment match the ground truth
      var sample_correct = true
      for i in Range[USize](0, 10) do
        try
          let predicted: USize = if predictions(i)? > 0.5 then 1 else 0 end
          let actual = sample.labels(i)?
          if predicted != actual then
            sample_correct = false
            break
          end
        end
      end
      
      if sample_correct then
        correct = correct + 1
      end
    end
    
    correct.f64() / total.f64()
  
  fun perfect_fitness(): F64 => 0.95  // 95% accuracy is considered perfect
  
  fun display_result(genome: Array[U8] val): String =>
    """
    Test the network on example sentences in Spanish and English.
    """
    let examples = [
      "I love this movie, it's amazing!"
      "Me encanta esta película, es increíble!"
      "This film is terrible and boring."
      "Esta película es terrible y aburrida."
      "I feel scared and anxious."
      "Me siento asustado y ansioso."
      "What a surprise! I'm so happy!"
      "¡Qué sorpresa! ¡Estoy tan feliz!"
    ]
    
    let emotion_names: Array[String] = ["anger"; "anticipation"; "disgust"; "fear"; "joy"; "sadness"; "surprise"; "trust"; "positive"; "negative"]
    
    var result = "Emotion predictions:\n"
    for text in examples.values() do
      let features = extract_nrc_features(text)
      let predictions = forward_pass(genome, features)
      
      result = result + "\"" + text + "\" ->\n"
      for i in Range[USize](0, 10) do
        try
          let emotion = emotion_names(i)?
          let confidence = predictions(i)?
          if confidence > 0.5 then
            result = result + "  " + emotion + ": " + (confidence * 100).string() + "%\n"
          end
        end
      end
      result = result + "\n"
    end
    result
  
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
    Perform forward pass through the neural network.
    Returns 10 outputs: 8 emotions + 2 sentiment (positive/negative).
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
    
    // Input to hidden layer (100 inputs + bias -> 20 hidden)
    let hidden = recover val
      let h_array = Array[F64](20)
      for h in Range[USize](0, 20) do
        var sum: F64 = 0.0
        
        // Add weighted inputs
        for feat_idx in Range[USize](0, 100) do
          try
            let weight_idx = (h * 101) + feat_idx  // 101 = 100 features + 1 bias per hidden neuron
            sum = sum + (features(feat_idx)? * weights(weight_idx)?)
          end
        end
        
        // Add bias weight
        try
          let bias_idx = (h * 101) + 100
          sum = sum + weights(bias_idx)?
        end
        
        // Apply sigmoid activation
        h_array.push(_sigmoid(sum))
      end
      h_array
    end
    
    // Hidden to output layer (20 hidden + bias -> 10 outputs)
    recover val
      let outputs = Array[F64](10)
      for o in Range[USize](0, 10) do
        var output_sum: F64 = 0.0
        
        // Add weighted hidden layer outputs
        for hid_idx in Range[USize](0, 20) do
          try
            let weight_idx = 2020 + (o * 21) + hid_idx  // Offset past input->hidden weights
            output_sum = output_sum + (hidden(hid_idx)? * weights(weight_idx)?)
          end
        end
        
        // Add output bias
        try
          let bias_idx = 2020 + (o * 21) + 20
          output_sum = output_sum + weights(bias_idx)?
        end
        
        // Apply sigmoid activation
        outputs.push(_sigmoid(output_sum))
      end
      outputs
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
        if word.contains(indicator) then
          spanish_count = spanish_count + 1
          break
        end
      end
    end
    
    // If more than 20% of words are Spanish indicators, consider it Spanish
    spanish_count.f64() > (words.size().f64() * 0.2)

// Training data structure for emotion detection
class EmotionSample
  let text: String
  let labels: Array[USize] val  // 10 binary labels: [anger, anticipation, disgust, fear, joy, sadness, surprise, trust, positive, negative]
  
  new create(t: String, l: Array[USize] val) =>
    text = t
    labels = l

primitive EmotionData
  """
  Training dataset for multilingual emotion detection.
  Based on NRC Emotion Lexicon categories.
  """
  
  fun training_data(): Array[EmotionSample] val =>
    recover val
      let data = Array[EmotionSample](24)
      
      // Joy + Positive examples
      data.push(EmotionSample("I love this movie, it's amazing!", [0; 0; 0; 0; 1; 0; 0; 0; 1; 0]))
      data.push(EmotionSample("Me encanta esta película, es increíble!", [0; 0; 0; 0; 1; 0; 0; 0; 1; 0]))
      data.push(EmotionSample("I'm so happy and cheerful today!", [0; 0; 0; 0; 1; 0; 0; 0; 1; 0]))
      data.push(EmotionSample("Estoy tan feliz y alegre hoy!", [0; 0; 0; 0; 1; 0; 0; 0; 1; 0]))
      
      // Anger + Negative examples
      data.push(EmotionSample("I'm furious about this terrible service!", [1; 0; 0; 0; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("Estoy furioso por este servicio terrible!", [1; 0; 0; 0; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("This makes me so angry and mad!", [1; 0; 0; 0; 0; 0; 0; 0; 0; 1]))
      
      // Fear + Negative examples  
      data.push(EmotionSample("I'm so scared and terrified!", [0; 0; 0; 1; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("Tengo mucho miedo y estoy asustado!", [0; 0; 0; 1; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("This is frightening and makes me afraid!", [0; 0; 0; 1; 0; 0; 0; 0; 0; 1]))
      
      // Sadness + Negative examples
      data.push(EmotionSample("I feel so sad and depressed today.", [0; 0; 0; 0; 0; 1; 0; 0; 0; 1]))
      data.push(EmotionSample("Me siento tan triste y deprimido hoy.", [0; 0; 0; 0; 0; 1; 0; 0; 0; 1]))
      data.push(EmotionSample("This is heartbreaking and makes me unhappy.", [0; 0; 0; 0; 0; 1; 0; 0; 0; 1]))
      
      // Surprise + Mixed sentiment
      data.push(EmotionSample("What a surprise! I'm amazed!", [0; 0; 0; 0; 0; 0; 1; 0; 1; 0]))
      data.push(EmotionSample("¡Qué sorpresa! ¡Estoy asombrado!", [0; 0; 0; 0; 0; 0; 1; 0; 1; 0]))
      data.push(EmotionSample("I'm shocked by this unexpected news.", [0; 0; 0; 0; 0; 0; 1; 0; 0; 0]))
      
      // Anticipation + Positive
      data.push(EmotionSample("I'm so excited and eager for tomorrow!", [0; 1; 0; 0; 0; 0; 0; 0; 1; 0]))
      data.push(EmotionSample("Estoy tan emocionado y ansioso por mañana!", [0; 1; 0; 0; 0; 0; 0; 0; 1; 0]))
      data.push(EmotionSample("I hope and expect great things!", [0; 1; 0; 0; 0; 0; 0; 0; 1; 0]))
      
      // Disgust + Negative
      data.push(EmotionSample("This is disgusting and revolting!", [0; 0; 1; 0; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("Esto es asqueroso y repugnante!", [0; 0; 1; 0; 0; 0; 0; 0; 0; 1]))
      data.push(EmotionSample("I find this gross and awful.", [0; 0; 1; 0; 0; 0; 0; 0; 0; 1]))
      
      // Trust + Positive
      data.push(EmotionSample("I have complete faith and confidence!", [0; 0; 0; 0; 0; 0; 0; 1; 1; 0]))
      data.push(EmotionSample("Tengo completa fe y confianza!", [0; 0; 0; 0; 0; 0; 0; 1; 1; 0]))
      data.push(EmotionSample("I trust this decision completely.", [0; 0; 0; 0; 0; 0; 0; 1; 1; 0]))
      
      data
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
    // Layer 1: 0 to 2019 (input to hidden weights: 100*20 + 20 biases = 2020)
    // Layer 2: 2020 to 2229 (hidden to output weights: 20*10 + 10 biases = 210)
    let crossover_points: Array[USize] val = recover val [2020] end  // Crossover between layers
    
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
  fun worker_count(): USize => 4
  fun mutation_rate(): F64 => 0.1
  fun crossover_rate(): F64 => 0.8
  fun elitism_count(): USize => 3