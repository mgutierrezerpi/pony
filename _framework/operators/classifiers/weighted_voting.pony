// Reusable weighted voting classifier for binary classification
// Can be used across any GA problem that needs binary classification

use "collections"

primitive WeightedVotingClassifier
  """
  Generic weighted voting classifier for binary classification.

  Architecture:
  - N feature weights (genome size = N bytes)
  - Each feature contributes to one of two classes based on its weight
  - Weight interpretation: 0.0-0.5 favors class 0, 0.5-1.0 favors class 1

  Usage:
    let genome: Array[U8] val = ...     // N bytes of weights
    let features: Array[F64] val = ...  // N feature values
    let predicted = WeightedVotingClassifier.classify(genome, features)
  """

  fun classify(genome: Array[U8] val, features: Array[F64] val): USize =>
    """
    Classify using weighted voting.

    Returns: 0 or 1 (binary classification)
    """
    var score_class0: F64 = 0.0
    var score_class1: F64 = 0.0

    let size = genome.size().min(features.size())

    for i in Range[USize](0, size) do
      try
        let weight = genome(i)?.f64() / 255.0  // Normalize to [0, 1]
        let feature_value = features(i)?

        // Weight determines class contribution
        if weight > 0.5 then
          // Favors class 1
          score_class1 = score_class1 + ((weight - 0.5) * 2.0 * feature_value)
        else
          // Favors class 0
          score_class0 = score_class0 + ((0.5 - weight) * 2.0 * feature_value)
        end
      end
    end

    if score_class1 > score_class0 then 1 else 0 end

  fun get_scores(genome: Array[U8] val, features: Array[F64] val): (F64, F64) =>
    """
    Get raw class scores for interpretation/debugging.
    Returns (score_class0, score_class1)
    """
    var score_class0: F64 = 0.0
    var score_class1: F64 = 0.0

    let size = genome.size().min(features.size())

    for i in Range[USize](0, size) do
      try
        let weight = genome(i)?.f64() / 255.0
        let feature_value = features(i)?

        if weight > 0.5 then
          score_class1 = score_class1 + ((weight - 0.5) * 2.0 * feature_value)
        else
          score_class0 = score_class0 + ((0.5 - weight) * 2.0 * feature_value)
        end
      end
    end

    (score_class0, score_class1)
