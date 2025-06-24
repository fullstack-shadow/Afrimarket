#!/bin/bash
# Generate project documentation including API references, metrics, and architecture diagrams
# Usage: ./scripts/docs/generate_docs.sh [--api] [--metrics] [--diagrams] [--all] [--serve]

# Enable strict error handling
set -euo pipefail

# Configuration
DOCS_DIR="docs"
API_DOCS_DIR="${DOCS_DIR}/api"
METRICS_DIR="${DOCS_DIR}/metrics"
DIAGRAMS_DIR="${DOCS_DIR}/architecture"
TEMPLATES_DIR="scripts/docs/templates"
FLUTTER_DOC="flutter pub global run dartdoc"
PLANTUML_JAR="scripts/docs/plantuml.jar"

# Initialize variables
GENERATE_API=false
GENERATE_METRICS=false
GENERATE_DIAGRAMS=false
SERVE_DOCS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --api)
      GENERATE_API=true
      shift
      ;;
    --metrics)
      GENERATE_METRICS=true
      shift
      ;;
    --diagrams)
      GENERATE_DIAGRAMS=true
      shift
      ;;
    --all)
      GENERATE_API=true
      GENERATE_METRICS=true
      GENERATE_DIAGRAMS=true
      shift
      ;;
    --serve)
      SERVE_DOCS=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [--api] [--metrics] [--diagrams] [--all] [--serve]"
      exit 1
      ;;
  esac
done

# If no specific target selected, generate all
if [ "$GENERATE_API" = false ] && [ "$GENERATE_METRICS" = false ] && [ "$GENERATE_DIAGRAMS" = false ]; then
  GENERATE_API=true
  GENERATE_METRICS=true
  GENERATE_DIAGRAMS=true
fi

# Verify dependencies
verify_dependencies() {
  local missing=0

  if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found"
    missing=1
  fi

  if [ "$GENERATE_DIAGRAMS" = true ] && [ ! -f "$PLANTUML_JAR" ]; then
    echo "❌ PlantUML not found at $PLANTUML_JAR"
    missing=1
  fi

  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

# Generate API documentation
generate_api_docs() {
  echo "📚 Generating API documentation..."
  mkdir -p "$API_DOCS_DIR"
  
  $FLUTTER_DOC \
    --output "$API_DOCS_DIR" \
    --exclude '**/*.g.dart,**/*.freezed.dart,**/test/**' \
    --include '**/*.dart' \
    --no-include-source
  
  # Add custom header
  cp "${TEMPLATES_DIR}/api_header.md" "${API_DOCS_DIR}/index.md"
  
  echo "✅ API docs generated at ${API_DOCS_DIR}"
}

# Generate code metrics
generate_metrics() {
  echo "📊 Generating code metrics..."
  mkdir -p "$METRICS_DIR"
  
  # Run Dart Code Metrics
  flutter pub run dart_code_metrics:metrics analyze lib --reporter=html --output-dir="$METRICS_DIR"
  
  # Generate test coverage report
  ./scripts/coverage/generate_coverage.sh --lcov
  flutter pub run dart_code_metrics:metrics check-unnecessary-nullable --lints-file="${METRICS_DIR}/null_analysis.json"
  
  # Generate metrics summary
  flutter pub run dart_code_metrics:metrics analyze lib --reporter=json --output-dir="$METRICS_DIR" > "${METRICS_DIR}/summary.json"
  
  echo "✅ Metrics generated at ${METRICS_DIR}"
}

# Generate architecture diagrams
generate_diagrams() {
  echo "📐 Generating architecture diagrams..."
  mkdir -p "$DIAGRAMS_DIR"
  
  # Process PlantUML files
  for diagram in "${TEMPLATES_DIR}"/diagrams/*.puml; do
    local diagram_name=$(basename "$diagram" .puml)
    java -jar "$PLANTUML_JAR" -tsvg "$diagram" -o "../${DIAGRAMS_DIR}"
    echo "  - Generated ${diagram_name}.svg"
  done
  
  # Generate architecture overview
  flutter pub run mason make architecture_overview --output-dir="$DIAGRAMS_DIR"
  
  echo "✅ Diagrams generated at ${DIAGRAMS_DIR}"
}

# Serve documentation locally
serve_docs() {
  if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found - cannot serve docs"
    return
  fi

  echo "🌐 Serving documentation at http://localhost:8000"
  cd "$DOCS_DIR" && python3 -m http.server 8000
}

# Main execution
main() {
  verify_dependencies
  
  # Create docs directory if it doesn't exist
  mkdir -p "$DOCS_DIR"
  
  # Generate requested documentation
  if [ "$GENERATE_API" = true ]; then
    generate_api_docs
  fi
  
  if [ "$GENERATE_METRICS" = true ]; then
    generate_metrics
  fi
  
  if [ "$GENERATE_DIAGRAMS" = true ]; then
    generate_diagrams
  fi
  
  # Generate README index
  cp "${TEMPLATES_DIR}/README.md" "${DOCS_DIR}/README.md"
  
  if [ "$SERVE_DOCS" = true ]; then
    serve_docs
  fi
  
  echo "🎉 Documentation generation complete!"
  echo "📂 Documentation available in: ${DOCS_DIR}"
}

main