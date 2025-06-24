#!/bin/bash
# Run build_runner with configuration options
# Usage: ./tools/code_generation/build_runner.sh [--watch] [--clean] [--force] [--verbose]

# Enable strict error handling
set -euo pipefail

# Default parameters
WATCH_MODE=false
CLEAN_FIRST=false
FORCE_BUILD=false
VERBOSE_LEVEL=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --watch)
      WATCH_MODE=true
      shift
      ;;
    --clean)
      CLEAN_FIRST=true
      shift
      ;;
    --force)
      FORCE_BUILD=true
      shift
      ;;
    --verbose)
      VERBOSE_LEVEL=1
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [--watch] [--clean] [--force] [--verbose]"
      exit 1
      ;;
  esac
done

# Log function with verbosity control
log() {
  if [ $VERBOSE_LEVEL -ge 1 ]; then
    echo "🚀 $1"
  fi
}

# Clean previous builds
clean_build() {
  log "Cleaning previous builds..."
  flutter pub run build_runner clean
}

# Main build function
run_build() {
  local command="flutter pub run build_runner build"
  
  if [ "$WATCH_MODE" = true ]; then
    command="$command --watch"
    log "Starting watch mode..."
  fi
  
  if [ "$FORCE_BUILD" = true ]; then
    command="$command --delete-conflicting-outputs"
    log "Forcing rebuild with conflict resolution..."
  fi

  if [ $VERBOSE_LEVEL -ge 1 ]; then
    command="$command --verbose"
  fi

  log "Executing: $command"
  eval $command
}

# Verify dependencies
verify_dependencies() {
  if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter SDK."
    exit 1
  fi

  if ! dart pub get &> /dev/null; then
    echo "❌ Failed to get Dart packages."
    exit 1
  fi
}

# Main execution
main() {
  verify_dependencies
  
  if [ "$CLEAN_FIRST" = true ]; then
    clean_build
  fi

  run_build
}

main