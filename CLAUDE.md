# Claude Development Guidelines for Pony Project

## Compilation

Always use the provided `pony` script in the root directory for compiling and running Pony projects:

```bash
# Compile a project
./pony compile fibonacci

# Run a compiled project
./pony run fibonacci
```

The script handles:
- Creating the bin/ directory structure
- Setting proper output paths
- Using the correct binary naming conventions

Do NOT use `ponyc` directly. Always use `./pony compile <project_name>` instead.