#!/bin/bash
# Test: enhance-gate.sh
# TDD spec for enhancement quality gate hook

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$SCRIPT_DIR/../hooks/stop/enhance-gate.sh"

echo "========================================"
echo "Testing: enhance-gate.sh"
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
# Test: Checks for enhance mode
# ============================================
test_start "Checks for enhance mode"
if grep -q "aida:enhance\|enhance.*mode\|MODE" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing enhance mode check"
fi

# ============================================
# Test: Verifies baseline preservation
# ============================================
test_start "Verifies baseline preservation"
if grep -q "baseline\|BASELINE" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing baseline verification"
fi

# ============================================
# Test: Runs quality gates
# ============================================
test_start "Runs quality gates"
if grep -q "quality.*gate\|GATE" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing quality gate execution"
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
# Test: Updates session on completion
# ============================================
test_start "Updates session on completion"
if grep -q "quality_gates_passed\|enhancement_complete" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing session update on completion"
fi

# ============================================
# Test: Writes completion result
# ============================================
test_start "Writes completion result"
if grep -q "enhance-complete.json\|RESULT_FILE" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing completion result file"
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
# Test: Reads session file
# ============================================
test_start "Reads session file"
if grep -q "SESSION_FILE\|session.json" "$SCRIPT"; then
    test_pass
else
    test_fail "Should read session file"
fi

# ============================================
# Test: Has stopReason field
# ============================================
test_start "Has stopReason field when blocking"
if grep -qE '"reason"|"stopReason"|output_block|output_allow' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have stopReason field"
fi

# ============================================
# Test: Uses strict mode
# ============================================
test_start "Uses strict mode (set -e or set -euo pipefail)"
if grep -qE 'set -e|set -euo pipefail' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use strict mode"
fi

print_summary
