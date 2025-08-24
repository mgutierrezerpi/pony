#!/bin/bash

# Pony project management script

show_usage() {
    cat << 'EOF'
Usage: ./pony <command> <project_name>

Commands:
  compile <project>  - Compile the project to project/bin/
  run <project>      - Run the compiled project from project/bin/

Examples:
  ./pony compile actors
  ./pony run actors
EOF
}

if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
PROJECT=$2

case "$COMMAND" in
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
        
        echo "Running $PROJECT..."
        "./$EXECUTABLE"
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac