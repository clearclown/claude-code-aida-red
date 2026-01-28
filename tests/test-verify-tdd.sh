#!/bin/bash
# Tests for verify-tdd.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/verify-tdd.sh"

echo "========================================"
echo "Testing: verify-tdd.sh"
echo "========================================"
echo ""

# ============================================
# Test: Script exists and is executable
# ============================================
test_start "Script exists and is executable"
if assert_file_exists "$SCRIPT" && assert_executable "$SCRIPT"; then
    test_pass
fi

# ============================================
# Test: Script has valid bash syntax
# ============================================
test_start "Script has valid bash syntax"
if bash -n "$SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error in script"
fi

# ============================================
# Test: Shows usage when no args
# ============================================
test_start "Shows usage when no args"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "project-name"; then
    test_pass
fi

# ============================================
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q 'lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source lib/common.sh"
fi

# ============================================
# Test: Verifies backend TDD
# ============================================
test_start "Verifies backend TDD"
if grep -q 'verify_backend_tdd()' "$SCRIPT" && \
   grep -q 'go test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should verify backend TDD"
fi

# ============================================
# Test: Verifies frontend TDD
# ============================================
test_start "Verifies frontend TDD"
if grep -q 'verify_frontend_tdd()' "$SCRIPT" && \
   grep -q 'npm test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should verify frontend TDD"
fi

# ============================================
# Test: Checks test file count
# ============================================
test_start "Checks test file count"
if grep -q 'MIN_BACKEND_TESTS' "$SCRIPT" && \
   grep -q 'MIN_FRONTEND_TESTS' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check test file count"
fi

# ============================================
# Test: Checks test coverage
# ============================================
test_start "Checks test coverage"
if grep -q 'MIN_TEST_COVERAGE' "$SCRIPT" && \
   grep -q 'coverage' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check test coverage"
fi

# ============================================
# Test: Supports component selection
# ============================================
test_start "Supports component selection (backend, frontend, all)"
if grep -q 'COMPONENT' "$SCRIPT" && \
   grep -q 'backend)' "$SCRIPT" && \
   grep -q 'frontend)' "$SCRIPT" && \
   grep -q 'all)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support component selection"
fi

# ============================================
# Test: Checks TDD patterns
# ============================================
test_start "Checks TDD patterns"
if grep -q 'table-driven' "$SCRIPT" || \
   grep -q 'testing-library' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check TDD patterns"
fi

# ============================================
# Test: Reports summary
# ============================================
test_start "Reports summary with errors/warnings"
if grep -q 'ERRORS' "$SCRIPT" && \
   grep -q 'WARNINGS' "$SCRIPT"; then
    test_pass
else
    test_fail "Should report summary"
fi

# ============================================
# Test: Logs TDD verification
# ============================================
test_start "Logs TDD verification"
if grep -qE 'TDD Verification|TDD verification' "$SCRIPT"; then
    test_pass
else
    test_fail "Should log TDD verification"
fi

# ============================================
# Test: Checks for TDD patterns
# ============================================
test_start "Checks for TDD patterns"
if grep -qE 'TDD patterns|Test.*functions|test_helpers' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check TDD patterns"
fi

# ============================================
# Test: Uses exit codes
# ============================================
test_start "Uses exit codes for results"
if grep -qE 'exit [012]' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use exit codes"
fi

print_summary
