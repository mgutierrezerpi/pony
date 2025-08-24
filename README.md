# Pony Projects

This repository contains Pony programming language projects and a custom build/run script.

## Setup

1. Install Pony compiler:
   ```bash
   brew install ponyc
   ```

2. Make the build script executable:
   ```bash
   chmod +x pony
   ```

## Usage

Use the `pony` script to compile and run projects:

```bash
# Compile a project
./pony compile <project_name>

# Run a compiled project
./pony run <project_name>
```

### Example

```bash
# Compile the actors project
./pony compile actors

# Run the actors project
./pony run actors
```

## Projects

### actors/
Actor-based model demonstration with:
- **Actor Creation**: Basic actor initialization
- **Actor Communication**: Message passing between PingActor and PongActor
- **Actor Concurrency**: Multiple workers running simultaneously

## Project Structure

Each project follows this structure:
```
project_name/
├── main.pony           # Main source file
└── bin/
    └── project_name    # Compiled executable (generated)
```

## Requirements

- Pony compiler (ponyc) 0.59.0 or later
- macOS/Linux environment