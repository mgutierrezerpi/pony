// Data loading utilities for NRC Emotion Lexicon
// Loads sentiment words from multilingual lexicon files

use "files"
use "collections"

primitive NRCLexiconLoader
  """
  Loads NRC Emotion Lexicon data files for sentiment analysis.

  File format: word\temotion\tassociation
  Example: love\tpositive\t1
  """

  fun load_lexicon(env: Env, file_path: String): Map[String, (Bool, Bool)] val =>
    """
    Load NRC lexicon file and return map of words to (is_positive, is_negative).

    Returns a map where:
    - Key: lowercase word
    - Value: tuple (is_positive, is_negative)
    """
    recover val
      let lexicon = Map[String, (Bool, Bool)]

      try
        let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
        let path = FilePath(FileAuth(env.root), file_path, caps)
        let file = OpenFile(path) as File

        for line in file.lines() do
          let parts_iso = line.split("\t")
          let parts = recover val consume parts_iso end

          // Parse: word\temotion\tvalue
          if parts.size() >= 3 then
            try
              let word = parts(0)?
              let emotion = parts(1)?
              let value_str = parts(2)?
              let value = value_str.usize()?

              // Only care about positive and negative associations
              if value == 1 then
                // Get or create entry for this word
                (var is_pos, var is_neg) = try
                  lexicon(word)?
                else
                  (false, false)
                end

                // Update based on emotion
                if emotion == "positive" then
                  is_pos = true
                elseif emotion == "negative" then
                  is_neg = true
                end

                lexicon(word) = (is_pos, is_neg)
              end
            end
          end
        end
      end

      lexicon
    end

  fun build_training_data_from_lexicon(
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val): Array[(String, USize)] val =>
    """
    Build training dataset from lexicon words themselves.
    Creates simple sentences from single words to train on real lexicon data.
    """
    recover val
      let training_data = Array[(String, USize)]

      // English positive words
      for (word, sentiment) in english_lex.pairs() do
        (let is_pos, let is_neg) = sentiment

        if is_pos and not is_neg then
          // Simple positive sentence templates
          training_data.push(("I feel " + word, 0))
          training_data.push(("This is " + word, 0))
        elseif is_neg and not is_pos then
          // Simple negative sentence templates
          training_data.push(("I feel " + word, 1))
          training_data.push(("This is " + word, 1))
        elseif not is_pos and not is_neg then
          // Neutral words
          training_data.push(("The " + word, 2))
        end
      end

      // Spanish positive words
      for (word, sentiment) in spanish_lex.pairs() do
        (let is_pos, let is_neg) = sentiment

        if is_pos and not is_neg then
          training_data.push(("Me siento " + word, 0))
          training_data.push(("Esto es " + word, 0))
        elseif is_neg and not is_pos then
          training_data.push(("Me siento " + word, 1))
          training_data.push(("Esto es " + word, 1))
        elseif not is_pos and not is_neg then
          training_data.push(("El " + word, 2))
        end
      end

      training_data
    end

primitive TestDataset
  """
  Provides test cases for sentiment classification.

  Returns array of (text, class) tuples where:
  - class 0 = positive
  - class 1 = negative
  - class 2 = neutral
  """

  fun get_test_cases(): Array[(String, USize)] val =>
    """
    Test cases using words from NRC lexicon to ensure feature extraction works.
    """
    recover val
      [
        // English positive (using NRC lexicon words)
        ("I love this wonderful movie", 0)
        ("This is beautiful and joyful", 0)
        ("So happy and excited about this", 0)
        ("Delightful day with pleasant friends", 0)
        ("Excellent and marvelous work", 0)
        ("Amazingly good and lovely", 0)
        ("Cheerful and grateful today", 0)
        ("Brilliant and glorious success", 0)

        // English negative (using NRC lexicon words)
        ("I hate this terrible thing", 1)
        ("This is awful and horrible", 1)
        ("So sad and angry about this", 1)
        ("Disgusting and disappointing failure", 1)
        ("Worst and dreadful experience", 1)
        ("Miserable and nasty situation", 1)
        ("Cruel and wicked behavior", 1)
        ("Frightening and disturbing news", 1)

        // English neutral
        ("The table is wooden", 2)
        ("It is what it is", 2)
        ("The meeting is scheduled", 2)
        ("This contains information", 2)
        ("The document has pages", 2)
        ("The building is tall", 2)
        ("The number is seventeen", 2)
        ("The object is round", 2)

        // Spanish positive
        ("Me encanta esta película maravillosa", 0)
        ("Esto es hermoso y alegre", 0)
        ("Muy feliz y emocionado por esto", 0)
        ("Día agradable con buenos amigos", 0)
        ("Excelente y magnífico trabajo", 0)

        // Spanish negative
        ("Odio esta cosa terrible", 1)
        ("Esto es horrible y espantoso", 1)
        ("Muy triste y enojado por esto", 1)
        ("Asqueroso y decepcionante", 1)
        ("Peor y horrible experiencia", 1)

        // Spanish neutral
        ("La mesa es marrón", 2)
        ("Es lo que es", 2)
        ("La reunión es programada", 2)
        ("Esto contiene datos", 2)
        ("El documento tiene páginas", 2)
      ]
    end

  fun get_training_samples(): Array[(String, USize)] val =>
    """
    Additional training samples beyond the lexicon.
    """
    recover val
      [
        // More varied English examples
        ("absolutely brilliant and outstanding", 0)
        ("completely terrible and pathetic", 1)
        ("the item is on the shelf", 2)
        ("magnificent and superb quality", 0)
        ("dreadful and miserable failure", 1)

        // More varied Spanish examples
        ("absolutamente brillante y excepcional", 0)
        ("completamente terrible y patético", 1)
        ("el artículo está en el estante", 2)
        ("magnífico y calidad soberbia", 0)
        ("espantoso y miserable fracaso", 1)
      ]
    end
