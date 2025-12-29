// RESTful web server for genetic algorithm models
// Exposes endpoints for different trained models (sentiment analysis, etc.)

use "net"
use "collections"
use "../sentiment_analysis/core"
use "../../packages/_framework"
use "files"

actor Main
  new create(env: Env) =>
    let auth = TCPListenAuth(env.root)

    // Load configuration from environment variables with fallback to defaults
    let host = _get_env_var(env, "HOST", "127.0.0.1")
    let port = _get_env_var(env, "PORT", "8080")
    let english_lex_path = _get_env_var(env, "ENGLISH_LEXICON", "apps/sentiment_analysis/data/English-NRC-EmoLex.txt")
    let spanish_lex_path = _get_env_var(env, "SPANISH_LEXICON", "apps/sentiment_analysis/data/Spanish-NRC-EmoLex.txt")
    let model_path = _get_env_var(env, "MODEL_PATH", "apps/sentiment_analysis/bin/")

    env.out.print("=== Configuration ===")
    env.out.print("Host: " + host)
    env.out.print("Port: " + port)
    env.out.print("Model: " + model_path)
    env.out.print("")

    // Load sentiment resources
    let english_lex = NRCLexiconLoader.load_lexicon(env, english_lex_path)
    let spanish_lex = NRCLexiconLoader.load_lexicon(env, spanish_lex_path)
    (let gen, let genome) = GenomePersistence.find_latest_generation(env, model_path)

    match genome
    | let g: Array[U8] val =>
      env.out.print("✓ Loaded sentiment analysis model (generation " + gen.string() + ")")
    | None =>
      env.out.print("⚠ Warning: No trained sentiment model found at " + model_path)
    end

    TCPListener(auth, recover iso WebServer(env, genome, english_lex, spanish_lex) end, host, port)
    env.out.print("")
    env.out.print("🚀 Web server started on http://" + host + ":" + port)
    env.out.print("")
    env.out.print("Available endpoints:")
    env.out.print("  POST /sentiment_analysis - Analyze sentiment of text")
    env.out.print("  GET  /health            - Health check")
    env.out.print("")

  fun _get_env_var(e: Env, name: String, default: String): String =>
    """
    Get environment variable by name, with fallback to default value.
    Searches through env.vars array for NAME=VALUE format.
    """
    for v in e.vars.values() do
      try
        let eq_pos = v.find("=")?
        let var_name = v.substring(0, eq_pos)
        if var_name == name then
          return v.substring(eq_pos + 1)
        end
      end
    end
    default

class WebServer is TCPListenNotify
  let _env: Env
  let _sentiment_genome: (Array[U8] val | None)
  let _english_lex: Map[String, (Bool, Bool)] val
  let _spanish_lex: Map[String, (Bool, Bool)] val

  new iso create(
    env: Env,
    sentiment_genome: (Array[U8] val | None),
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val) =>
    _env = env
    _sentiment_genome = sentiment_genome
    _english_lex = english_lex
    _spanish_lex = spanish_lex

  fun ref listening(listen: TCPListener ref) =>
    None

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("Failed to listen on port 8080")

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    HTTPConnection(_env, _sentiment_genome, _english_lex, _spanish_lex)

class HTTPConnection is TCPConnectionNotify
  let _env: Env
  let _sentiment_genome: (Array[U8] val | None)
  let _english_lex: Map[String, (Bool, Bool)] val
  let _spanish_lex: Map[String, (Bool, Bool)] val
  var _request_buffer: String ref

  new iso create(
    env: Env,
    sentiment_genome: (Array[U8] val | None),
    english_lex: Map[String, (Bool, Bool)] val,
    spanish_lex: Map[String, (Bool, Bool)] val) =>
    _env = env
    _sentiment_genome = sentiment_genome
    _english_lex = english_lex
    _spanish_lex = spanish_lex
    _request_buffer = String

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    """
    Process incoming HTTP request data.
    """
    _request_buffer.append(consume data)

    // Check if we have a complete HTTP request (ends with \r\n\r\n)
    if _request_buffer.contains("\r\n\r\n") then
      let request = _request_buffer.clone()
      _request_buffer = String
      _handle_request(conn, consume request)
    end
    true

  fun ref _handle_request(conn: TCPConnection ref, request: String) =>
    """
    Parse and route HTTP request to appropriate handler.
    """
    let lines_iso = request.split("\r\n")
    let lines = recover val consume lines_iso end

    if lines.size() == 0 then
      _send_response(conn, 400, "Bad Request", "Invalid HTTP request")
      return
    end

    try
      let request_line = lines(0)?
      let parts_iso = request_line.split(" ")
      let parts = recover val consume parts_iso end

      if parts.size() < 2 then
        _send_response(conn, 400, "Bad Request", "Invalid request line")
        return
      end

      let method = parts(0)?
      let path = parts(1)?

      // Extract request body (after headers)
      var body = recover val String end
      var in_body = false
      for line in lines.values() do
        if in_body then
          body = body + line + "\n"
        elseif line.size() == 0 then
          in_body = true
        end
      end

      // Route to appropriate handler
      match (method, path)
      | ("POST", "/sentiment_analysis") =>
        _handle_sentiment_analysis(conn, consume body)
      | ("GET", "/") =>
        _handle_root(conn)
      | ("GET", "/health") =>
        _send_json_response(conn, 200, "{\"status\": \"ok\"}")
      else
        _send_response(conn, 404, "Not Found", "Endpoint not found")
      end
    else
      _send_response(conn, 400, "Bad Request", "Failed to parse request")
    end

  fun ref _handle_root(conn: TCPConnection ref) =>
    """
    Root endpoint - show available endpoints.
    """
    let response =
      """
      Genetic Algorithm Web API

      Available endpoints:
        POST /sentiment_analysis - Analyze sentiment of text
        GET  /health            - Health check
      """
    _send_response(conn, 200, "OK", response)

  fun ref _handle_sentiment_analysis(conn: TCPConnection ref, body: String val) =>
    """
    POST /sentiment_analysis
    Body: {"text": "your text here"}
    Response: {"sentiment": "Positive", "confidence": 0.85, "scores": {...}}
    """
    // Debug: log the body
    _env.out.print("Received body: [" + body + "]")

    match _sentiment_genome
    | let genome: Array[U8] val =>
      // Simple JSON parsing (extract text field)
      let text = _extract_json_field(body, "text")

      _env.out.print("Extracted text: [" + text + "]")

      if text.size() == 0 then
        _send_json_response(conn, 400, "{\"error\": \"Missing 'text' field\"}")
        return
      end

      // Perform sentiment analysis
      let features = FeatureExtractor.extract(text, _english_lex, _spanish_lex)
      let predicted = WeightedClassifier.classify(genome, features)
      (let pos_score, let neg_score) = WeightedClassifier.get_scores(genome, features)

      let class_names: Array[String] val = ["Positive"; "Negative"]

      try
        let sentiment = class_names(predicted)?
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

        // Build JSON response
        let response = recover val
          let s = String
          s.append("{\"sentiment\": \"")
          s.append(sentiment)
          s.append("\",\"confidence\": ")
          s.append(confidence.string())
          s.append(",\"scores\": {\"positive\": ")
          s.append(pos_score.string())
          s.append(",\"negative\": ")
          s.append(neg_score.string())
          s.append("}}")
          s
        end

        _send_json_response(conn, 200, consume response)
      else
        _send_json_response(conn, 500, "{\"error\": \"Classification failed\"}")
      end
    | None =>
      _send_json_response(conn, 503, "{\"error\": \"Model not loaded\"}")
    end

  fun _extract_json_field(json: String box, field: String): String val =>
    """
    Simple JSON field extraction (not a full parser).
    Looks for "field":"value" or "field": "value"
    """
    recover val
      // Try with space first
      let search_space = recover val "\"" + field + "\": \"" end
      try
        let start_pos = json.find(consume search_space)?
        let value_start = start_pos + field.size().isize() + 5  // "": "
        let remaining = json.substring(value_start)
        let end_pos = remaining.find("\"")?
        return remaining.substring(0, end_pos)
      end

      // Try without space
      let search_no_space = recover val "\"" + field + "\":\"" end
      try
        let start_pos = json.find(consume search_no_space)?
        let value_start = start_pos + field.size().isize() + 4  // "":"
        let remaining = json.substring(value_start)
        let end_pos = remaining.find("\"")?
        remaining.substring(0, end_pos)
      else
        String
      end
    end

  fun ref _send_response(conn: TCPConnection ref, status: U16, status_text: String, body: String) =>
    """
    Send HTTP response with text/plain content type.
    """
    let response = recover val
      let s = String
      s.append("HTTP/1.1 ")
      s.append(status.string())
      s.append(" ")
      s.append(status_text)
      s.append("\r\nContent-Type: text/plain\r\nContent-Length: ")
      s.append(body.size().string())
      s.append("\r\nConnection: close\r\n\r\n")
      s.append(body)
      s
    end
    conn.write(response.array())
    conn.dispose()

  fun ref _send_json_response(conn: TCPConnection ref, status: U16, json: String val) =>
    """
    Send HTTP response with application/json content type.
    """
    let status_text = if status == 200 then "OK"
      elseif status == 400 then "Bad Request"
      elseif status == 404 then "Not Found"
      elseif status == 500 then "Internal Server Error"
      elseif status == 503 then "Service Unavailable"
      else "Unknown"
      end

    let response = recover val
      let s = String
      s.append("HTTP/1.1 ")
      s.append(status.string())
      s.append(" ")
      s.append(status_text)
      s.append("\r\nContent-Type: application/json\r\nContent-Length: ")
      s.append(json.size().string())
      s.append("\r\nConnection: close\r\n\r\n")
      s.append(json)
      s
    end
    conn.write(response.array())
    conn.dispose()

  fun ref closed(conn: TCPConnection ref) =>
    None

  fun ref connect_failed(conn: TCPConnection ref) =>
    None
