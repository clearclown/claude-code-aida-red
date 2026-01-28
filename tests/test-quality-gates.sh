#!/bin/bash
# Tests for quality-gates.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/quality-gates.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: quality-gates.sh"
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
# Test: Help/usage when no args
# ============================================
test_start "Shows usage when no project provided"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "quality" || \
   assert_contains "$output" "project"; then
    test_pass
fi

# ============================================
# Test: Common library is sourced
# ============================================
test_start "Sources common library"
# Check that script references lib/common.sh
if grep -q "lib/common.sh" "$SCRIPT"; then
    test_pass
else
    test_fail "Does not source lib/common.sh"
fi

# ============================================
# Test: Defines gate functions
# ============================================
test_start "Defines gate check functions"
if grep -qE "check_gate|run_gate|gate_" "$SCRIPT"; then
    test_pass
else
    test_fail "No gate functions found"
fi

# ============================================
# Test: Has multiple gates defined
# ============================================
test_start "Has multiple gates defined"
gate_count=$(grep -cE "Gate [0-9]+|gate.*[0-9]+" "$SCRIPT" || echo "0")
if [[ $gate_count -ge 5 ]]; then
    test_pass
else
    test_fail "Expected at least 5 gates, found $gate_count"
fi

# ============================================
# Test: Handles missing project gracefully
# ============================================
test_start "Handles missing project directory"
output=$(run_script "$SCRIPT" nonexistent-project 2>&1) || true
exit_code=$?
# Should either show error or usage
if [[ $exit_code -ne 0 ]] || \
   assert_contains "$output" "not found" || \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Script syntax is valid
# ============================================
test_start "Script has valid bash syntax"
if bash -n "$SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error in script"
fi

# ============================================
# Test: Gate 20 TDD Evidence Verification exists
# ============================================
test_start "Gate 20: TDD Evidence Verification defined"
if grep -qE "Gate 20|gate.*20|TDD.*[Ee]vidence" "$SCRIPT"; then
    test_pass
else
    test_fail "Gate 20 TDD Evidence not found"
fi

# ============================================
# Test: TDD evidence directory check
# ============================================
test_start "Checks TDD evidence directory"
if grep -q "tdd-evidence" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check .aida/tdd-evidence directory"
fi

# ============================================
# Test: RED-GREEN-REFACTOR cycle verification
# ============================================
test_start "Verifies RED-GREEN-REFACTOR cycle"
if grep -qE "red.*phase|green.*phase|RED.*GREEN" "$SCRIPT"; then
    test_pass
else
    test_fail "Should verify TDD cycle phases"
fi

# ============================================
# Test: Outputs summary
# ============================================
test_start "Outputs gate summary"
if grep -qE "PASSED_GATES|FAILED_GATES|Summary" "$SCRIPT"; then
    test_pass
else
    test_fail "Should output gate summary"
fi

# ============================================
# Test: Uses log functions from common.sh
# ============================================
test_start "Uses log functions from common.sh"
if grep -qE "log_info|log_success|log_error|log_warning" "$SCRIPT"; then
    test_pass
else
    test_fail "Should use log functions"
fi

# ============================================
# Test: Has pass and fail counting
# ============================================
test_start "Has pass and fail counting"
if grep -q "PASSED_GATES=" "$SCRIPT" && grep -q "FAILED_GATES=" "$SCRIPT"; then
    test_pass
else
    test_fail "Should count passes and fails"
fi

# ============================================
# Test: Total gates tracking
# ============================================
test_start "Has total gates tracking"
if grep -q "TOTAL_GATES=" "$SCRIPT"; then
    test_pass
else
    test_fail "Should track total gates"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
