#!/bin/bash
#
# AIDA Enhancement Quality Gates
# Dynamic quality gates based on project analysis and baseline
# Enforces zero-regression and tracks coverage improvements
#
# Usage: ./scripts/enhance-quality-gates.sh <project_dir> [options]
#
# Options:
#   --baseline <file>  Use specific baseline file
#   --analysis <file>  Use specific analysis file
#   --target-coverage <N>  Target coverage percentage (default: 100)
#   --verbose          Show detailed output
#   --skip-docker      Skip Docker gates
#
# Exit codes:
#   0 - All gates passed
#   1 - Hard gate failure (blocks completion)
#   2 - Soft gate failure (warnings only)

set -euo pipefail

# ============================================
# Configuration
# ============================================

PROJECT_DIR="${1:-}"
shift || true

BASELINE_FILE=""
ANALYSIS_FILE=""
TARGET_COVERAGE=100
VERBOSE=false
SKIP_DOCKER=false

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --baseline)
            BASELINE_FILE="$2"
            shift 2
            ;;
        --analysis)
            ANALYSIS_FILE="$2"
            shift 2
            ;;
        --target-coverage)
            TARGET_COVERAGE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Counters
TOTAL_GATES=0
PASSED_GATES=0
FAILED_GATES=()
WARNED_GATES=()
REGRESSION_TESTS=()

# ============================================
# Helper Functions
# ============================================

# Custom log function for verbose output (not in common.sh)
log_detail() { [[ "$VERBOSE" == "true" ]] && echo -e "${CYAN}[DETAIL]${NC} $*"; }

gate_pass() {
    PASSED_GATES=$((PASSED_GATES + 1))
    log_success "Gate $TOTAL_GATES PASSED: $1"
}

gate_fail() {
    FAILED_GATES+=("Gate $TOTAL_GATES: $1")
    log_error "Gate $TOTAL_GATES FAILED: $1"
}

gate_warn() {
    WARNED_GATES+=("Gate $TOTAL_GATES: $1")
    log_warn "Gate $TOTAL_GATES WARNING: $1"
    PASSED_GATES=$((PASSED_GATES + 1))
}

# ============================================
# Validation
# ============================================

if [[ -z "$PROJECT_DIR" ]]; then
    echo "Usage: $0 <project_dir> [options]"
    echo ""
    echo "Options:"
    echo "  --baseline <file>      Use specific baseline file"
    echo "  --analysis <file>      Use specific analysis file"
    echo "  --target-coverage <N>  Target coverage percentage (default: 100)"
    echo "  --verbose              Show detailed output"
    echo "  --skip-docker          Skip Docker gates"
    exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
    log_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

# Convert to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
cd "$PROJECT_DIR"

# Auto-detect files
[[ -z "$BASELINE_FILE" ]] && BASELINE_FILE=".aida/state/enhance-baseline.json"
[[ -z "$ANALYSIS_FILE" ]] && ANALYSIS_FILE=".aida/analysis/*-analysis.json"

# Expand glob for analysis file
if [[ "$ANALYSIS_FILE" == *"*"* ]]; then
    ANALYSIS_FILE=$(ls $ANALYSIS_FILE 2>/dev/null | head -1 || echo "")
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")

echo ""
echo -e "${BLUE}========================================"
echo " AIDA Enhancement Quality Gates"
echo " Project: $PROJECT_NAME"
echo " Target Coverage: ${TARGET_COVERAGE}%"
echo "========================================${NC}"
echo ""

# ============================================
# Load Baseline
# ============================================

BASELINE_LOADED=false
BASELINE_TOTAL_TESTS=0
BASELINE_PASSED_TESTS=0
BASELINE_COVERAGE=""

if [[ -f "$BASELINE_FILE" ]]; then
    log_info "Loading baseline from $BASELINE_FILE"
    BASELINE_LOADED=true
    BASELINE_TOTAL_TESTS=$(jq -r '.summary.total_tests // 0' "$BASELINE_FILE")
    BASELINE_PASSED_TESTS=$(jq -r '.summary.total_passed // 0' "$BASELINE_FILE")
    BASELINE_VALID=$(jq -r '.summary.baseline_valid // true' "$BASELINE_FILE")

    log_info "Baseline: $BASELINE_TOTAL_TESTS tests, $BASELINE_PASSED_TESTS passed"

    if [[ "$BASELINE_VALID" != "true" ]]; then
        log_warn "Baseline has failing tests - will preserve this state"
    fi
else
    log_warn "No baseline file found at $BASELINE_FILE"
    log_warn "Run ./scripts/capture-baseline.sh first for accurate comparison"
fi

# ============================================
# Language Detection
# ============================================

detect_language() {
    if [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        echo "typescript"
    else
        echo "unknown"
    fi
}

# ============================================
# Test Execution Functions
# ============================================

run_go_tests() {
    local output_file="/tmp/enhance-go-test-output.json"

    log_detail "Running: go test -v -json ./..."

    local exit_code=0
    go test -v -json ./... > "$output_file" 2>&1 || exit_code=$?

    # Parse results
    local total=$(grep -c '"Action":"pass"\|"Action":"fail"' "$output_file" 2>/dev/null || echo "0")
    local passed=$(grep -c '"Action":"pass"' "$output_file" 2>/dev/null || echo "0")
    local failed=$(grep -c '"Action":"fail"' "$output_file" 2>/dev/null || echo "0")

    # Get coverage
    local coverage="0"
    go test -coverprofile=/tmp/enhance-coverage.out ./... >/dev/null 2>&1 || true
    if [[ -f "/tmp/enhance-coverage.out" ]]; then
        coverage=$(go tool cover -func=/tmp/enhance-coverage.out 2>/dev/null | grep total | awk '{print $3}' | sed 's/%//' || echo "0")
    fi

    echo "$total:$passed:$failed:$coverage:$exit_code"
}

run_ts_tests() {
    local output_file="/tmp/enhance-ts-test-output.txt"

    # Detect package manager
    local pm="npm"
    [[ -f "pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "yarn.lock" ]] && pm="yarn"

    log_detail "Running: $pm test"

    local exit_code=0
    $pm test -- --run 2>&1 | tee "$output_file" || exit_code=$?

    # Parse vitest/jest output
    local total=0
    local passed=0
    local failed=0

    # Try vitest format
    if grep -q "Tests:" "$output_file"; then
        total=$(grep -oP '\d+(?= passed)' "$output_file" | head -1 || echo "0")
        passed=$total
        failed=$(grep -oP '\d+(?= failed)' "$output_file" | head -1 || echo "0")
        total=$((passed + failed))
    fi

    # Get coverage
    local coverage="0"
    $pm test -- --run --coverage >/dev/null 2>&1 || true
    if [[ -f "coverage/coverage-summary.json" ]]; then
        coverage=$(cat coverage/coverage-summary.json | grep -oP '"pct":\s*\K[0-9.]+' | head -1 || echo "0")
    fi

    echo "$total:$passed:$failed:$coverage:$exit_code"
}

run_python_tests() {
    local output_file="/tmp/enhance-python-test-output.txt"

    log_detail "Running: pytest"

    local exit_code=0
    python -m pytest -v 2>&1 | tee "$output_file" || exit_code=$?

    # Parse pytest output
    local passed=$(grep -oP '\d+(?= passed)' "$output_file" | head -1 || echo "0")
    local failed=$(grep -oP '\d+(?= failed)' "$output_file" | head -1 || echo "0")
    local total=$((passed + failed))

    # Get coverage
    local coverage="0"
    python -m pytest --cov --cov-report=term 2>/dev/null | grep "TOTAL" | awk '{print $NF}' | sed 's/%//' > /tmp/py-cov.txt || true
    [[ -f "/tmp/py-cov.txt" ]] && coverage=$(cat /tmp/py-cov.txt)

    echo "$total:$passed:$failed:$coverage:$exit_code"
}

run_rust_tests() {
    local output_file="/tmp/enhance-rust-test-output.txt"

    log_detail "Running: cargo test"

    local exit_code=0
    cargo test 2>&1 | tee "$output_file" || exit_code=$?

    # Parse rust output
    local passed=$(grep -oP '\d+(?= passed)' "$output_file" | tail -1 || echo "0")
    local failed=$(grep -oP '\d+(?= failed)' "$output_file" | tail -1 || echo "0")
    local total=$((passed + failed))

    echo "$total:$passed:$failed:0:$exit_code"
}

# ============================================
# Gate 1: Build Check
# ============================================

TOTAL_GATES=$((TOTAL_GATES + 1))
log_info "[Gate $TOTAL_GATES] Build Check"

LANG=$(detect_language)
log_detail "Detected language: $LANG"

BUILD_EXIT=0
case "$LANG" in
    go)
        go build ./... 2>/dev/null || BUILD_EXIT=$?
        ;;
    typescript)
        npm run build 2>/dev/null || BUILD_EXIT=$?
        ;;
    python)
        # Python typically doesn't need build
        BUILD_EXIT=0
        ;;
    rust)
        cargo build 2>/dev/null || BUILD_EXIT=$?
        ;;
esac

if [[ $BUILD_EXIT -eq 0 ]]; then
    gate_pass "Build successful"
else
    gate_fail "Build failed"
fi

# ============================================
# Gate 2: Test Execution
# ============================================

TOTAL_GATES=$((TOTAL_GATES + 1))
log_info "[Gate $TOTAL_GATES] Test Execution"

CURRENT_TESTS=0
CURRENT_PASSED=0
CURRENT_FAILED=0
CURRENT_COVERAGE=0
TEST_EXIT=0

case "$LANG" in
    go)
        IFS=':' read -r CURRENT_TESTS CURRENT_PASSED CURRENT_FAILED CURRENT_COVERAGE TEST_EXIT <<< "$(run_go_tests)"
        ;;
    typescript)
        IFS=':' read -r CURRENT_TESTS CURRENT_PASSED CURRENT_FAILED CURRENT_COVERAGE TEST_EXIT <<< "$(run_ts_tests)"
        ;;
    python)
        IFS=':' read -r CURRENT_TESTS CURRENT_PASSED CURRENT_FAILED CURRENT_COVERAGE TEST_EXIT <<< "$(run_python_tests)"
        ;;
    rust)
        IFS=':' read -r CURRENT_TESTS CURRENT_PASSED CURRENT_FAILED CURRENT_COVERAGE TEST_EXIT <<< "$(run_rust_tests)"
        ;;
esac

log_info "Current: $CURRENT_TESTS tests, $CURRENT_PASSED passed, $CURRENT_FAILED failed"
log_info "Coverage: ${CURRENT_COVERAGE}%"

if [[ $TEST_EXIT -eq 0 ]] && [[ $CURRENT_FAILED -eq 0 ]]; then
    gate_pass "All tests passed"
else
    gate_fail "Test failures detected ($CURRENT_FAILED failed)"
fi

# ============================================
# Gate 3: Baseline Preservation (No Regression)
# ============================================

TOTAL_GATES=$((TOTAL_GATES + 1))
log_info "[Gate $TOTAL_GATES] Baseline Preservation (No Regression)"

if [[ "$BASELINE_LOADED" == "true" ]]; then
    # Check test count didn't decrease
    if [[ $CURRENT_TESTS -lt $BASELINE_TOTAL_TESTS ]]; then
        gate_fail "Test regression: $CURRENT_TESTS < $BASELINE_TOTAL_TESTS (lost tests)"
    elif [[ $CURRENT_PASSED -lt $BASELINE_PASSED_TESTS ]] && [[ "$BASELINE_VALID" == "true" ]]; then
        gate_fail "Test regression: $CURRENT_PASSED < $BASELINE_PASSED_TESTS (tests now failing)"
    else
        local new_tests=$((CURRENT_TESTS - BASELINE_TOTAL_TESTS))
        if [[ $new_tests -gt 0 ]]; then
            gate_pass "Baseline preserved + $new_tests new tests added"
        else
            gate_pass "Baseline preserved ($CURRENT_TESTS tests)"
        fi
    fi
else
    gate_warn "No baseline - cannot verify regression"
fi

# ============================================
# Gate 4: Coverage Target
# ============================================

TOTAL_GATES=$((TOTAL_GATES + 1))
log_info "[Gate $TOTAL_GATES] Coverage Target (${TARGET_COVERAGE}%)"

if [[ "$CURRENT_COVERAGE" == "0" ]] || [[ -z "$CURRENT_COVERAGE" ]]; then
    gate_warn "Coverage measurement unavailable"
elif (( $(echo "$CURRENT_COVERAGE >= $TARGET_COVERAGE" | bc -l) )); then
    gate_pass "Coverage ${CURRENT_COVERAGE}% >= ${TARGET_COVERAGE}%"
elif (( $(echo "$CURRENT_COVERAGE >= 80" | bc -l) )); then
    gate_warn "Coverage ${CURRENT_COVERAGE}% < ${TARGET_COVERAGE}% (acceptable)"
else
    gate_fail "Coverage ${CURRENT_COVERAGE}% is below minimum (80%)"
fi

# ============================================
# Gate 5: Security Check (Basic)
# ============================================

TOTAL_GATES=$((TOTAL_GATES + 1))
log_info "[Gate $TOTAL_GATES] Basic Security Check"

SECURITY_ISSUES=0

# Check for common security anti-patterns
case "$LANG" in
    go)
        # Check for unsafe operations
        if grep -r "unsafe\." --include="*.go" . 2>/dev/null | grep -v "_test.go" | grep -v "vendor/" | head -1 | grep -q .; then
            log_detail "Found unsafe package usage"
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
        # Check for hardcoded secrets
        if grep -rE "(password|secret|api_key)\s*=\s*\"[^\"]+\"" --include="*.go" . 2>/dev/null | grep -v "_test.go" | head -1 | grep -q .; then
            log_detail "Found potential hardcoded secrets"
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
        ;;
    typescript)
        # Check for eval usage
        if grep -r "eval(" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v "node_modules" | head -1 | grep -q .; then
            log_detail "Found eval() usage"
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
        ;;
    python)
        # Check for exec/eval
        if grep -rE "exec\(|eval\(" --include="*.py" . 2>/dev/null | grep -v "test" | head -1 | grep -q .; then
            log_detail "Found exec/eval usage"
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
        ;;
esac

if [[ $SECURITY_ISSUES -eq 0 ]]; then
    gate_pass "No obvious security issues"
else
    gate_warn "Found $SECURITY_ISSUES potential security concerns"
fi

# ============================================
# Gate 6: Docker (Optional)
# ============================================

if [[ "$SKIP_DOCKER" != "true" ]] && [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
    TOTAL_GATES=$((TOTAL_GATES + 1))
    log_info "[Gate $TOTAL_GATES] Docker Build"

    # Detect compose command
    COMPOSE_CMD=""
    if command -v podman-compose > /dev/null 2>&1; then
        COMPOSE_CMD="podman-compose"
    elif command -v docker > /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    fi

    if [[ -n "$COMPOSE_CMD" ]]; then
        if $COMPOSE_CMD build > /tmp/docker-build.log 2>&1; then
            gate_pass "Docker build successful"
        else
            gate_warn "Docker build failed (non-blocking)"
        fi
    else
        gate_warn "No container runtime available"
    fi
fi

# ============================================
# Summary
# ============================================

echo ""
echo -e "${BLUE}========================================"
echo " Enhancement Quality Gates Summary"
echo "========================================${NC}"
echo ""
echo "Project: $PROJECT_NAME"
echo "Language: $LANG"
echo ""
echo "Test Results:"
echo "  Total Tests: $CURRENT_TESTS"
echo "  Passed: $CURRENT_PASSED"
echo "  Failed: $CURRENT_FAILED"
echo "  Coverage: ${CURRENT_COVERAGE}%"
echo ""
echo "Gates:"
echo "  Total: $TOTAL_GATES"
echo "  Passed: $PASSED_GATES"
echo "  Failed: ${#FAILED_GATES[@]}"
echo "  Warnings: ${#WARNED_GATES[@]}"
echo ""

if [[ ${#FAILED_GATES[@]} -gt 0 ]]; then
    echo -e "${RED}Failed Gates:${NC}"
    for gate in "${FAILED_GATES[@]}"; do
        echo "  - $gate"
    done
    echo ""
fi

if [[ ${#WARNED_GATES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Warnings:${NC}"
    for gate in "${WARNED_GATES[@]}"; do
        echo "  - $gate"
    done
    echo ""
fi

# ============================================
# Generate Report
# ============================================

ensure_dir ".aida/results"

cat > ".aida/results/enhance-gates-result.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project": "$PROJECT_NAME",
  "language": "$LANG",
  "tests": {
    "total": $CURRENT_TESTS,
    "passed": $CURRENT_PASSED,
    "failed": $CURRENT_FAILED,
    "coverage": "$CURRENT_COVERAGE"
  },
  "baseline": {
    "loaded": $BASELINE_LOADED,
    "total_tests": $BASELINE_TOTAL_TESTS,
    "passed_tests": $BASELINE_PASSED_TESTS
  },
  "gates": {
    "total": $TOTAL_GATES,
    "passed": $PASSED_GATES,
    "failed": ${#FAILED_GATES[@]},
    "warnings": ${#WARNED_GATES[@]}
  },
  "result": "$([ ${#FAILED_GATES[@]} -eq 0 ] && echo 'PASS' || echo 'FAIL')"
}
EOF

# ============================================
# Exit Code
# ============================================

if [[ ${#FAILED_GATES[@]} -gt 0 ]]; then
    echo -e "${RED}========================================"
    echo " Enhancement Quality Gates FAILED"
    echo "========================================${NC}"
    echo ""
    echo "Fix the failing gates before completing enhancement."
    echo "Run with --verbose for more details."
    exit 1
else
    echo -e "${GREEN}========================================"
    echo " Enhancement Quality Gates PASSED"
    echo "========================================${NC}"
    echo ""
    if [[ ${#WARNED_GATES[@]} -gt 0 ]]; then
        echo "Note: Some warnings were generated. Consider addressing them."
    fi
    exit 0
fi
