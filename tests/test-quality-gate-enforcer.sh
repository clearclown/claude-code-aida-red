#!/bin/bash
# Test: quality-gate-enforcer.sh (Issue #217)
# TDD spec for Ralph-loop iteration tracking

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$SCRIPT_DIR/../hooks/stop/quality-gate-enforcer.sh"

echo "========================================"
echo "Testing: quality-gate-enforcer.sh"
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
# Test: Has anti-infinite-loop protection (Issue #217)
# ============================================
test_start "Has anti-infinite-loop protection"
if grep -q "MAX_ITERATIONS" "$SCRIPT" && grep -q "STUCK_THRESHOLD" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing anti-infinite-loop configuration"
fi

# ============================================
# Test: Tracks iteration count
# ============================================
test_start "Tracks iteration count"
if grep -q "iteration" "$SCRIPT" && grep -q "iteration_history" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing iteration tracking"
fi

# ============================================
# Test: Detects stuck state
# ============================================
test_start "Detects stuck state"
if grep -q "STUCK_COUNT\|stuck_detected\|no progress" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing stuck detection"
fi

# ============================================
# Test: Uses correct JSON format for block
# ============================================
test_start "Uses correct JSON format for block"
if grep -qE '"decision": "block"|output_block' "$SCRIPT"; then
    test_pass
else
    test_fail "Block decision format incorrect"
fi

# ============================================
# Test: Uses correct JSON format for allow
# ============================================
test_start "Uses correct JSON format for allow"
if grep -qE '"decision": null|output_allow' "$SCRIPT"; then
    test_pass
else
    test_fail "Allow decision format incorrect"
fi

# ============================================
# Test: Generates fix plan
# ============================================
test_start "Generates fix plan"
if grep -q "generate-fix-plan.sh\|FIX_PLAN" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing fix plan generation"
fi

# ============================================
# Test: Updates session file
# ============================================
test_start "Updates session file"
if grep -q "SESSION_FILE\|session.json" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing session file handling"
fi

# ============================================
# Test: Respects max iterations
# ============================================
test_start "Respects max iterations"
if grep -q "MAX_ITERATIONS\|max_iterations" "$SCRIPT" && \
   grep -q "forced_exit\|max_iterations" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing max iterations enforcement"
fi

# ============================================
# Test: Exit codes are correct
# ============================================
test_start "Uses exit 0 for JSON processing"
if grep -q "exit 0" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing exit 0"
fi

# ============================================
# Test: Uses strict mode
# ============================================
test_start "Uses strict mode"
if grep -qE 'set -e|set -euo pipefail' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use strict mode"
fi

# ============================================
# Test: Has reason field when blocking
# ============================================
test_start "Has reason field when blocking"
if grep -qE '"reason"|REASON=|output_block' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have reason field"
fi

print_summary
