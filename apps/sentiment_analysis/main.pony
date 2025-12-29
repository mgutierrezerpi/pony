// Main entry point for sentiment analysis genetic algorithm
// Modern implementation using clean framework pattern

use "random"
use "time"
use "files"
use "collections"
use "../../packages/_framework"
use "core"

actor Main
  new create(env: Env) =>
    let args = env.args
    if args.size() < 2 then
      _usage(env)
      return
    end

    try
      match args(1)?
      | "train" => _train(env)
      | "resume" => _resume(env, args)
      | "clear" => _clear(env)
      | "summary" => _summary(env)
      | "test" => _test(env)
      | "analyze" => _analyze(env, args)
      else
        _usage(env)
      end
    else
      _usage(env)
    end

  fun _usage(env: Env) =>
    env.out.print("Usage:")
    env.out.print("  sentiment_analysis train              - Train from scratch")
    env.out.print("  sentiment_analysis resume [gens]      - Resume from last saved generation")
    env.out.print("  sentiment_analysis clear              - Clear all saved generations")
    env.out.print("  sentiment_analysis summary            - Generate evolution summary report")
    env.out.print("  sentiment_analysis test               - Test with example sentences")
    env.out.print("  sentiment_analysis analyze <text>     - Analyze sentiment of given text")

  fun _train(env: Env) =>
    env.out.print("=== Sentiment Analysis Evolution ===")
    env.out.print("Loading datasets...")
    env.out.print("")

    // Load NRC lexicons for feature extraction
    let english_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
    let spanish_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")

    // Load IMDB movie reviews dataset (real training data!)
    env.out.print("Loading IMDB dataset (this may take a moment)...")
    let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "apps/sentiment_analysis/data/imdb_dataset.csv")

    env.out.print("English lexicon: " + english_lex.size().string() + " words")
    env.out.print("Spanish lexicon: " + spanish_lex.size().string() + " words")
    env.out.print("IMDB training data: " + imdb_data.size().string() + " movie reviews")
    env.out.print("")
    env.out.print("Starting GA training for sentiment classification...")
    env.out.print("Weighted Classifier: 50 features (50 weights)")
    env.out.print("Test cases: " + TestDataset.get_test_cases().size().string())
    env.out.print("")

    // Create domain with lexicons and IMDB data
    let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)

    let reporter = GenericReporter(env, "apps/sentiment_analysis/bin/")
    GenericGAController[SentimentDomainWithLexicons val, SentimentGenomeOperations val, SentimentEvolutionConfig val]
      .create(env, domain, SentimentGenomeOperations, SentimentEvolutionConfig, reporter)

  fun _resume(env: Env, args: Array[String] val) =>
    // Check if generation limit was provided
    let limit = try
      if args.size() >= 3 then
        args(2)?.usize()?
      else
        0
      end
    else
      0
    end

    // Load the latest generation
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "apps/sentiment_analysis/bin/")

    match genome
    | let g: Array[U8] val =>
      env.out.print("Resuming from generation " + gen.string())

      // Load lexicons and data
      let english_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "apps/sentiment_analysis/data/imdb_dataset.csv")

      let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)
      let reporter = GenericReporter(env, "apps/sentiment_analysis/bin/")

      if limit > 0 then
        env.out.print("Will run for " + limit.string() + " more generations")
        GenericGAController[SentimentDomainWithLexicons val, SentimentGenomeOperations val, SentimentEvolutionConfig val]
          .with_limit(env, domain, SentimentGenomeOperations, SentimentEvolutionConfig, reporter, gen + limit, gen)
      else
        GenericGAController[SentimentDomainWithLexicons val, SentimentGenomeOperations val, SentimentEvolutionConfig val]
          .create(env, domain, SentimentGenomeOperations, SentimentEvolutionConfig, reporter, gen)
      end
    | None =>
      env.out.print("No saved genomes found, starting fresh")
      _train(env)
    end

  fun _clear(env: Env) =>
    env.out.print("Clearing all saved generations...")
    let deleted = GenomePersistence.clear_all_generations(env, "apps/sentiment_analysis/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")

  fun _summary(env: Env) =>
    env.out.print("Generating evolution summary...")

    // Find the latest generation and best fitness
    (let latest_gen, let best_genome) = GenomePersistence.find_latest_generation(env, "apps/sentiment_analysis/bin/")

    match best_genome
    | let genome: Array[U8] val =>
      // Load lexicons and data for evaluation
      let english_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "apps/sentiment_analysis/data/imdb_dataset.csv")
      let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)

      let best_fitness = domain.evaluate(genome)

      // Create evolution summary
      let success = EvolutionDataArchiver.create_evolution_summary_report(
        env,
        "apps/sentiment_analysis/",
        latest_gen,
        best_fitness,
        latest_gen
      )

      if success then
        env.out.print("✓ Evolution summary saved to sentiment_analysis/evolution_summary.yaml")
        env.out.print("Latest generation: " + latest_gen.string())
        env.out.print("Best fitness: " + (best_fitness * 100).string() + "%")
        env.out.print("")
        env.out.print(domain.display_result(genome))
      else
        env.out.print("✗ Failed to save evolution summary")
      end
    | None =>
      env.out.print("No saved genomes found. Run training first.")
    end

  fun _test(env: Env) =>
    env.out.print("Testing sentiment classifier...")

    // Load genome
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "apps/sentiment_analysis/bin/")

    match genome
    | let g: Array[U8] val =>
      env.out.print("Using genome from generation " + gen.string())
      env.out.print("")

      // Load lexicons and data
      let english_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "apps/sentiment_analysis/data/imdb_dataset.csv")
      let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)

      // Show fitness
      let fitness = domain.evaluate(g)
      env.out.print("Accuracy: " + (fitness * 100).string() + "%")
      env.out.print("")

      // Show predictions
      env.out.print(domain.display_result(g))
    | None =>
      env.out.print("No trained genome found. Run 'sentiment_analysis train' first.")
    end

  fun _analyze(env: Env, args: Array[String] val) =>
    // Concatenate all arguments after "analyze" into single text
    var text = ""
    for i in Range[USize](2, args.size()) do
      try
        if i > 2 then
          text = text + " "
        end
        text = text + args(i)?
      end
    end

    if text.size() == 0 then
      env.out.print("Usage: sentiment_analysis analyze \"<text to analyze>\"")
      return
    end

    // Load genome
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "apps/sentiment_analysis/bin/")

    match genome
    | let g: Array[U8] val =>
        // Load lexicons
        let english_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
        let spanish_lex = NRCLexiconLoader.load_lexicon(env, "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")

        // Extract features
        let features = FeatureExtractor.extract(text, english_lex, spanish_lex)

        // Classify using weighted classifier
        let predicted = WeightedClassifier.classify(g, features)
        (let pos_score, let neg_score) = WeightedClassifier.get_scores(g, features)

        let class_names: Array[String] val = ["Positive"; "Negative"]

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

          env.out.print("Text: \"" + text + "\"")
          env.out.print("Sentiment: " + class_name)
          env.out.print("Confidence: " + confidence.string() + "%")
          env.out.print("")
          env.out.print("Detailed scores:")
          env.out.print("  Positive: " + pos_score.string())
          env.out.print("  Negative: " + neg_score.string())
        end
      | None =>
        env.out.print("No trained genome found. Run 'sentiment_analysis train' first.")
      end
