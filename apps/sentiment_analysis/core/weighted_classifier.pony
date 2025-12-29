// Sentiment-specific wrapper for the generic WeightedVotingClassifier
// Uses the reusable operator from _framework/operators/classifiers

use "../../../packages/_framework/operators/classifiers"

primitive WeightedClassifier
  """
  Sentiment analysis classifier using the generic WeightedVotingClassifier operator.

  This demonstrates how to use reusable operators from the framework.
  The generic operator handles all the weighted voting logic.

  Genome size: 50 bytes (one weight per feature)
  Returns: 0 = Positive, 1 = Negative
  """

  fun genome_size(): USize => 50

  fun classify(genome: Array[U8] val, features: Array[F64] val): USize =>
    """
    Classify sentiment using the generic weighted voting operator.

    Returns: 0 = Positive, 1 = Negative

    Note: The generic operator returns 1 for "class 1" which we map to Negative.
    """
    WeightedVotingClassifier.classify(genome, features)

  fun get_scores(genome: Array[U8] val, features: Array[F64] val): (F64, F64) =>
    """
    Get raw class scores using the generic operator.
    Returns (positive_score, negative_score) where positive = class 0, negative = class 1
    """
    WeightedVotingClassifier.get_scores(genome, features)
