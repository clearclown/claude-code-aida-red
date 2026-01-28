#!/bin/bash
# Tests for test-aida.sh
# Self-test script validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/test-aida.sh"

echo "========================================"
echo "Testing: test-aida.sh"
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
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q 'source.*lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source common.sh"
fi

# ============================================
# Test: Supports --quick option
# ============================================
test_start "Supports --quick option"
if grep -qE "\-\-quick" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --quick option"
fi

# ============================================
# Test: Supports --full option
# ============================================
test_start "Supports --full option"
if grep -qE "\-\-full" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --full option"
fi

# ============================================
# Test: Has run_test function
# ============================================
test_start "Has run_test function"
if grep -q 'run_test()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have run_test function"
fi

# ============================================
# Test: Tests directory structure
# ============================================
test_start "Tests directory structure"
if grep -qE "agents.*commands.*scripts" "$SCRIPT"; then
    test_pass
else
    test_fail "Should test directory structure"
fi

# ============================================
# Test: Tests agent files
# ============================================
test_start "Tests agent files"
if grep -q "conductor.md" "$SCRIPT" && \
   grep -q "player.md" "$SCRIPT"; then
    test_pass
else
    test_fail "Should test agent files"
fi

# ============================================
# Test: Tests script files
# ============================================
test_start "Tests script files"
if grep -q "quality-gates.sh" "$SCRIPT"; then
    test_pass
else
    test_fail "Should test script files"
fi

# ============================================
# Test: Tests executability
# ============================================
test_start "Tests script executability"
if grep -qE "\-x.*scripts" "$SCRIPT"; then
    test_pass
else
    test_fail "Should test script executability"
fi

# ============================================
# Test: Counts passed and failed tests
# ============================================
test_start "Counts passed and failed tests"
if grep -q "PASSED_TESTS" "$SCRIPT" && \
   grep -q "FAILED_TESTS" "$SCRIPT"; then
    test_pass
else
    test_fail "Should count passed and failed tests"
fi

# ============================================
# Test: Outputs summary
# ============================================
test_start "Outputs summary"
if grep -q "Test Summary" "$SCRIPT"; then
    test_pass
else
    test_fail "Should output summary"
fi

# ============================================
# Test: Container tests in full mode
# ============================================
test_start "Has container tests for full mode"
if grep -qE "Container.*Full|compose.*docker" "$SCRIPT"; then
    test_pass
else
    test_fail "Should have container tests for full mode"
fi

# ============================================
# Test: Returns proper exit codes
# ============================================
test_start "Returns proper exit codes"
if grep -q "exit 0" "$SCRIPT" && grep -q "exit 1" "$SCRIPT"; then
    test_pass
else
    test_fail "Should return proper exit codes"
fi

print_summary
