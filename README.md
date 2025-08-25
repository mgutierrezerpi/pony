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

### supervisor/
Supervisor pattern implementation demonstrating:
- **Supervisor Actor**: Monitors and manages child actors
- **Worker Actors**: Perform work with random failure (20% chance)
- **Automatic Restart**: Failed workers are restarted after 3 seconds
- **Health Monitoring**: Periodic health checks every 2 seconds
- **Fault Tolerance**: System continues operating despite individual failures

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