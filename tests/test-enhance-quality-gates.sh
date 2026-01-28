#!/bin/bash
# Test: enhance-quality-gates.sh
# TDD spec for enhancement quality gates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$SCRIPT_DIR/../scripts/enhance-quality-gates.sh"

echo "========================================"
echo "Testing: enhance-quality-gates.sh"
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
    test_fail "Bash syntax error"
fi

# ============================================
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q "source.*lib/common.sh" "$SCRIPT"; then
    test_pass
else
    test_fail "Does not source common.sh"
fi

# ============================================
# Test: Supports baseline comparison
# ============================================
test_start "Supports baseline comparison"
if grep -q "BASELINE\|baseline" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing baseline support"
fi

# ============================================
# Test: Supports analysis file input
# ============================================
test_start "Supports analysis file input"
if grep -q "ANALYSIS\|analysis" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing analysis file support"
fi

# ============================================
# Test: Has gate pass/fail functions
# ============================================
test_start "Has gate pass/fail functions"
if grep -q "gate_pass\|gate_fail" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing gate functions"
fi

# ============================================
# Test: Tracks gate counters
# ============================================
test_start "Tracks gate counters"
if grep -q "PASSED_GATES\|FAILED_GATES\|TOTAL_GATES" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing gate counters"
fi

# ============================================
# Test: Supports verbose mode
# ============================================
test_start "Supports verbose mode"
if grep -q "VERBOSE\|--verbose" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing verbose mode"
fi

# ============================================
# Test: Supports skip-docker option
# ============================================
test_start "Supports skip-docker option"
if grep -q "SKIP_DOCKER\|--skip-docker" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing skip-docker option"
fi

# ============================================
# Test: Has target coverage setting
# ============================================
test_start "Has target coverage setting"
if grep -q "TARGET_COVERAGE\|target.*coverage" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing target coverage"
fi

# ============================================
# Test: Validates project directory
# ============================================
test_start "Validates project directory"
if grep -q "PROJECT_DIR\|-d.*PROJECT" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing project directory validation"
fi

# ============================================
# Test: Has custom log_detail function
# ============================================
test_start "Has custom log_detail function"
if grep -q "log_detail" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing log_detail function"
fi

# ============================================
# Test: Runs quality gate checks
# ============================================
test_start "Runs quality gate checks"
if grep -qE 'run_gate|check_gate|Gate' "$SCRIPT"; then
    test_pass
else
    test_fail "Should run quality gate checks"
fi

# ============================================
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -qE 'ensure_dir|mkdir -p' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir"
fi

print_summary
