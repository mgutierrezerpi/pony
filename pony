#!/bin/bash

# Pony project management script

show_usage() {
    cat << 'EOF'
Usage: ./pony <command> <project_name> [args...]

Commands:
  help                    - Show this help message
  compile <project>       - Compile the project to apps/<project>/bin/
  run <project> [args]    - Run the compiled project with optional arguments
  test <project>          - Run unit tests for the project
  disassemble <project>   - Disassemble the best genome (shows nucleos and execution trace)

Available Projects (in apps/):
  powers_of_two           - Evolve VM programs to compute powers of 2
  sentiment_analysis      - Multilingual sentiment classification using evolved weights
  web_server              - REST API server for trained models

Examples:
  ./pony help
  ./pony compile powers_of_two
  ./pony compile sentiment_analysis
  ./pony compile web_server

  ./pony run powers_of_two train
  ./pony run powers_of_two 5
  ./pony run powers_of_two resume 100
  ./pony run powers_of_two disassemble

  ./pony run sentiment_analysis train
  ./pony run sentiment_analysis analyze "I love this movie"
  ./pony run sentiment_analysis test

  ./pony run web_server
  HOST=0.0.0.0 PORT=3000 ./pony run web_server

  ./pony test powers_of_two
  ./pony disassemble powers_of_two
EOF
}

if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

if [ $# -lt 2 ] && [ "$1" != "help" ]; then
    show_usage
    exit 1
fi

COMMAND=$1
PROJECT=$2
PROJECT_DIR="apps/$PROJECT"

case "$COMMAND" in
    "help")
        show_usage
        exit 0
        ;;

    "compile")
        if [ ! -d "$PROJECT_DIR" ]; then
            echo "Error: Project directory '$PROJECT_DIR' does not exist"
            exit 1
        fi

        echo "Compiling $PROJECT..."
        mkdir -p "$PROJECT_DIR/bin"
        ponyc "$PROJECT_DIR" --output "$PROJECT_DIR/bin" --bin-name "$PROJECT"
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully compiled $PROJECT to $PROJECT_DIR/bin/$PROJECT"
        else
            echo "❌ Compilation failed"
            exit 1
        fi
        ;;

    "run")
        EXECUTABLE="$PROJECT_DIR/bin/$PROJECT"
        
        if [ ! -f "$EXECUTABLE" ]; then
            echo "Error: Executable '$EXECUTABLE' not found"
            echo "Try running: $0 compile $PROJECT"
            exit 1
        fi
        
        # Get all arguments after the first two (command and project)
        shift 2
        ARGS="$@"
        
        if [ -n "$ARGS" ]; then
            echo "Running $PROJECT with arguments: $ARGS"
        else
            echo "Running $PROJECT..."
        fi
        "./$EXECUTABLE" $ARGS
        ;;
        
    "test")
        if [ ! -d "$PROJECT_DIR" ]; then
            echo "Error: Project directory '$PROJECT_DIR' does not exist"
            exit 1
        fi

        echo "Running tests for $PROJECT..."
        mkdir -p "$PROJECT_DIR/bin"

        # Check if we have test files in test directory
        if [ -f "$PROJECT_DIR/test/test_vm.pony" ] && [ -f "$PROJECT_DIR/test/test_main.pony" ]; then
            echo "Compiling and running test suite..."

            # Create a temporary test directory
            mkdir -p "$PROJECT_DIR/test_build"

            # Copy test files and dependencies
            cp "$PROJECT_DIR/test/test_vm.pony" "$PROJECT_DIR/test_build/"
            cp "$PROJECT_DIR/test/test_main.pony" "$PROJECT_DIR/test_build/main.pony"  # Use test_main as main

            # Copy the core and packages directories
            cp -r "$PROJECT_DIR/core" "$PROJECT_DIR/test_build/"
            cp -r "packages/_framework" "$PROJECT_DIR/test_build/"

            # Compile the test suite
            ponyc "$PROJECT_DIR/test_build" --output "$PROJECT_DIR/bin" --bin-name test_runner

            # Clean up
            rm -rf "$PROJECT_DIR/test_build"

            if [ $? -eq 0 ] && [ -f "$PROJECT_DIR/bin/test_runner" ]; then
                echo "Running VM tests..."
                "./$PROJECT_DIR/bin/test_runner"
            else
                echo "❌ Test compilation failed"
                exit 1
            fi
        else
            echo "No test files found in test/ directory"
            exit 1
        fi
        ;;

    "disassemble")
        EXECUTABLE="$PROJECT_DIR/bin/$PROJECT"

        if [ ! -f "$EXECUTABLE" ]; then
            echo "Error: Executable '$EXECUTABLE' not found"
            echo "Try running: $0 compile $PROJECT"
            exit 1
        fi

        echo "Disassembling best genome from $PROJECT..."
        "./$EXECUTABLE" disassemble
        ;;

    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac