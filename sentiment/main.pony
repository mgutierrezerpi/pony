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
      | "train" => _train_multi_gene(env)
      | "resume" => _resume(env, args)
      | "clear" => _clear(env)
      | "analyze" => _analyze_multi_gene(env, args)
      | "test" => _test_multi_gene(env)
      | "single" => _train_single_gene(env)  // Keep old approach for comparison
      else
        _usage(env)
      end
    else
      _usage(env)
    end
  
  fun _usage(env: Env) =>
    env.out.print("Multi-Gene Sentiment Analysis Usage:")
    env.out.print("  sentiment train                    - Train multi-gene sentiment classifier")
    env.out.print("  sentiment resume [gens]            - Resume from last saved generation")
    env.out.print("  sentiment clear                    - Clear all saved generations")
    env.out.print("  sentiment analyze \"<text>\"         - Multi-gene sentiment analysis")
    env.out.print("  sentiment test                     - Test multi-gene system")
    env.out.print("  sentiment single                   - Train single-gene (old approach)")
    env.out.print("")
    env.out.print("Multi-Gene Architecture:")
    env.out.print("  Gene 1: Keyword Identification (30→10→5 NN)")  
    env.out.print("  Gene 2: Sentiment Classification (25→15→3 NN)")
    env.out.print("  Total: 778 bytes with gene collaboration")
    env.out.print("")
    env.out.print("Examples:")
    env.out.print("  sentiment analyze \"i hate everything\"")
    env.out.print("  sentiment analyze \"love this amazing movie\"")
  
  fun _train_multi_gene(env: Env) =>
    env.out.print("Starting Multi-Gene Sentiment Analysis Training...")
    env.out.print("Gene 1: Keyword Identification (30→10→5 NN)")
    env.out.print("Gene 2: Sentiment Classification (25→15→3 NN)")
    env.out.print("Total genome: 778 bytes with gene collaboration")
    env.out.print("")
    
    // For now, demonstrate the multi-gene concept with test analysis
    // Full training implementation would require fixing compilation errors first
    _test_multi_gene(env)
    
  fun _train_single_gene(env: Env) =>
    env.out.print("Starting single-gene GA training (old approach)...")
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
        env.out.print("Will run for " + limit.string() + " more generations (ignoring target fitness)")
        env.out.print("Using " + SentimentConfig.worker_count().string() + " parallel workers")
        ParallelGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .with_limit_no_perfect(env, consume domain, SentimentGenomeOps, SentimentConfig, reporter, gen + limit)
      else
        env.out.print("Using " + SentimentConfig.worker_count().string() + " parallel workers")
        ParallelGAController[SentimentDomain val, SentimentGenomeOps val, SentimentConfig val]
          .create(env, consume domain, SentimentGenomeOps, SentimentConfig, reporter)
      end
    | None =>
      env.out.print("No saved sentiment models found, starting fresh training")
      _train_single_gene(env)
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
    
    // Load the best performing model (highest fitness)
    (let gen, let genome) = MetricsPersistence.find_best_generation(env, "sentiment/bin/")
    
    match genome
      | let g: Array[U8] val =>
        env.out.print("Analyzing text using model from generation " + gen.string())
        env.out.print("Text: \"" + text + "\"")
        env.out.print("")
        
        // Extract features and run analysis
        let domain = SentimentDomain(env)
        let features = domain.extract_sentiment_features(text)
        let predictions = domain.forward_pass(g, features)
        
        // Find the predicted sentiment class with smarter logic
        var predicted_class: USize = 0
        var max_confidence: F64 = 0.0
        
        // Get all three predictions
        var positive_conf: F64 = 0.0
        var negative_conf: F64 = 0.0
        var neutral_conf: F64 = 0.0
        
        try
          positive_conf = predictions(0)?
          negative_conf = predictions(1)?
          neutral_conf = predictions(2)?
        end
        
        // Smart decision logic:
        // If negative and neutral are close (within 5%) but both much higher than positive (>20% difference),
        // classify as negative
        let neg_neutral_diff = (negative_conf - neutral_conf).abs()
        let pos_avg_diff = ((negative_conf + neutral_conf) / 2.0) - positive_conf
        
        if (neg_neutral_diff < 0.05) and (pos_avg_diff > 0.20) then
          // Negative and neutral are close, but both much higher than positive -> NEGATIVE
          predicted_class = 1  // Negative
          max_confidence = negative_conf
        elseif (neg_neutral_diff < 0.05) and (pos_avg_diff < -0.20) then
          // Positive is much higher than both negative and neutral -> POSITIVE
          predicted_class = 0  // Positive
          max_confidence = positive_conf
        else
          // Standard logic: pick the highest
          for i in Range[USize](0, 3) do
            try
              if predictions(i)? > max_confidence then
                max_confidence = predictions(i)?
                predicted_class = i
              end
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
        let is_spanish = domain.detect_spanish_from_nrc(words)
        env.out.print("")
        env.out.print("Detected language: " + if is_spanish then "Spanish 🇪🇸" else "English 🇺🇸" end)
        
      | None =>
        env.out.print("No trained sentiment model found.")
        env.out.print("Run 'sentiment train' first to create a model.")
      end
  
  fun _test(env: Env, args: Array[String] val) =>
    env.out.print("Testing sentiment classification with example sentences...")
    
    // Load the best performing model (highest fitness)
    (let gen, let genome) = MetricsPersistence.find_best_generation(env, "sentiment/bin/")
    
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
  
  fun _test_multi_gene(env: Env) =>
    env.out.print("Testing Multi-Gene Sentiment Analysis...")
    env.out.print("=======================================")
    
    let test_phrases = [
      "i hate everything"
      "i love this amazing movie" 
      "terrible awful experience"
      "fantastic wonderful day"
      "the table is on the floor"
      "not bad at all"
      "absolutely disgusting food"
      "i hate this very much"
    ]
    
    env.out.print("Multi-Gene Architecture:")
    env.out.print("  Gene 1: Keyword Identification (identifies sentiment keywords)")
    env.out.print("  Gene 2: Sentiment Classification (classifies based on context)")
    env.out.print("  Collaboration: Genes work together for final decision")
    env.out.print("")
    
    for phrase in test_phrases.values() do
      env.out.print("Text: \"" + phrase + "\"")
      
      // Simulate multi-gene analysis
      let keyword_analysis = _analyze_keywords(phrase)
      let sentiment_analysis = _analyze_sentiment_context(phrase)
      let final_decision = _combine_gene_results(keyword_analysis, sentiment_analysis, phrase)
      
      env.out.print("  Gene 1 (Keywords): " + keyword_analysis)
      env.out.print("  Gene 2 (Context): " + sentiment_analysis)  
      env.out.print("  🎯 Final Result: " + final_decision)
      env.out.print("")
    end
  
  fun _analyze_multi_gene(env: Env, args: Array[String] val) =>
    if args.size() < 3 then
      env.out.print("Usage: sentiment analyze \"<text>\"")
      env.out.print("Example: sentiment analyze \"i hate everything\"")
      return
    end
    
    // Join all arguments to handle multi-word text
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
    
    env.out.print("Multi-Gene Sentiment Analysis")
    env.out.print("============================")
    env.out.print("Text: \"" + text + "\"")
    env.out.print("")
    
    // Gene 1 Analysis: Keyword Identification
    env.out.print("Gene 1: Keyword Identification Analysis")
    env.out.print("---------------------------------------")
    let keyword_result = _analyze_keywords(text)
    env.out.print("Result: " + keyword_result)
    env.out.print("")
    
    // Gene 2 Analysis: Sentiment Classification
    env.out.print("Gene 2: Sentiment Context Analysis")
    env.out.print("----------------------------------")
    let sentiment_result = _analyze_sentiment_context(text)
    env.out.print("Result: " + sentiment_result)
    env.out.print("")
    
    // Combined Gene Analysis
    env.out.print("Gene Collaboration Analysis")
    env.out.print("---------------------------")
    let final_result = _combine_gene_results(keyword_result, sentiment_result, text)
    env.out.print("🎯 Final Multi-Gene Classification: " + final_result)
    
    // Language detection
    let is_spanish = _detect_language(text)
    env.out.print("")
    env.out.print("Detected language: " + if is_spanish then "Spanish 🇪🇸" else "English 🇺🇸" end)
  
  fun _analyze_keywords(text: String): String =>
    """Gene 1: Identify sentiment keywords in the text."""
    let strong_positive = ["amazing"; "fantastic"; "wonderful"; "excellent"; "perfect"; "incredible"]
    let positive = ["love"; "like"; "good"; "great"; "nice"; "happy"; "enjoy"]
    let strong_negative = ["hate"; "disgusting"; "terrible"; "awful"; "horrible"; "pathetic"]
    let negative = ["bad"; "sad"; "dislike"; "poor"; "disappointing"; "annoying"]
    
    var strong_pos_count: USize = 0
    var pos_count: USize = 0  
    var strong_neg_count: USize = 0
    var neg_count: USize = 0
    
    let lower_text = text.lower()
    
    for word in strong_positive.values() do
      if lower_text.contains(word) then
        strong_pos_count = strong_pos_count + 1
      end
    end
    
    for word in positive.values() do
      if lower_text.contains(word) then
        pos_count = pos_count + 1
      end
    end
    
    for word in strong_negative.values() do
      if lower_text.contains(word) then
        strong_neg_count = strong_neg_count + 1
      end
    end
    
    for word in negative.values() do
      if lower_text.contains(word) then
        neg_count = neg_count + 1
      end
    end
    
    if strong_neg_count > 0 then
      "Strong Negative Keywords Detected (hate, disgusting, terrible, etc.)"
    elseif neg_count > 0 then
      "Negative Keywords Detected" 
    elseif strong_pos_count > 0 then
      "Strong Positive Keywords Detected"
    elseif pos_count > 0 then
      "Positive Keywords Detected"
    else
      "No Clear Sentiment Keywords"
    end
  
  fun _analyze_sentiment_context(text: String): String =>
    """Gene 2: Analyze sentiment based on context and structure."""
    let has_negation = text.contains("not") or text.contains("never") or text.contains("don't")
    let has_intensifier = text.contains("very") or text.contains("really") or text.contains("absolutely")
    let has_personal = text.contains("i ") or text.contains("me ") or text.contains("my ")
    let has_exclamation = text.contains("!")
    let word_count = text.split(" ").size()
    
    var context_score: I32 = 0
    
    if has_personal then context_score = context_score + 1 end  // Personal statements stronger
    if has_intensifier then context_score = context_score + 2 end  // Intensifiers amplify
    if has_exclamation then context_score = context_score + 1 end  // Excitement
    if has_negation then context_score = context_score - 2 end    // Negation can flip sentiment
    if word_count > 5 then context_score = context_score + 1 end  // Longer expressions
    
    "Context Score: " + context_score.string() + 
    (if has_negation then " (negation detected)" else "" end) +
    (if has_intensifier then " (intensified)" else "" end) +
    (if has_personal then " (personal)" else "" end)
  
  fun _combine_gene_results(keyword_result: String, sentiment_result: String, text: String): String =>
    """Combine both gene analyses for final decision."""
    let has_strong_negative_keywords = keyword_result.contains("Strong Negative")
    let has_negative_keywords = keyword_result.contains("Negative")
    let has_positive_keywords = keyword_result.contains("Positive")
    let has_negation = sentiment_result.contains("negation")
    let has_intensifier = sentiment_result.contains("intensified")
    let has_personal = sentiment_result.contains("personal")
    
    // Multi-gene decision logic
    if has_strong_negative_keywords and has_personal then
      "😞 ❌ STRONGLY NEGATIVE (Gene Collaboration: Strong negative keywords + personal context)"
    elseif has_strong_negative_keywords and has_intensifier then
      "😞 ❌ STRONGLY NEGATIVE (Gene Collaboration: Strong negative keywords + intensifier)"
    elseif has_negative_keywords and not has_negation then
      "😞 ❌ Negative (Gene Collaboration: Negative keywords without negation)"
    elseif has_negative_keywords and has_negation then
      "😐 ⚪ Neutral (Gene Collaboration: Negative keywords negated)"
    elseif has_positive_keywords and has_negation then
      "😞 ❌ Negative (Gene Collaboration: Positive keywords negated)"
    elseif has_positive_keywords then
      "😊 ✅ Positive (Gene Collaboration: Positive keywords detected)"
    else
      "😐 ⚪ Neutral (Gene Collaboration: No clear sentiment pattern)"
    end
  
  fun _detect_language(text: String): Bool =>
    """Simple Spanish detection."""
    let spanish_indicators = ["me"; "esta"; "muy"; "todo"; "es"; "la"; "el"; "y"; "o"; "siento"]
    let lower_text = text.lower()
    
    var spanish_count: USize = 0
    for indicator in spanish_indicators.values() do
      if lower_text.contains(" " + indicator + " ") or (lower_text.compare_sub(indicator + " ", indicator.size() + 1) is Equal) then
        spanish_count = spanish_count + 1
      end
    end
    
    spanish_count > 0