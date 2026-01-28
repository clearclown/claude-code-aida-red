#!/bin/bash
# Test: subagent-validator.sh (Issue #215)
# TDD spec for Player (subagent) completion validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$SCRIPT_DIR/../hooks/stop/subagent-validator.sh"

echo "========================================"
echo "Testing: subagent-validator.sh"
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
# Test: Validates Backend Player
# ============================================
test_start "Validates Backend Player"
if grep -q "Backend Player\|BACKEND_DIR\|backend" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing Backend Player validation"
fi

# ============================================
# Test: Validates Frontend Player
# ============================================
test_start "Validates Frontend Player"
if grep -q "Frontend Player\|FRONTEND_DIR\|frontend" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing Frontend Player validation"
fi

# ============================================
# Test: Checks minimum test requirements
# ============================================
test_start "Checks minimum test requirements"
if grep -q "MIN_BACKEND_TESTS\|MIN_FRONTEND_TESTS" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing minimum test requirements"
fi

# ============================================
# Test: Counts test functions
# ============================================
test_start "Counts test functions"
if grep -q "func Test\|BACKEND_TESTS\|FRONTEND_TESTS" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing test counting logic"
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
# Test: Validates E2E tests
# ============================================
test_start "Validates E2E tests"
if grep -q "E2E\|e2e" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing E2E validation"
fi

# ============================================
# Test: Checks handler test coverage
# ============================================
test_start "Checks handler test coverage"
if grep -q "handler\|HANDLER" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing handler coverage check"
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
    test_fail "Missing session file handling"
fi

# ============================================
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q "source.*lib/common.sh" "$SCRIPT"; then
    test_pass
else
    test_fail "Should source common.sh"
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

print_summary
