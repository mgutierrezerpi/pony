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
    env.out.print("  sentiment train                    - Train emotion detection from scratch")
    env.out.print("  sentiment resume [gens]            - Resume from last saved generation")
    env.out.print("  sentiment clear                    - Clear all saved generations")
    env.out.print("  sentiment analyze \"<text>\"         - Analyze emotions in text")
    env.out.print("  sentiment test                     - Test with example sentences")
    env.out.print("")
    env.out.print("Examples:")
    env.out.print("  sentiment analyze \"I'm so happy today!\"")
    env.out.print("  sentiment analyze \"Me siento triste y solo\"")
  
  fun _train(env: Env) =>
    env.out.print("Starting GA training for multilingual emotion detection...")
    env.out.print("Based on NRC Emotion Lexicon (8 emotions + positive/negative sentiment)")
    let reporter = GenericReporter(env, "sentiment/bin/")
    GenericGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
      .create(env, SentimentDomain, SentimentGenomeOps, SentimentConfig, reporter)
  
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
      env.out.print("Resuming emotion detection training from generation " + gen.string())
      let reporter = GenericReporter(env, "sentiment/bin/")
      
      if limit > 0 then
        env.out.print("Will run for " + limit.string() + " more generations")
        GenericGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .with_limit(env, SentimentDomain, SentimentGenomeOps, SentimentConfig, reporter, gen + limit)
      else
        GenericGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .create(env, SentimentDomain, SentimentGenomeOps, SentimentConfig, reporter)
      end
    | None =>
      env.out.print("No saved emotion models found, starting fresh training")
      _train(env)
    end
  
  fun _clear(env: Env) =>
    env.out.print("Clearing all saved emotion detection models...")
    let deleted = GenomePersistence.clear_all_generations(env, "sentiment/bin/")
    env.out.print("Deleted " + deleted.string() + " generation files")
  
  fun _analyze(env: Env, args: Array[String] val) =>
    if args.size() < 3 then
      env.out.print("Usage: sentiment analyze \"<text>\"")
      env.out.print("Example: sentiment analyze \"I'm feeling happy and excited!\"")
      return
    end
    
    try
      let text = args(2)?
      
      // Load the best trained model
      (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment/bin/")
      
      match genome
      | let g: Array[U8] val =>
        env.out.print("Analyzing text using model from generation " + gen.string())
        env.out.print("Text: \"" + text + "\"")
        env.out.print("")
        
        // Extract features and run analysis
        let features = SentimentDomain.extract_nrc_features(text)
        let predictions = SentimentDomain.forward_pass(g, features)
        
        // Display results
        let emotion_names: Array[String] = ["Anger"; "Anticipation"; "Disgust"; "Fear"; "Joy"; "Sadness"; "Surprise"; "Trust"; "Positive"; "Negative"]
        let emotion_colors: Array[String] = ["🔴"; "🟡"; "🟤"; "🟣"; "🟢"; "🔵"; "🟠"; "⭐"; "✅"; "❌"]
        
        env.out.print("Detected emotions:")
        for i in Range[USize](0, 10) do
          try
            let name = emotion_names(i)?
            let color = emotion_colors(i)?
            let confidence = predictions(i)?
            if confidence > 0.3 then  // Only show emotions above 30% confidence
              let bar = _create_bar(confidence)
              let conf_pct = (confidence * 100).f64().string()
              env.out.print("  " + color + " " + name + ": " + consume conf_pct + "% " + bar)
            end
          end
        end
        
        // Language detection
        let lower_text = text.lower()
        let words_iso = lower_text.split(" ")
        let words = recover val consume words_iso end
        let is_spanish = SentimentDomain.detect_spanish(words)
        env.out.print("")
        env.out.print("Detected language: " + if is_spanish then "Spanish 🇪🇸" else "English 🇺🇸" end)
        
      | None =>
        env.out.print("No trained emotion model found.")
        env.out.print("Run 'sentiment train' first to create a model.")
      end
    else
      env.out.print("Error: Could not process the provided text")
    end
  
  fun _test(env: Env, args: Array[String] val) =>
    env.out.print("Testing emotion detection with example sentences...")
    
    // Load the best trained model
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, "sentiment/bin/")
    
    match genome
    | let g: Array[U8] val =>
      env.out.print("Using model from generation " + gen.string())
      env.out.print(SentimentDomain.display_result(g))
    | None =>
      env.out.print("No trained emotion model found.")
      env.out.print("Run 'sentiment train' first to create a model.")
      env.out.print("")
      env.out.print("Meanwhile, here are some example emotions that would be detected:")
      env.out.print("🟢 Joy: \"I'm so happy!\" / \"¡Estoy tan feliz!\"")
      env.out.print("🔴 Anger: \"I'm furious!\" / \"¡Estoy furioso!\"") 
      env.out.print("🟣 Fear: \"I'm scared!\" / \"¡Tengo miedo!\"")
      env.out.print("🔵 Sadness: \"I feel sad.\" / \"Me siento triste.\"")
      env.out.print("🟠 Surprise: \"What a surprise!\" / \"¡Qué sorpresa!\"")
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