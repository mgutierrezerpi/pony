// File I/O utilities for the genetic algorithm framework

use "files"
use "collections"
use "random"

primitive FileReader
  """
  Utility for reading files with proper error handling and authorization.
  """
  
  fun read_lines(env: Env, filepath: String): Array[String] val =>
    """
    Read all lines from a file. Returns empty array on error.
    """
    recover val
      let lines = Array[String](0)
      
      let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
      let auth = FileAuth(env.root)
      let path = FilePath(auth, filepath, caps)
      
      if path.exists() then
        let file = File.open(path)
        for line in file.lines() do
          lines.push(line.clone())
        end
        file.dispose()
      end
      
      lines
    end
  
  fun read_nrc_lexicon(env: Env, filepath: String): Map[String, (Bool, Bool)] val =>
    """
    Read NRC Emotion Lexicon file and extract positive/negative associations.
    Returns a map of word -> (is_positive, is_negative)
    """
    recover val
      let word_sentiments = Map[String, (Bool, Bool)](0)
      let lines = read_lines(env, filepath)
      
      var current_word: String = ""
      var is_positive: Bool = false
      var is_negative: Bool = false
      
      for line in lines.values() do
        let parts = line.split("\t")
        if parts.size() >= 3 then
          try
            let word = parts(0)?
            let emotion = parts(1)?
            let value = parts(2)?.usize()?
            
            // If we've moved to a new word, store the previous one
            if (word != current_word) and (current_word != "") then
              word_sentiments(current_word) = (is_positive, is_negative)
              is_positive = false
              is_negative = false
            end
            
            current_word = word
            
            // Track positive/negative associations
            if (emotion == "positive") and (value == 1) then
              is_positive = true
            elseif (emotion == "negative") and (value == 1) then
              is_negative = true
            end
          end
        end
      end
      
      // Store the last word
      if current_word != "" then
        word_sentiments(current_word) = (is_positive, is_negative)
      end
      
      word_sentiments
    end

primitive DatasetBuilder
  """
  Build training datasets from NRC lexicon files.
  """
  
  fun load_random_sentiment_subset(env: Env, subset_size: USize, rng: Rand): Array[(String, USize)] val =>
    """
    Load a random subset of sentiment training samples from NRC lexicon files.
    This provides dynamic training data for each generation.
    Returns array of (text, class) where class: 0=positive, 1=negative, 2=neutral
    """
    recover val
      // First load all available samples
      let all_samples = load_all_sentiment_samples(env)
      
      // Create a shuffled subset
      let samples = Array[(String, USize)](0)
      let total_available = all_samples.size()
      
      if total_available > 0 then
        // Randomly select samples without replacement
        let indices = Array[USize](0)
        for i in Range[USize](0, total_available) do
          indices.push(i)
        end
        
        // Fisher-Yates shuffle of indices
        var k = indices.size()
        while k > 1 do
          k = k - 1
          let j = rng.next().usize() % (k + 1)
          try
            let temp = indices(k)?
            indices(k)? = indices(j)?
            indices(j)? = temp
          end
        end
        
        // Take first subset_size samples
        let actual_size = subset_size.min(total_available)
        for idx in Range[USize](0, actual_size) do
          try
            let sample_idx = indices(idx)?
            samples.push(all_samples(sample_idx)?)
          end
        end
      end
      
      samples
    end
  
  fun load_all_sentiment_samples(env: Env): Array[(String, USize)] val =>
    """
    Load ALL sentiment training samples from NRC lexicon files.
    Used internally for creating random subsets.
    """
    recover val
      let samples = Array[(String, USize)](0)
      
      // Load English lexicon
      let english_words = FileReader.read_nrc_lexicon(env, "sentiment/data/English-NRC-EmoLex.txt")
      for (word, sentiments) in english_words.pairs() do
        (let is_positive, let is_negative) = sentiments
        if is_positive and not is_negative then
          samples.push((word, 0))  // Positive
        elseif is_negative and not is_positive then
          samples.push((word, 1))  // Negative  
        elseif not is_positive and not is_negative then
          samples.push((word, 2))  // Neutral
        end
        // Skip ambiguous words that are both positive and negative
      end
      
      // Load Spanish lexicon
      let spanish_words = FileReader.read_nrc_lexicon(env, "sentiment/data/Spanish-NRC-EmoLex.txt")
      for (spanish_word, spanish_sentiments) in spanish_words.pairs() do
        (let spanish_is_positive, let spanish_is_negative) = spanish_sentiments
        if spanish_is_positive and not spanish_is_negative then
          samples.push((spanish_word, 0))  // Positive
        elseif spanish_is_negative and not spanish_is_positive then
          samples.push((spanish_word, 1))  // Negative
        elseif not spanish_is_positive and not spanish_is_negative then
          samples.push((spanish_word, 2))  // Neutral
        end
      end
      
      // Add some explicit neutral words for balance
      let neutral_words: Array[String] val = ["the"; "and"; "or"; "but"; "if"; "then"; "when"; "where"; "how"; "what"; "who"; "which"; "this"; "that"; "these"; "those"; "here"; "there"; "today"; "yesterday"; "tomorrow"; "now"; "later"; "before"; "after"; "table"; "chair"; "book"; "car"; "house"; "street"; "city"; "country"; "el"; "la"; "y"; "o"; "pero"; "si"; "entonces"; "cuando"; "donde"; "como"; "que"; "quien"; "cual"; "este"; "ese"; "estos"; "esos"; "aqui"; "alli"; "hoy"; "ayer"; "mañana"; "ahora"; "despues"; "antes"; "mesa"; "silla"]
      
      for neutral_word in neutral_words.values() do
        samples.push((neutral_word, 2))  // Neutral
      end
      
      samples
    end
  
  fun get_test_cases(): Array[(String, USize)] val =>
    """
    Get a fixed set of test cases for consistent evaluation across generations.
    These are separate from training data and remain constant.
    """
    recover val
      let test_cases = Array[(String, USize)](0)
      
      // Positive test cases
      test_cases.push(("love", 0))
      test_cases.push(("happy", 0))
      test_cases.push(("excellent", 0))
      test_cases.push(("wonderful", 0))
      test_cases.push(("amazing", 0))
      test_cases.push(("perfect", 0))
      test_cases.push(("me gusta", 0))
      test_cases.push(("fantástico", 0))
      test_cases.push(("increíble", 0))
      test_cases.push(("excelente", 0))
      
      // Negative test cases
      test_cases.push(("hate", 1))
      test_cases.push(("terrible", 1))
      test_cases.push(("awful", 1))
      test_cases.push(("horrible", 1))
      test_cases.push(("disgusting", 1))
      test_cases.push(("worst", 1))
      test_cases.push(("odio", 1))
      test_cases.push(("malo", 1))
      test_cases.push(("pésimo", 1))
      test_cases.push(("horrible", 1))
      
      // Neutral test cases
      test_cases.push(("table", 2))
      test_cases.push(("chair", 2))
      test_cases.push(("book", 2))
      test_cases.push(("today", 2))
      test_cases.push(("regular", 2))
      test_cases.push(("normal", 2))
      test_cases.push(("mesa", 2))
      test_cases.push(("libro", 2))
      test_cases.push(("hoy", 2))
      test_cases.push(("normal", 2))
      
      test_cases
    end