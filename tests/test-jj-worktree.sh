#!/bin/bash
# Tests for jj-worktree.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/jj-worktree.sh"

echo "========================================"
echo "Testing: jj-worktree.sh"
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
# Test: Help command works
# ============================================
test_start "Help command works"
output=$(run_script "$SCRIPT" help 2>&1) || true
if assert_contains "$output" "jj" || \
   assert_contains "$output" "worktree" || \
   assert_contains "$output" "Usage"; then
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
# Test: List command works (may require jj)
# ============================================
test_start "List command handles missing jj gracefully"
output=$(run_script "$SCRIPT" list 2>&1) || true
# Should either work or show helpful error
if [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Status command works
# ============================================
test_start "Status command works"
output=$(run_script "$SCRIPT" status 2>&1) || true
if [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Unknown command shows error
# ============================================
test_start "Unknown command shows error"
output=$(run_script "$SCRIPT" unknown-command 2>&1) || true
if assert_contains "$output" "Unknown" || assert_contains "$output" "usage" || assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Create without name shows usage (or jj not found)
# ============================================
test_start "Create without name shows usage or requires jj"
output=$(run_script "$SCRIPT" create 2>&1) || true
# Either shows usage for missing name, or jj not found error
if echo "$output" | grep -qE "Usage|usage|name|jj|not found"; then
    test_pass
else
    test_fail "Should show usage or jj requirement message"
fi

# ============================================
# Test: Switch without name shows usage
# ============================================
test_start "Switch without name shows usage"
output=$(run_script "$SCRIPT" switch 2>&1) || true
if assert_contains "$output" "Usage" || assert_contains "$output" "usage" || assert_contains "$output" "name"; then
    test_pass
fi

# ============================================
# Test: Delete without name shows usage
# ============================================
test_start "Delete without name shows usage"
output=$(run_script "$SCRIPT" delete 2>&1) || true
if assert_contains "$output" "Usage" || assert_contains "$output" "usage" || assert_contains "$output" "name"; then
    test_pass
fi

# ============================================
# Test: Script sources common.sh
# ============================================
test_start "Script sources common.sh"
if grep -q 'source.*lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Script should source common.sh"
fi

# ============================================
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -q 'ensure_dir' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir from common.sh"
fi

# ============================================
# Test: Uses require_command from common.sh
# ============================================
test_start "Uses require_command from common.sh"
if grep -q 'require_command' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use require_command from common.sh"
fi

# ============================================
# Test: Help shows all commands
# ============================================
test_start "Help shows all commands"
output=$(run_script "$SCRIPT" help 2>&1) || true
if assert_contains "$output" "create" && \
   assert_contains "$output" "list" && \
   assert_contains "$output" "switch" && \
   assert_contains "$output" "delete" && \
   assert_contains "$output" "status"; then
    test_pass
else
    test_fail "Help should show all commands"
fi

# ============================================
# Test: Script handles -h and --help flags
# ============================================
test_start "Script handles -h and --help flags"
output_h=$(run_script "$SCRIPT" -h 2>&1) || true
output_help=$(run_script "$SCRIPT" --help 2>&1) || true
if [[ -n "$output_h" ]] && [[ -n "$output_help" ]]; then
    test_pass
else
    test_fail "Should handle -h and --help flags"
fi

print_summary
