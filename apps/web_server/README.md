# Web Server

RESTful API server for genetic algorithm models built with Pony's native `net` library.

## Features

- **Zero external dependencies** - Uses only Pony's built-in `net` package
- **RESTful JSON API** - Clean HTTP endpoints with JSON request/response
- **Concurrent** - Leverages Pony's actor model for handling multiple connections
- **Production-ready** - Environment variable configuration for deployment

## Configuration

The server is configured via environment variables with sensible defaults for development:

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `127.0.0.1` | Server bind address (use `0.0.0.0` for production) |
| `PORT` | `8080` | Server port |
| `MODEL_PATH` | `sentiment_analysis/bin/` | Path to trained model directory |
| `ENGLISH_LEXICON` | `sentiment_analysis/data/English-NRC-EmoLex.txt` | English emotion lexicon path |
| `SPANISH_LEXICON` | `sentiment_analysis/data/Spanish-NRC-EmoLex.txt` | Spanish emotion lexicon path |

## Quick Start

### Development

```bash
# Compile
../pony compile web_server

# Run with defaults (localhost:8080)
./bin/web_server
```

### Production

```bash
# Set production environment
export HOST=0.0.0.0
export PORT=3000
export MODEL_PATH=/app/models/sentiment_analysis/bin/

# Run
./bin/web_server
```

Or use an `.env` file:

```bash
# Copy example
cp .env.example .env

# Edit configuration
vim .env

# Run with environment loader (using direnv, dotenv, etc.)
./bin/web_server
```

## API Endpoints

### Health Check

```bash
GET /health
```

**Response:**
```json
{
  "status": "ok"
}
```

### Sentiment Analysis

```bash
POST /sentiment_analysis
Content-Type: application/json

{
  "text": "This movie is absolutely fantastic!"
}
```

**Response:**
```json
{
  "sentiment": "Positive",
  "confidence": 0.85,
  "scores": {
    "positive": 0.85,
    "negative": 0.10,
    "neutral": 0.05
  }
}
```

**Supported Languages:** English and Spanish

## Examples

### Using curl

```bash
# Health check
curl http://localhost:8080/health

# Analyze English text
curl -X POST http://localhost:8080/sentiment_analysis \
  -H "Content-Type: application/json" \
  -d '{"text":"This product is amazing!"}'

# Analyze Spanish text
curl -X POST http://localhost:8080/sentiment_analysis \
  -H "Content-Type: application/json" \
  -d '{"text":"Esta película es horrible"}'
```

### Using httpie

```bash
# Health check
http localhost:8080/health

# Analyze sentiment
http POST localhost:8080/sentiment_analysis text="I love this!"
```

## Deployment

### Docker Example

```dockerfile
FROM ponylang/ponyc:latest

WORKDIR /app
COPY . .

# Compile
RUN ponyc web_server

# Run
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

CMD ["./web_server/bin/web_server"]
```

### systemd Service

```ini
[Unit]
Description=Pony Web Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/pony
Environment="HOST=0.0.0.0"
Environment="PORT=8080"
Environment="MODEL_PATH=/opt/pony/sentiment_analysis/bin/"
ExecStart=/opt/pony/web_server/bin/web_server
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Development

### Add Debug Logging

The server includes debug output for request bodies. To disable for production, remove the `_env.out.print()` calls in `_handle_sentiment_analysis`.

### Add New Endpoints

1. Add route in `_handle_request`:
```pony
| ("GET", "/new-endpoint") =>
  _handle_new_endpoint(conn)
```

2. Implement handler:
```pony
fun ref _handle_new_endpoint(conn: TCPConnection ref) =>
  _send_json_response(conn, 200, "{\"message\": \"Hello\"}")
```

## Performance

The server uses Pony's actor-based concurrency model:
- Each connection is handled by an isolated `HTTPConnection` actor
- No shared mutable state between connections
- Zero-copy message passing
- Automatic parallelization across CPU cores

## License

Same as parent project.
