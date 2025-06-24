#!/bin/bash
# Generates test coverage reports and opens them in a browser
# Usage: ./scripts/coverage/generate_coverage.sh [--html] [--lcov] [--ci]

# Enable strict error handling
set -euo pipefail

# Configuration
COVERAGE_DIR="coverage"
REPORT_DIR="${COVERAGE_DIR}/reports"
UNIT_TEST_DIR="test"
INTEGRATION_TEST_DIR="test/integration"
E2E_TEST_DIR="test/e2e"
LCOV_FILE="${COVERAGE_DIR}/lcov.info"

# Parse command line arguments
GENERATE_HTML=false
GENERATE_LCOV=false
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --html)
      GENERATE_HTML=true
      shift
      ;;
    --lcov)
      GENERATE_LCOV=true
      shift
      ;;
    --ci)
      CI_MODE=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [--html] [--lcov] [--ci]"
      exit 1
      ;;
  esac
done

# Create coverage directories
mkdir -p "${COVERAGE_DIR}"
mkdir -p "${REPORT_DIR}"

echo "🔍 Running tests with coverage..."

# Run unit tests with coverage
flutter test --coverage "${UNIT_TEST_DIR}"

# For integration tests (if needed)
if [ -d "${INTEGRATION_TEST_DIR}" ]; then
  echo "🧪 Running integration tests..."
  flutter test --coverage "${INTEGRATION_TEST_DIR}"
fi

# For e2e tests (if needed)
if [ -d "${E2E_TEST_DIR}" ]; then
  echo "🔗 Running e2e tests..."
  flutter test --coverage "${E2E_TEST_DIR}"
fi

# Process coverage data
echo "📊 Processing coverage data..."

# Combine coverage data
lcov --add-tracefile coverage/lcov.info --output-file "${LCOV_FILE}"

# Remove files we don't want to track
lcov --remove "${LCOV_FILE}" \
  '**/*.g.dart' \
  '**/*.freezed.dart' \
  '**/*.gr.dart' \
  '**/*.mocks.dart' \
  '**/*.pbenum.dart' \
  '**/*.pbjson.dart' \
  '**/*.pb.dart' \
  '**/*_event.dart' \
  '**/*_state.dart' \
  '**/generated_plugin_registrant.dart' \
  '**/test/**' \
  '**/mock/**' \
  -o "${LCOV_FILE}"

# Generate HTML report if requested
if [ "$GENERATE_HTML" = true ]; then
  echo "🌐 Generating HTML report..."
  genhtml "${LCOV_FILE}" -o "${REPORT_DIR}/html"
  
  if [ "$CI_MODE" = false ]; then
    # Open in default browser (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      open "${REPORT_DIR}/html/index.html"
    # Linux
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      xdg-open "${REPORT_DIR}/html/index.html"
    fi
  fi
fi

# Generate LCOV report if requested
if [ "$GENERATE_LCOV" = true ]; then
  echo "📝 Generating LCOV report..."
  cp "${LCOV_FILE}" "${REPORT_DIR}/lcov.info"
fi

# Generate coverage badge for CI
if [ "$CI_MODE" = true ]; then
  echo "🛠️ Generating coverage badge..."
  TOTAL_COVERAGE=$(lcov --summary "${LCOV_FILE}" 2>&1 | grep lines | awk '{print $2}' | tr -d '%')
  echo "📈 Total Coverage: ${TOTAL_COVERAGE}%"
  
  # Generate badge (requires lcov-to-cobertura-xml and coverage-badger)
  if command -v lcov-to-cobertura-xml &> /dev/null && command -v coverage-badger &> /dev/null; then
    lcov-to-cobertura-xml "${LCOV_FILE}" -o "${REPORT_DIR}/coverage.xml"
    coverage-badger -i "${REPORT_DIR}/coverage.xml" -o "${REPORT_DIR}/coverage.svg"
  fi
fi

echo "✅ Coverage generation complete!"
echo "📂 Reports available in: ${REPORT_DIR}"