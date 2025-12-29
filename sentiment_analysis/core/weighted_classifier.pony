// Weighted feature voting classifier for sentiment analysis
// Much simpler than neural network - perfect for genetic algorithms!

use "collections"

primitive WeightedClassifier
  """
  Simple weighted voting classifier for binary sentiment classification.

  Architecture:
  - 50 feature weights (one per feature)
  - Each feature votes for positive or negative based on its weight
  - First 3 features are: positive_count, negative_count, neutral_count

  Genome size: 50 bytes (one weight per feature)

  This is MUCH simpler than the neural network (50 vs 797 weights)!
  """

  fun genome_size(): USize => 50

  fun classify(genome: Array[U8] val, features: Array[F64] val): USize =>
    """
    Classify sentiment using weighted voting.

    Returns: 0 = Positive, 1 = Negative
    """
    var positive_score: F64 = 0.0
    var negative_score: F64 = 0.0

    // Iterate through all 50 features
    for i in Range[USize](0, 50) do
      try
        let weight = genome(i)?.f64() / 255.0  // Normalize to 0-1
        let feature_value = features(i)?

        // First 3 features are sentiment word counts
        // Feature 0: positive word count
        // Feature 1: negative word count
        // Feature 2: neutral word count

        // Features 3-5: binary indicators (has positive/negative/neutral words)
        // Features 6+: other features (punctuation, length, etc.)

        match i
        | 0 =>
          // Positive word count feature - contributes to positive score
          positive_score = positive_score + (weight * feature_value)
        | 1 =>
          // Negative word count feature - contributes to negative score
          negative_score = negative_score + (weight * feature_value)
        | 2 =>
          // Neutral word count - split contribution (learn which way it leans)
          if weight > 0.5 then
            positive_score = positive_score + ((weight - 0.5) * feature_value)
          else
            negative_score = negative_score + ((0.5 - weight) * feature_value)
          end
        else
          // All other features: weight determines which class they support
          // Weight > 0.5 = contributes to positive
          // Weight < 0.5 = contributes to negative
          // Weight = 0.5 = neutral (no contribution)

          if weight > 0.5 then
            positive_score = positive_score + ((weight - 0.5) * 2.0 * feature_value)
          else
            negative_score = negative_score + ((0.5 - weight) * 2.0 * feature_value)
          end
        end
      end
    end

    // Winner takes all - no diversity penalty needed!
    // The simple structure prevents degenerate solutions naturally
    if positive_score > negative_score then
      0  // Positive
    else
      1  // Negative
    end

  fun get_scores(genome: Array[U8] val, features: Array[F64] val): (F64, F64) =>
    """
    Get raw positive and negative scores (for debugging/display).
    Returns (positive_score, negative_score)
    """
    var positive_score: F64 = 0.0
    var negative_score: F64 = 0.0

    for i in Range[USize](0, 50) do
      try
        let weight = genome(i)?.f64() / 255.0
        let feature_value = features(i)?

        match i
        | 0 =>
          positive_score = positive_score + (weight * feature_value)
        | 1 =>
          negative_score = negative_score + (weight * feature_value)
        | 2 =>
          if weight > 0.5 then
            positive_score = positive_score + ((weight - 0.5) * feature_value)
          else
            negative_score = negative_score + ((0.5 - weight) * feature_value)
          end
        else
          if weight > 0.5 then
            positive_score = positive_score + ((weight - 0.5) * 2.0 * feature_value)
          else
            negative_score = negative_score + ((0.5 - weight) * 2.0 * feature_value)
          end
        end
      end
    end

    (positive_score, negative_score)
