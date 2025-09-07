// NRC Emotion Lexicon word lists for multilingual emotion detection
// Based on the NRC Emotion Lexicon by Saif Mohammad and Peter Turney

primitive NRCLexicon
  """
  Contains curated word lists from the NRC Emotion Lexicon.
  These are the most common emotion-bearing words for each category.
  """
  
  fun anger_words(): Array[String] val =>
    """English and Spanish words associated with ANGER"""
    recover val
      ["angry"; "mad"; "furious"; "rage"; "wrath"; "fury"; "anger"; "hostile"; "irritated"; "enraged"; "outraged"; "livid"; "irate"; "annoyed"; "aggravated"; "bitter"; "resentful"; "enojado"; "furioso"; "ira"; "rabia"; "cólera"; "enfadado"; "molesto"; "irritado"; "indignado"; "airado"; "colérico"; "sañudo"; "rencoroso"; "hostil"; "agresivo"]
    end
  
  fun anticipation_words(): Array[String] val =>
    """English and Spanish words associated with ANTICIPATION"""
    recover val
      ["excited"; "expect"; "hope"; "eager"; "anticipate"; "await"; "ready"; "prepared"; "optimistic"; "hopeful"; "expectant"; "enthusiastic"; "keen"; "anxious"; "impatient"; "esperar"; "emocionado"; "ansioso"; "expectante"; "esperanza"; "ilusión"; "ganas"; "preparado"; "listo"; "optimista"; "entusiasmado"; "impaciente"; "deseoso"]
    end
    
  fun disgust_words(): Array[String] val =>
    """English and Spanish words associated with DISGUST"""
    recover val
      ["disgusting"; "gross"; "revolting"; "sick"; "nausea"; "repulsive"; "vile"; "loathsome"; "abhorrent"; "repugnant"; "offensive"; "foul"; "hideous"; "appalling"; "horrible"; "asqueroso"; "repugnante"; "asco"; "náusea"; "asqueante"; "repulsivo"; "vil"; "odioso"; "abominable"; "horrible"; "desagradable"; "repelente"; "inmundo"]
    end
    
  fun fear_words(): Array[String] val =>
    """English and Spanish words associated with FEAR"""
    recover val
      ["afraid"; "scared"; "terrified"; "fear"; "terror"; "panic"; "frightened"; "anxious"; "worried"; "nervous"; "alarmed"; "apprehensive"; "dread"; "phobia"; "timid"; "miedo"; "asustado"; "temor"; "terror"; "pánico"; "aterrorizado"; "espantado"; "preocupado"; "nervioso"; "alarmado"; "temeroso"; "aprensivo"; "cobarde"; "tímido"]
    end
    
  fun joy_words(): Array[String] val =>
    """English and Spanish words associated with JOY"""
    recover val
      ["happy"; "joy"; "cheerful"; "glad"; "delighted"; "pleased"; "content"; "elated"; "euphoric"; "ecstatic"; "blissful"; "merry"; "jovial"; "upbeat"; "joyful"; "feliz"; "alegre"; "contento"; "gozo"; "alegría"; "dichoso"; "gozoso"; "radiante"; "eufórico"; "extático"; "jubiloso"; "regocijado"; "satisfecho"; "complacido"]
    end
    
  fun sadness_words(): Array[String] val =>
    """English and Spanish words associated with SADNESS"""
    recover val
      ["sad"; "depressed"; "unhappy"; "sorrow"; "grief"; "melancholy"; "gloomy"; "down"; "blue"; "dejected"; "miserable"; "heartbroken"; "mournful"; "sorrowful"; "glum"; "triste"; "deprimido"; "infeliz"; "melancolía"; "pena"; "dolor"; "luto"; "tristeza"; "desconsolado"; "abatido"; "afligido"; "pesaroso"; "doliente"; "apenado"]
    end
    
  fun surprise_words(): Array[String] val =>
    """English and Spanish words associated with SURPRISE"""
    recover val
      ["surprised"; "amazed"; "shocked"; "astonished"; "astounded"; "stunned"; "startled"; "bewildered"; "dumbfounded"; "flabbergasted"; "wonder"; "awe"; "marvel"; "unexpected"; "sorprendido"; "asombrado"; "sorpresa"; "asombro"; "estupefacto"; "pasmado"; "admirado"; "maravillado"; "atónito"; "boquiabierto"; "inesperado"; "imprevisto"]
    end
    
  fun trust_words(): Array[String] val =>
    """English and Spanish words associated with TRUST"""
    recover val
      ["trust"; "faith"; "confidence"; "reliable"; "dependable"; "honest"; "loyal"; "faithful"; "trustworthy"; "credible"; "secure"; "assured"; "belief"; "conviction"; "confianza"; "fe"; "seguridad"; "confiable"; "fiable"; "honesto"; "leal"; "fiel"; "creíble"; "seguro"; "convencido"; "creencia"; "convicción"; "esperanza"]
    end
    
  fun positive_words(): Array[String] val =>
    """English and Spanish words associated with POSITIVE sentiment"""
    recover val
      ["good"; "great"; "amazing"; "wonderful"; "excellent"; "fantastic"; "awesome"; "love"; "best"; "perfect"; "beautiful"; "brilliant"; "outstanding"; "superb"; "magnificent"; "bueno"; "genial"; "increíble"; "maravilloso"; "excelente"; "fantástico"; "amor"; "mejor"; "perfecto"; "hermoso"; "brillante"; "magnífico"; "estupendo"; "extraordinario"]
    end
    
  fun negative_words(): Array[String] val =>
    """English and Spanish words associated with NEGATIVE sentiment"""
    recover val
      ["bad"; "terrible"; "awful"; "hate"; "worst"; "horrible"; "disgusting"; "pathetic"; "useless"; "disaster"; "failure"; "nightmare"; "rubbish"; "trash"; "garbage"; "malo"; "terrible"; "horrible"; "odio"; "peor"; "pésimo"; "desastre"; "fracaso"; "basura"; "inútil"; "patético"; "deplorable"; "lamentable"; "espantoso"]
    end
  
  fun get_emotion_words(emotion_idx: USize): Array[String] val =>
    """Get word list for a specific emotion index"""
    match emotion_idx
    | 0 => anger_words()
    | 1 => anticipation_words()
    | 2 => disgust_words()
    | 3 => fear_words()
    | 4 => joy_words()
    | 5 => sadness_words()
    | 6 => surprise_words()
    | 7 => trust_words()
    | 8 => positive_words()
    | 9 => negative_words()
    else
      recover val Array[String](0) end
    end