# Pony Genetic Algorithm Framework

A monorepo-style repository containing a reusable genetic algorithm framework and example applications, all written in the [Pony programming language](https://www.ponylang.io/).

## Repository Structure

```
pony/
├── packages/              # Reusable framework code
│   └── _framework/        # Core GA framework
├── apps/                  # Applications
│   ├── powers_of_two/     # Evolve VM programs to compute powers of 2
│   ├── sentiment_analysis/# Sentiment classification using evolved weights
│   └── web_server/        # REST API for trained models
├── pony                   # Build/run script
├── README.md
└── CLAUDE.md             # Detailed documentation for AI assistants
```

## Quick Start

### 1. Install Pony Compiler

```bash
brew install ponyc
```

### 2. Make Build Script Executable

```bash
chmod +x pony
```

### 3. Try an Example

```bash
# Train a model to compute powers of 2
./pony compile powers_of_two
./pony run powers_of_two train

# Test the trained model
./pony run powers_of_two 5
# Output: 2^5 = 32 ✓ Correct!

# Analyze sentiment of text
./pony compile sentiment_analysis
./pony run sentiment_analysis analyze "I love this movie"
# Output: Sentiment: Positive, Confidence: 56.4%
```

## Usage

Use the `./pony` script for all operations:

```bash
# Compile a project
./pony compile <project_name>

# Run a project
./pony run <project_name> [args...]

# Run tests
./pony test <project_name>

# Show help
./pony help
```

## Applications

### Powers of Two (`apps/powers_of_two/`)

Evolves VM programs to compute powers of 2 using genetic algorithms.

**Features:**
- Virtual machine with 4 registers and 12 opcodes
- Genome = 16 instructions × 3 bytes = 48 bytes
- Achieves 100% fitness in ~600 generations
- Can compute any power of 2 (2^0 to 2^n)

**Commands:**
```bash
./pony run powers_of_two train              # Train from scratch
./pony run powers_of_two 5                  # Compute 2^5
./pony run powers_of_two resume 100         # Resume training for 100 more generations
./pony run powers_of_two disassemble        # Show VM instructions
./pony run powers_of_two clear              # Clear saved models
```

**Example Output:**
```
gen=596 best=0.833333 avg=0.220681
gen=600 best=1 avg=0.325516
PERFECT! Achieved fitness 1 at generation 600
```

### Sentiment Analysis (`apps/sentiment_analysis/`)

Multilingual sentiment classification using evolved feature weights.

**Features:**
- 50-feature extraction from text (NRC emotion lexicon)
- Weighted voting classifier (50 weights)
- Supports English and Spanish
- Trained on IMDB dataset (50,000 movie reviews)
- Binary classification: Positive/Negative

**Commands:**
```bash
./pony run sentiment_analysis train                    # Train from scratch
./pony run sentiment_analysis analyze "I love this"    # Analyze sentiment
./pony run sentiment_analysis test                     # Test with examples
./pony run sentiment_analysis clear                    # Clear saved models
```

**Example Output:**
```
Text: "I love this movie"
Sentiment: Positive
Confidence: 56.4%
Detailed scores:
  Positive: 0.445343
  Negative: 0.343922
```

### Web Server (`apps/web_server/`)

REST API server for trained sentiment analysis models.

**Features:**
- HTTP server exposing trained models via REST API
- JSON request/response format
- Configurable via environment variables
- Health check endpoint

**Commands:**
```bash
./pony run web_server                           # Run on localhost:8080
HOST=0.0.0.0 PORT=3000 ./pony run web_server  # Custom host/port
```

**Environment Variables:**
- `HOST` - Server host (default: `127.0.0.1`)
- `PORT` - Server port (default: `8080`)
- `ENGLISH_LEXICON` - Path to English NRC lexicon
- `SPANISH_LEXICON` - Path to Spanish NRC lexicon
- `MODEL_PATH` - Path to trained model

**API Endpoints:**

```bash
# Health check
GET /health
Response: {"status": "ok"}

# Sentiment analysis
POST /sentiment_analysis
Body: {"text": "I love this movie"}
Response: {
  "sentiment": "Positive",
  "confidence": 60.3,
  "scores": {
    "positive": 0.537725,
    "negative": 0.353529
  }
}
```

**Example Usage:**
```bash
# Start server
./pony run web_server

# Test API
curl -X POST http://127.0.0.1:8080/sentiment_analysis \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this wonderful movie"}'
```

## Genetic Algorithm Framework

The `packages/_framework/` directory contains reusable GA components:

- **Core Traits**: `ProblemDomain`, `GenomeOperations`, `GAConfiguration`
- **Evolution Engine**: `GAController` with tournament selection
- **Persistence**: Binary genome storage (`.bytes` files)
- **Reporting**: Progress tracking and logging
- **Operators Library**: Reusable mutations, classifiers, decoders

### Key Concepts

1. **Genome**: Fixed-size byte array representing a solution
2. **Fitness**: Evaluation score (0.0 to 1.0) measuring solution quality
3. **Selection**: Tournament selection chooses best performers
4. **Mutation**: Random modifications for exploration
5. **Crossover**: Combines two parent genomes
6. **Elitism**: Preserves best solutions across generations

### Adding a New GA Problem

1. Create project in `apps/your_project/`
2. Implement the domain:
   ```pony
   use "../../packages/_framework"

   primitive YourDomain is ProblemDomain
     fun genome_size(): USize => 100  // Your genome size
     fun evaluate(genome: Array[U8] val): F64 => /* fitness calculation */
     fun random_genome(rng: Rand): Array[U8] val => /* random initialization */
   ```
3. Implement genetic operators:
   ```pony
   primitive YourOperations is GenomeOperations
     fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val => /* mutation */
     fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) => /* crossover */
   ```
4. Configure GA parameters:
   ```pony
   primitive YourConfig is GAConfiguration
     fun population_size(): USize => 100
     fun tournament_size(): USize => 5
     fun mutation_rate(): F64 => 0.1
   ```

See `CLAUDE.md` for detailed framework documentation.

## Requirements

- **Pony compiler**: 0.59.0 or later
- **Operating System**: macOS or Linux
- **Memory**: 2GB+ recommended for training
- **Disk Space**: ~100MB for IMDB dataset

## Project Files

Each application follows this structure:
```
apps/project_name/
├── main.pony           # Entry point with CLI commands
├── core/               # Domain-specific implementations
│   └── *.pony         # Problem domain, operators, etc.
├── data/              # Training data (if needed)
├── bin/               # Compiled binary and saved models
│   ├── project_name   # Executable
│   └── gen_*.bytes    # Saved genome files
└── README.md          # Project-specific docs
```

## Performance Notes

- **Powers of Two**: Trains to 100% fitness in ~15 seconds (600 generations)
- **Sentiment Analysis**: Achieves ~84% accuracy with sufficient training
- **Actor Model**: Parallel fitness evaluation using Pony's lightweight actors
- **Persistence**: Genomes auto-saved every generation for resume capability

## Future Improvements

### Advanced Fine-tuning Capabilities

The genetic algorithm framework could be enhanced with:

1. **Seed Genome Support**
   - Start evolution from pre-trained genomes
   - Enable transfer learning between tasks
   - Domain adaptation and specialized fine-tuning

2. **Learning Rate Decay**
   - Adaptive mutation schedules
   - Automatic mutation rate reduction as solutions converge
   - Balance exploration vs exploitation

3. **Adaptive Parameters**
   - Auto-adjust GA configuration based on convergence
   - Dynamic population sizing based on diversity
   - Adaptive tournament selection pressure

4. **Domain Transfer**
   - Use trained genomes to initialize related problems
   - Partial genome freezing (preserve some weights)
   - Multi-stage training strategies
   - Cross-domain knowledge transfer

## Contributing

This is a research/educational project demonstrating genetic algorithms in Pony. See `CLAUDE.md` for detailed architecture and implementation notes.

## License

See individual project files for licensing information.
