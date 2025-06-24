#!/bin/bash
# Run all test suites with proper reporting and resource management
# Usage: ./scripts/test/run_all_tests.sh [--unit] [--integration] [--e2e] [--golden] [--coverage] [--ci]

# Enable strict error handling
set -euo pipefail

# Configuration
REPORT_DIR="test_reports"
UNIT_TEST_DIR="test"
INTEGRATION_TEST_DIR="test/integration"
E2E_TEST_DIR="test/e2e"
GOLDEN_TEST_DIR="test/golden"
COVERAGE_DIR="coverage"
LOG_FILE="$REPORT_DIR/test_logs.txt"

# Initialize variables
RUN_UNIT=false
RUN_INTEGRATION=false
RUN_E2E=false
RUN_GOLDEN=false
RUN_COVERAGE=false
CI_MODE=false
PARALLEL_JOBS=4  # Number of parallel test jobs

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --unit)
      RUN_UNIT=true
      shift
      ;;
    --integration)
      RUN_INTEGRATION=true
      shift
      ;;
    --e2e)
      RUN_E2E=true
      shift
      ;;
    --golden)
      RUN_GOLDEN=true
      shift
      ;;
    --coverage)
      RUN_COVERAGE=true
      shift
      ;;
    --ci)
      CI_MODE=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [--unit] [--integration] [--e2e] [--golden] [--coverage] [--ci]"
      exit 1
      ;;
  esac
done

# If no specific test type selected, run all
if [ "$RUN_UNIT" = false ] && [ "$RUN_INTEGRATION" = false ] && 
   [ "$RUN_E2E" = false ] && [ "$RUN_GOLDEN" = false ]; then
  RUN_UNIT=true
  RUN_INTEGRATION=true
  RUN_E2E=true
  RUN_GOLDEN=true
fi

# Create report directory
mkdir -p "$REPORT_DIR"
rm -f "$LOG_FILE"  # Clear previous logs

# Initialize test counters
declare -A test_results=(
  [unit]=0
  [integration]=0
  [e2e]=0
  [golden]=0
)

# Helper function to run tests with timing and reporting
run_test_suite() {
  local suite_name=$1
  local test_dir=$2
  local test_command=$3
  local start_time=$(date +%s)
  local log_file="$REPORT_DIR/${suite_name}_report.txt"

  echo "🧪 Starting $suite_name tests..."
  echo "==================== $suite_name TESTS ====================" >> "$LOG_FILE"

  if eval "$test_command" 2>&1 | tee -a "$LOG_FILE" "$log_file"; then
    test_results[$suite_name]=0
    echo "✅ $suite_name tests passed"
  else
    test_results[$suite_name]=1
    echo "❌ $suite_name tests failed"
  fi

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  echo "⏱️  $suite_name tests completed in ${duration}s"
}

# Run unit tests
if [ "$RUN_UNIT" = true ]; then
  run_test_suite "unit" "$UNIT_TEST_DIR" \
    "flutter test --machine --coverage --concurrency=$PARALLEL_JOBS $UNIT_TEST_DIR"
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
  run_test_suite "integration" "$INTEGRATION_TEST_DIR" \
    "flutter test --machine $INTEGRATION_TEST_DIR"
fi

# Run e2e tests
if [ "$RUN_E2E" = true ]; then
  run_test_suite "e2e" "$E2E_TEST_DIR" \
    "flutter test --machine $E2E_TEST_DIR"
fi

# Run golden tests
if [ "$RUN_GOLDEN" = true ]; then
  run_test_suite "golden" "$GOLDEN_TEST_DIR" \
    "flutter test --machine --update-goldens $GOLDEN_TEST_DIR"
fi

# Generate coverage report if requested
if [ "$RUN_COVERAGE" = true ]; then
  echo "📊 Generating coverage report..."
  ./scripts/coverage/generate_coverage.sh --html --lcov
  
  if [ "$CI_MODE" = true ]; then
    ./scripts/coverage/generate_coverage.sh --ci
  fi
fi

# Generate summary report
echo "📝 Generating test summary..."
{
  echo "==================== TEST SUMMARY ===================="
  echo "Unit Tests: $([ ${test_results[unit]} -eq 0 ] && echo "✅ Passed" || echo "❌ Failed")"
  echo "Integration Tests: $([ ${test_results[integration]} -eq 0 ] && echo "✅ Passed" || echo "❌ Failed")"
  echo "E2E Tests: $([ ${test_results[e2e]} -eq 0 ] && echo "✅ Passed" || echo "❌ Failed")"
  echo "Golden Tests: $([ ${test_results[golden]} -eq 0 ] && echo "✅ Passed" || echo "❌ Failed")"
  echo "====================================================="
} | tee -a "$LOG_FILE" "$REPORT_DIR/summary.txt"

# Check for any test failures
if [[ "${test_results[@]}" =~ 1 ]]; then
  echo "❌ Some tests failed. See $LOG_FILE for details."
  exit 1
else
  echo "🎉 All tests passed successfully!"
  exit 0
fi