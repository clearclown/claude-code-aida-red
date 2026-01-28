#!/bin/bash
# Tests for verify-installation.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/verify-installation.sh"

echo "========================================"
echo "Testing: verify-installation.sh"
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
# Test: Script runs successfully
# ============================================
test_start "Script runs successfully"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Verification"; then
    test_pass
fi

# ============================================
# Test: Checks core dependencies
# ============================================
test_start "Checks core dependencies"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "bash" && \
   assert_contains "$output" "jq" && \
   assert_contains "$output" "git"; then
    test_pass
fi

# ============================================
# Test: Checks scripts exist
# ============================================
test_start "Checks scripts exist"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "quality-gates.sh" && \
   assert_contains "$output" "install.sh"; then
    test_pass
fi

# ============================================
# Test: Checks hooks exist
# ============================================
test_start "Checks hooks exist"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "hooks.json" && \
   assert_contains "$output" "quality-gate-enforcer.sh"; then
    test_pass
fi

# ============================================
# Test: Reports summary
# ============================================
test_start "Reports summary with counts"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Total" && \
   assert_contains "$output" "Passed"; then
    test_pass
fi

# ============================================
# Test: All checks pass
# ============================================
test_start "All checks pass in current environment"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "All verifications passed" || \
   assert_contains "$output" "AIDA is ready"; then
    test_pass
else
    # Check if failed count is 0
    if echo "$output" | grep -q "Failed:.*0"; then
        test_pass
    else
        test_fail "Some verification checks failed"
    fi
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
# Test: Checks optional tools
# ============================================
test_start "Checks optional tools"
if grep -qE "jj|grepai|fzf" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check optional tools"
fi

# ============================================
# Test: Checks enhancement scripts
# ============================================
test_start "Checks enhancement scripts"
if grep -q "enhancement-queue.sh" "$SCRIPT" && \
   grep -q "semantic-search.sh" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check enhancement scripts"
fi

# ============================================
# Test: Has check function
# ============================================
test_start "Has check function"
if grep -q 'check()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have check function"
fi

# ============================================
# Test: Has check_optional function
# ============================================
test_start "Has check_optional function"
if grep -q 'check_optional()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have check_optional function"
fi

# ============================================
# Test: Checks skills directory
# ============================================
test_start "Checks skills directory"
if grep -qE "skills/|SKILL.md" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check skills directory"
fi

print_summary
