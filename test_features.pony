// Quick test to see what features are extracted
use "sentiment_analysis/core"
use "collections"

actor Main
  new create(env: Env) =>
    // Load lexicons
    let english_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/English-NRC-EmoLex.txt")
    let spanish_lex = NRCLexiconLoader.load_lexicon(env, "sentiment_analysis/data/Spanish-NRC-EmoLex.txt")

    // Test texts
    let tests = [
      ("awful", "should be negative")
      ("wonderful", "should be positive")
      ("This is terrible", "should be negative")
      ("I love this", "should be positive")
    ]

    for test in tests.values() do
      (let text, let expected) = test
      let features = FeatureExtractor.extract(text, english_lex, spanish_lex)

      env.out.print("\n" + text + " (" + expected + "):")
      env.out.print("  Feature[0] (pos_count): " + try features(0)?.string() else "?" end)
      env.out.print("  Feature[1] (neg_count): " + try features(1)?.string() else "?" end)
      env.out.print("  Feature[2] (neutral_count): " + try features(2)?.string() else "?" end)
    end
