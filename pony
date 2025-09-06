#!/bin/bash

# Pony project management script

show_usage() {
    cat << 'EOF'
Usage: ./pony <command> <project_name> [args...]

Commands:
  help                    - Show this help message
  compile <project>       - Compile the project to project/bin/
  run <project> [args]    - Run the compiled project with optional arguments

Examples:
  ./pony help
  ./pony compile fibonacci
  ./pony run fibonacci
  ./pony run fibonacci train
  ./pony run fibonacci test 100
  ./pony run fibonacci resume
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
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac