#!/bin/bash
# Tests for init-worktree.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/init-worktree.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: init-worktree.sh"
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
# Test: Supports jj backend
# ============================================
test_start "Supports jj backend"
if grep -qE "jj|jujutsu" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support jj backend"
fi

# ============================================
# Test: Supports git worktree backend
# ============================================
test_start "Supports git worktree backend"
if grep -qE "git worktree|git-worktree" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support git worktree backend"
fi

# ============================================
# Test: Creates isolated environment
# ============================================
test_start "Creates isolated environment"
if grep -qE "mkdir|create.*dir|worktree add" "$SCRIPT"; then
    test_pass
else
    test_fail "Should create isolated environment"
fi

# ============================================
# Test: Sets environment variables
# ============================================
test_start "Sets environment variables"
if grep -qE "export|AIDA_WORKTREE|WORKTREE_PATH" "$SCRIPT"; then
    test_pass
else
    test_fail "Should set environment variables"
fi

# ============================================
# Test: Supports branch naming
# ============================================
test_start "Supports branch naming"
if grep -qE "branch|BRANCH|aida-" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support branch naming"
fi

# ============================================
# Test: Has cleanup instructions
# ============================================
test_start "Has cleanup instructions or reference"
if grep -qE "cleanup|remove|delete" "$SCRIPT"; then
    test_pass
else
    test_fail "Should have cleanup instructions"
fi

# ============================================
# Test: Checks for required tools
# ============================================
test_start "Checks for required tools"
if grep -qE "command -v|which|hash" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for required tools"
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
# Test: Has help option
# ============================================
test_start "Has help option"
if grep -qE '\-\-help|-h\)|help\)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have help option"
fi

# ============================================
# Test: Accepts feature name
# ============================================
test_start "Accepts feature name"
if grep -qE 'FEATURE|feature|NAME' "$SCRIPT"; then
    test_pass
else
    test_fail "Should accept feature name"
fi

# ============================================
# Test: Supports --jj and --git backends
# ============================================
test_start "Supports --jj and --git backends"
if grep -qE '\-\-jj|\-\-git' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --jj and --git backends"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
