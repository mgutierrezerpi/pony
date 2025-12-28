// Main entry point for sentiment analysis genetic algorithm
// Modern implementation using clean framework pattern

use "random"
use "time"
use "files"
use "../_framework"
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
    let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
    let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")

    // Load IMDB movie reviews dataset (real training data!)
    env.out.print("Loading IMDB dataset (this may take a moment)...")
    let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "sentiment_analysis/data/imdb_dataset.csv")

    env.out.print("English lexicon: " + english_lex.size().string() + " words")
    env.out.print("Spanish lexicon: " + spanish_lex.size().string() + " words")
    env.out.print("IMDB training data: " + imdb_data.size().string() + " movie reviews")
    env.out.print("")
    env.out.print("Starting GA training for sentiment classification...")
    env.out.print("Neural Network: 50 -> 15 -> 3 (813 weights)")
    env.out.print("Test cases: " + TestDataset.get_test_cases().size().string())
    env.out.print("")

    // Create domain with lexicons and IMDB data
    let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)

    let reporter = GenericReporter(env, "sentiment_analysis/bin/")
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
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment_analysis/bin/")

    match genome
    | let g: Array[U8] val =>
      env.out.print("Resuming from generation " + gen.string())

      // Load lexicons and data
      let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "sentiment_analysis/data/imdb_dataset.csv")

      let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)
      let reporter = GenericReporter(env, "sentiment_analysis/bin/")

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
    let deleted = GenomePersistence.clear_all_generations(env, "sentiment_analysis/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")

  fun _summary(env: Env) =>
    env.out.print("Generating evolution summary...")

    // Find the latest generation and best fitness
    (let latest_gen, let best_genome) = GenomePersistence.find_latest_generation(env, "sentiment_analysis/bin/")

    match best_genome
    | let genome: Array[U8] val =>
      // Load lexicons and data for evaluation
      let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "sentiment_analysis/data/imdb_dataset.csv")
      let domain = SentimentDomainWithLexicons(english_lex, spanish_lex, imdb_data)

      let best_fitness = domain.evaluate(genome)

      // Create evolution summary
      let success = EvolutionDataArchiver.create_evolution_summary_report(
        env,
        "sentiment_analysis/",
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
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment_analysis/bin/")

    match genome
    | let g: Array[U8] val =>
      env.out.print("Using genome from generation " + gen.string())
      env.out.print("")

      // Load lexicons and data
      let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
      let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
      env.out.print("Loading IMDB dataset...")
      let imdb_data = IMDBDatasetLoader.load_imdb_dataset(env, "sentiment_analysis/data/imdb_dataset.csv")
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
    try
      let text = args(2)?

      // Load genome
      (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment_analysis/bin/")

      match genome
      | let g: Array[U8] val =>
        // Load lexicons
        let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
        let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")

        // Extract features
        let features = FeatureExtractor.extract(text, english_lex, spanish_lex)

        // Classify
        let outputs = NeuralNetwork.forward_pass(g, features)
        let predicted = NeuralNetwork.classify(outputs)

        let class_names: Array[String] val = ["Positive"; "Negative"; "Neutral"]

        try
          let class_name = class_names(predicted)?
          let confidence = outputs(predicted)?

          env.out.print("Text: \"" + text + "\"")
          env.out.print("Sentiment: " + class_name)
          env.out.print("Confidence: " + (confidence * 100).string() + "%")
          env.out.print("")
          env.out.print("Detailed scores:")
          env.out.print("  Positive: " + (outputs(0)? * 100).string() + "%")
          env.out.print("  Negative: " + (outputs(1)? * 100).string() + "%")
          env.out.print("  Neutral: " + (outputs(2)? * 100).string() + "%")
        end
      | None =>
        env.out.print("No trained genome found. Run 'sentiment_analysis train' first.")
      end
    else
      env.out.print("Usage: sentiment_analysis analyze \"<text to analyze>\"")
    end
