#!/bin/bash
# Tests for worktree management scripts
# Issue #220: Environment isolation via git worktree

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

echo "========================================"
echo "Testing: Worktree Management Scripts"
echo "========================================"
echo ""

# ============================================
# Test: init-worktree.sh
# ============================================
INIT_SCRIPT="$PROJECT_ROOT/scripts/init-worktree.sh"

test_start "init-worktree.sh exists and is executable"
if assert_file_exists "$INIT_SCRIPT" && assert_executable "$INIT_SCRIPT"; then
    test_pass
fi

test_start "init-worktree.sh has valid bash syntax"
if bash -n "$INIT_SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error"
fi

test_start "init-worktree.sh sources common library"
if grep -q "source.*lib/common.sh" "$INIT_SCRIPT"; then
    test_pass
else
    test_fail "Does not source common.sh"
fi

test_start "init-worktree.sh supports project name argument"
if grep -q "PROJECT\|project" "$INIT_SCRIPT"; then
    test_pass
else
    test_fail "Missing project name support"
fi

test_start "init-worktree.sh creates worktree directory"
if grep -qE "git worktree add|mkdir.*worktree" "$INIT_SCRIPT"; then
    test_pass
else
    test_fail "Missing worktree creation"
fi

test_start "init-worktree.sh supports branch creation"
if grep -q "branch\|-b\|--branch" "$INIT_SCRIPT"; then
    test_pass
else
    test_fail "Missing branch support"
fi

# ============================================
# Test: cleanup-worktree.sh
# ============================================
CLEANUP_SCRIPT="$PROJECT_ROOT/scripts/cleanup-worktree.sh"

test_start "cleanup-worktree.sh exists and is executable"
if assert_file_exists "$CLEANUP_SCRIPT" && assert_executable "$CLEANUP_SCRIPT"; then
    test_pass
fi

test_start "cleanup-worktree.sh has valid bash syntax"
if bash -n "$CLEANUP_SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error"
fi

test_start "cleanup-worktree.sh sources common library"
if grep -q "source.*lib/common.sh" "$CLEANUP_SCRIPT"; then
    test_pass
else
    test_fail "Does not source common.sh"
fi

test_start "cleanup-worktree.sh removes worktree"
if grep -q "worktree remove" "$CLEANUP_SCRIPT" || grep -q "rm -rf" "$CLEANUP_SCRIPT"; then
    test_pass
else
    test_fail "Missing worktree removal"
fi

test_start "cleanup-worktree.sh handles branch cleanup"
if grep -qE "git branch -d|git branch -D|delete.*branch" "$CLEANUP_SCRIPT"; then
    test_pass
else
    test_fail "Missing branch cleanup"
fi

# ============================================
# Test: jj-worktree.sh (Jujutsu alternative)
# ============================================
JJ_SCRIPT="$PROJECT_ROOT/scripts/jj-worktree.sh"

test_start "jj-worktree.sh exists and is executable"
if assert_file_exists "$JJ_SCRIPT" && assert_executable "$JJ_SCRIPT"; then
    test_pass
fi

test_start "jj-worktree.sh has valid bash syntax"
if bash -n "$JJ_SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error"
fi

test_start "jj-worktree.sh sources common library"
if grep -q "source.*lib/common.sh" "$JJ_SCRIPT"; then
    test_pass
else
    test_fail "Does not source common.sh"
fi

test_start "jj-worktree.sh supports jj commands"
if grep -q "jj " "$JJ_SCRIPT"; then
    test_pass
else
    test_fail "Missing jj support"
fi

test_start "jj-worktree.sh has fallback to git"
if grep -qE "git worktree|fallback|git" "$JJ_SCRIPT"; then
    test_pass
else
    test_fail "Missing git fallback"
fi

test_start "jj-worktree.sh supports new workspace creation"
if grep -qE "jj new|jj workspace|create" "$JJ_SCRIPT"; then
    test_pass
else
    test_fail "Missing workspace creation"
fi

print_summary
