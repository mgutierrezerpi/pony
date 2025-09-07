// Main entry point for sentiment analysis using the GA framework

use "files"
use "random"
use "collections"
use "_framework"
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
      | "analyze" => _analyze(env, args)
      | "test" => _test(env, args)
      else
        _usage(env)
      end
    else
      _usage(env)
    end
  
  fun _usage(env: Env) =>
    env.out.print("Usage:")
    env.out.print("  sentiment train                    - Train sentiment classifier from scratch")
    env.out.print("  sentiment resume [gens]            - Resume from last saved generation")
    env.out.print("  sentiment clear                    - Clear all saved generations")
    env.out.print("  sentiment analyze \"<text>\"         - Classify sentiment (positive/negative/neutral)")
    env.out.print("  sentiment test                     - Test with example sentences")
    env.out.print("")
    env.out.print("Examples:")
    env.out.print("  sentiment analyze \"I'm so happy today!\"")
    env.out.print("  sentiment analyze \"Me siento triste y solo\"")
  
  fun _train(env: Env) =>
    env.out.print("Starting parallel GA training for multilingual sentiment classification...")
    env.out.print("3-class classification: positive, negative, neutral")
    env.out.print("Loading NRC lexicon data...")
    let domain = SentimentDomain(env)
    env.out.print("Using " + SentimentConfig.worker_count().string() + " parallel workers")
    let reporter = GenericReporter(env, "sentiment/bin/")
    ParallelGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
      .create(env, consume domain, SentimentGenomeOps, SentimentConfig, reporter)
  
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
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment/bin/")
    
    match genome
    | let g: Array[U8] val =>
      env.out.print("Resuming sentiment classification training from generation " + gen.string())
      env.out.print("Loading NRC lexicon data...")
      let domain = SentimentDomain(env)
      let reporter = GenericReporter(env, "sentiment/bin/")
      
      if limit > 0 then
        env.out.print("Will run for " + limit.string() + " more generations")
        env.out.print("Using " + SentimentConfig.worker_count().string() + " parallel workers")
        ParallelGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .with_limit(env, consume domain, SentimentGenomeOps, SentimentConfig, reporter, gen + limit)
      else
        env.out.print("Using " + SentimentConfig.worker_count().string() + " parallel workers")
        ParallelGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .create(env, consume domain, SentimentGenomeOps, SentimentConfig, reporter)
      end
    | None =>
      env.out.print("No saved sentiment models found, starting fresh training")
      _train(env)
    end
  
  fun _clear(env: Env) =>
    env.out.print("Clearing all saved sentiment classification models...")
    let deleted = GenomePersistence.clear_all_generations(env, "sentiment/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")
  
  fun _analyze(env: Env, args: Array[String] val) =>
    if args.size() < 3 then
      env.out.print("Usage: sentiment analyze \"<text>\"")
      env.out.print("Example: sentiment analyze \"I'm feeling happy and excited!\"")
      return
    end
    
    // Join all arguments from position 2 onwards to handle multi-word text
    var text = ""
    for i in Range[USize](2, args.size()) do
      try
        if text.size() > 0 then
          text = text + " " + args(i)?
        else
          text = args(i)?
        end
      end
    end
    
    // Load the best trained model
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment/bin/")
    
    match genome
      | let g: Array[U8] val =>
        env.out.print("Analyzing text using model from generation " + gen.string())
        env.out.print("Text: \"" + text + "\"")
        env.out.print("")
        
        // Extract features and run analysis
        let domain = SentimentDomain(env)
        let features = domain.extract_sentiment_features(text)
        let predictions = domain.forward_pass(g, features)
        
        // Find the predicted sentiment class (highest confidence)
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
        
        // Display results
        let sentiment_names: Array[String] = ["Positive"; "Negative"; "Neutral"]
        let sentiment_colors: Array[String] = ["✅"; "❌"; "⚪"]
        let sentiment_emojis: Array[String] = ["😊"; "😞"; "😐"]
        
        env.out.print("Sentiment Classification:")
        try
          let name = sentiment_names(predicted_class)?
          let color = sentiment_colors(predicted_class)?
          let emoji = sentiment_emojis(predicted_class)?
          let bar = _create_bar(max_confidence)
          let conf_pct = (max_confidence * 100).f64().string()
          env.out.print("  " + emoji + " " + color + " " + name + ": " + consume conf_pct + "% " + bar)
        end
        
        env.out.print("")
        env.out.print("All predictions:")
        for i in Range[USize](0, 3) do
          try
            let name = sentiment_names(i)?
            let color = sentiment_colors(i)?
            let confidence = predictions(i)?
            let bar = _create_bar(confidence)
            let conf_pct = (confidence * 100).f64().string()
            env.out.print("  " + color + " " + name + ": " + consume conf_pct + "% " + bar)
          end
        end
        
        // Language detection
        let lower_text = text.lower()
        let words_iso = lower_text.split(" ")
        let words = recover val consume words_iso end
        let is_spanish = domain.detect_spanish(words)
        env.out.print("")
        env.out.print("Detected language: " + if is_spanish then "Spanish 🇪🇸" else "English 🇺🇸" end)
        
      | None =>
        env.out.print("No trained sentiment model found.")
        env.out.print("Run 'sentiment train' first to create a model.")
      end
  
  fun _test(env: Env, args: Array[String] val) =>
    env.out.print("Testing sentiment classification with example sentences...")
    
    // Load the best trained model
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment/bin/")
    
    match genome
    | let g: Array[U8] val =>
      env.out.print("Using model from generation " + gen.string())
      let domain = SentimentDomain(env)
      env.out.print(domain.display_result(g))
    | None =>
      env.out.print("No trained sentiment model found.")
      env.out.print("Run 'sentiment train' first to create a model.")
      env.out.print("")
      env.out.print("Meanwhile, here are example sentiments that would be detected:")
      env.out.print("😊 Positive: \"I'm so happy!\" / \"¡Estoy tan feliz!\"")
      env.out.print("😞 Negative: \"This is terrible!\" / \"¡Esto es terrible!\"") 
      env.out.print("😐 Neutral: \"The weather is okay.\" / \"El clima está bien.\"")
    end
  
  fun _create_bar(confidence: F64): String =>
    """
    Create a visual progress bar for confidence levels.
    """
    let bar_length: USize = 20
    let filled = (confidence * bar_length.f64()).usize()
    
    var bar = "["
    for i in Range[USize](0, bar_length) do
      if i < filled then
        bar = bar + "█"
      else
        bar = bar + "░"
      end
    end
    bar + "]"