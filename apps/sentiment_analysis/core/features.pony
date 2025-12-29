// Feature extraction for sentiment analysis
// Extracts 50 numerical features from text using NRC lexicon

use "collections"

primitive FeatureExtractor
  """
  Extracts 50 sentiment features from text using NRC Emotion Lexicon.

  Features:
  0-2:   Normalized sentiment word counts (positive, negative, neutral)
  3-5:   Binary indicators (has positive, has negative, has neutral words)
  6-8:   Squared counts (emphasizes strong sentiment)
  9-11:  Language-adjusted scores
  12-20: Text characteristics (length, punctuation, etc.)
  21-49: Zero padding for future extensions
  """

  fun extract(
    text: String,
    english_lexicon: Map[String, (Bool, Bool)] val,
    spanish_lexicon: Map[String, (Bool, Bool)] val): Array[F64] val =>
    """
    Extract all 50 features from input text.
    """
    recover val
      let features = Array[F64](50)

      // Parse text into words
      let lower_text = text.lower()
      let words_iso = lower_text.split(" ")
      let words = recover val consume words_iso end
      let word_count = words.size().f64()

      // Count sentiment words using lexicons
      let sent_counts = _count_sentiment_words(words, english_lexicon, spanish_lexicon)
      let is_spanish = _detect_spanish(words, english_lexicon, spanish_lexicon)

      // Features 0-2: Normalized sentiment word counts
      for i in Range[USize](0, 3) do
        try
          features.push(sent_counts(i)? / word_count.max(1.0))
        else
          features.push(0.0)
        end
      end

      // Features 3-5: Binary indicators
      for i in Range[USize](0, 3) do
        try
          features.push(if sent_counts(i)? > 0 then 1.0 else 0.0 end)
        else
          features.push(0.0)
        end
      end

      // Features 6-8: Squared counts (emphasizes multiple matches)
      for i in Range[USize](0, 3) do
        try
          let count = sent_counts(i)?
          let word_count_sq = word_count.max(1.0) * word_count.max(1.0)
          features.push((count * count) / word_count_sq)
        else
          features.push(0.0)
        end
      end

      // Features 9-11: Language-adjusted scores
      let lang_multiplier: F64 = if is_spanish then 1.1 else 0.9 end
      for i in Range[USize](0, 3) do
        try
          let base_score = sent_counts(i)? / word_count.max(1.0)
          features.push(base_score * lang_multiplier)
        else
          features.push(0.0)
        end
      end

      // Features 12-20: Text characteristics
      features.push(word_count / 20.0)  // Text length (normalized)
      features.push(if text.contains("!") then 1.0 else 0.0 end)  // Exclamation
      features.push(if text.contains("?") then 1.0 else 0.0 end)  // Question
      features.push(if text.contains("¡") then 1.0 else 0.0 end)  // Spanish exclamation
      features.push(if text.contains("¿") then 1.0 else 0.0 end)  // Spanish question
      features.push(if is_spanish then 1.0 else 0.0 end)  // Language indicator
      features.push(_count_capitals(text) / word_count.max(1.0))  // Capital letters ratio
      features.push(if text.contains("very") or text.contains("muy") then 1.0 else 0.0 end)  // Intensifiers
      features.push(if text.contains("not") or text.contains("no") then 1.0 else 0.0 end)  // Negations

      // Features 21-49: Zero padding for future extensions
      for _ in Range[USize](21, 50) do
        features.push(0.0)
      end

      features
    end

  fun _count_sentiment_words(
    words: Array[String] val,
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val): Array[F64] val =>
    """
    Count sentiment words: [positive, negative, neutral]
    """
    recover val
      let counts = Array[F64](3)
      counts.push(0.0)  // positive
      counts.push(0.0)  // negative
      counts.push(0.0)  // neutral

      for word in words.values() do
        // Clean word
        let clean = word.clone()
        clean.strip(" .,!?¡¿\"':;")
        let lower = recover val clean.lower() end

        // Try English lexicon first
        var found = false
        try
          (let is_pos, let is_neg) = english_lex(lower)?
          _update_counts(counts, is_pos, is_neg)
          found = true
        end

        // Try Spanish lexicon if not found
        if not found then
          try
            (let is_pos, let is_neg) = spanish_lex(lower)?
            _update_counts(counts, is_pos, is_neg)
          end
        end
      end

      counts
    end

  fun _update_counts(counts: Array[F64], is_positive: Bool, is_negative: Bool) =>
    """
    Update sentiment counts based on word classification.
    Skip ambiguous words (both positive and negative).
    """
    try
      if is_positive and not is_negative then
        counts(0)? = counts(0)? + 1.0  // Positive
      elseif is_negative and not is_positive then
        counts(1)? = counts(1)? + 1.0  // Negative
      elseif not is_positive and not is_negative then
        counts(2)? = counts(2)? + 1.0  // Neutral
      end
      // Skip words that are both positive and negative (ambiguous)
    end

  fun _detect_spanish(
    words: Array[String] val,
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val): Bool =>
    """
    Detect if text is likely Spanish based on lexicon matches.
    """
    var spanish_count: USize = 0
    var english_count: USize = 0

    for word in words.values() do
      let clean = word.clone()
      clean.strip(" .,!?¡¿\"':;")
      let lower = recover val clean.lower() end

      if english_lex.contains(lower) then
        english_count = english_count + 1
      end

      if spanish_lex.contains(lower) then
        spanish_count = spanish_count + 1
      end
    end

    spanish_count > english_count

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
