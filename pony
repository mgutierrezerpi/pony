#!/bin/bash

# Pony project management script

show_usage() {
    cat << 'EOF'
Usage: ./pony <command> <project_name> [args...]

Commands:
  help                    - Show this help message
  compile <project>       - Compile the project to project/bin/
  run <project> [args]    - Run the compiled project with optional arguments
  test <project>          - Run unit tests for the project

Available Projects:
  fibonacci              - Evolve VM programs to compute Fibonacci sequences
  sentiment              - Multilingual emotion detection using neural networks
  powers_of_two          - Evolve VM programs to compute powers of 2

Examples:
  ./pony help
  ./pony compile fibonacci
  ./pony compile sentiment
  ./pony compile powers_of_two
  ./pony run fibonacci train
  ./pony run sentiment analyze "I'm so happy today!"
  ./pony run powers_of_two train
  ./pony run powers_of_two 5
  ./pony test fibonacci
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

case "$COMMAND" in
    "help")
        show_usage
        exit 0
        ;;
        
    "compile")
        if [ ! -d "$PROJECT" ]; then
            echo "Error: Project directory '$PROJECT' does not exist"
            exit 1
        fi
        
        echo "Compiling $PROJECT..."
        mkdir -p "$PROJECT/bin"
        ponyc "$PROJECT" --output "$PROJECT/bin" --bin-name "$PROJECT"
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully compiled $PROJECT to $PROJECT/bin/$PROJECT"
        else
            echo "❌ Compilation failed"
            exit 1
        fi
        ;;
        
    "run")
        EXECUTABLE="$PROJECT/bin/$PROJECT"
        
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
        if [ ! -d "$PROJECT" ]; then
            echo "Error: Project directory '$PROJECT' does not exist"
            exit 1
        fi
        
        echo "Running tests for $PROJECT..."
        mkdir -p "$PROJECT/bin"
        
        # Check if we have test files in test directory
        if [ -f "$PROJECT/test/test_vm.pony" ] && [ -f "$PROJECT/test/test_main.pony" ]; then
            echo "Compiling and running test suite..."
            
            # Create a temporary test directory
            mkdir -p "$PROJECT/test_build"
            
            # Copy test files and dependencies
            cp "$PROJECT/test/test_vm.pony" "$PROJECT/test_build/"
            cp "$PROJECT/test/test_main.pony" "$PROJECT/test_build/main.pony"  # Use test_main as main
            
            # Copy the core and _framework directories
            cp -r "$PROJECT/core" "$PROJECT/test_build/"
            cp -r "$PROJECT/_framework" "$PROJECT/test_build/"
            
            # Compile the test suite
            ponyc "$PROJECT/test_build" --output "$PROJECT/bin" --bin-name test_runner
            
            # Clean up
            rm -rf "$PROJECT/test_build"
            
            if [ $? -eq 0 ] && [ -f "$PROJECT/bin/test_runner" ]; then
                echo "Running VM tests..."
                "./$PROJECT/bin/test_runner"
            else
                echo "❌ Test compilation failed"
                exit 1
            fi
        else
            echo "No test files found in test/ directory"
            exit 1
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac