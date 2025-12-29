// CSV parser for IMDB movie review dataset
// Format: review,sentiment (positive/negative)

use "files"
use "collections"

primitive IMDBDatasetLoader
  """
  Loads IMDB movie review dataset from CSV file.

  File format:
  review,sentiment
  "text of review",positive
  "text of review",negative

  Returns array of (text, class) tuples where:
  - class 0 = positive
  - class 1 = negative
  """

  fun load_imdb_dataset(env: Env, file_path: String, max_samples: USize = 0): Array[(String, USize)] val =>
    """
    Load IMDB dataset from CSV file.

    Parameters:
    - env: Environment for file access
    - file_path: Path to CSV file
    - max_samples: Maximum number of samples to load (0 = load all)

    Returns array of (review_text, sentiment_class) tuples
    """
    recover val
      let dataset = Array[(String, USize)]

      try
        let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
        let path = FilePath(FileAuth(env.root), file_path, caps)
        let file = OpenFile(path) as File

        var line_num: USize = 0
        var loaded: USize = 0

        for line in file.lines() do
          line_num = line_num + 1

          // Skip header line
          if line_num == 1 then
            continue
          end

          // Check if we've hit max samples
          if (max_samples > 0) and (loaded >= max_samples) then
            break
          end

          // Parse CSV line: "review text",sentiment
          let parsed = _parse_csv_line(consume line)

          match parsed
          | (let review: String, let sentiment: USize) =>
            dataset.push((review, sentiment))
            loaded = loaded + 1
          end
        end
      end

      dataset
    end

  fun _parse_csv_line(line: String iso): ((String, USize) | None) =>
    """
    Parse a single CSV line.
    Expected format: "review text",sentiment

    Returns (review, class) or None if parse fails
    """
    let line_val: String val = recover val consume line end

    // Find last comma (separates review from sentiment)
    var last_comma: (USize | None) = None
    var pos: USize = 0

    for char in line_val.values() do
      if char == ',' then
        last_comma = pos
      end
      pos = pos + 1
    end

    match last_comma
    | let comma_pos: USize =>
      // Extract review (remove quotes if present)
      var review = line_val.substring(0, comma_pos.isize())
      review = _unquote(consume review)

      // Extract sentiment label
      var sentiment_str = line_val.substring((comma_pos + 1).isize())
      sentiment_str.strip()

      // Convert sentiment string to class number
      let sentiment_class: USize = if sentiment_str == "positive" then
        0
      elseif sentiment_str == "negative" then
        1
      else
        return None  // Unknown sentiment
      end

      (consume review, sentiment_class)
    else
      None
    end

  fun _unquote(s: String iso): String iso^ =>
    """
    Remove surrounding quotes from string if present.
    """
    var result = consume s
    result.strip()

    // Remove leading quote
    if result.at("\"", 0) then
      result = result.substring(1)
    end

    // Remove trailing quote
    if result.size() > 0 then
      if result.at("\"", (result.size() - 1).isize()) then
        result = result.substring(0, (result.size() - 1).isize())
      end
    end

    consume result
