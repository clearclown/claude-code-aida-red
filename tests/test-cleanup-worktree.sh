#!/bin/bash
# Tests for cleanup-worktree.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/cleanup-worktree.sh"

echo "========================================"
echo "Testing: cleanup-worktree.sh"
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
if assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Supports --force option
# ============================================
test_start "Supports --force option"
if grep -qE "\-\-force" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --force option"
fi

# ============================================
# Test: Supports --all option
# ============================================
test_start "Supports --all option"
if grep -qE "\-\-all" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --all option"
fi

# ============================================
# Test: Supports --list option
# ============================================
test_start "Supports --list option"
if grep -qE "\-\-list" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --list option"
fi

# ============================================
# Test: Handles jj backend
# ============================================
test_start "Handles jj backend cleanup"
if grep -qE "jj workspace|jj|jujutsu" "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle jj backend"
fi

# ============================================
# Test: Handles git worktree backend
# ============================================
test_start "Handles git worktree backend cleanup"
if grep -qE "git worktree remove|git.*worktree" "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle git worktree backend"
fi

# ============================================
# Test: Updates session file
# ============================================
test_start "Updates session file"
if grep -q "session.json" "$SCRIPT"; then
    test_pass
else
    test_fail "Should update session file"
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
# Test: Uses safe_jq_update
# ============================================
test_start "Uses safe_jq_update from common.sh"
if grep -q 'safe_jq_update' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use safe_jq_update"
fi

# ============================================
# Test: Supports --help option
# ============================================
test_start "Supports --help option"
if grep -qE "\-\-help|\-h\)" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --help option"
fi

# ============================================
# Test: Has list_worktrees function
# ============================================
test_start "Has list_worktrees function"
if grep -q 'list_worktrees()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have list_worktrees function"
fi

# ============================================
# Test: Handles branch deletion
# ============================================
test_start "Handles branch deletion on cleanup"
if grep -qE "branch -D|branch.*delete" "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle branch deletion"
fi

print_summary
