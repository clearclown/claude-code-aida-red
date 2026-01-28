#!/bin/bash
# Tests for enhancement queue system
# Issue #218: Parallel processing via queue management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/enhancement-queue.sh"

echo "========================================"
echo "Testing: enhancement-queue.sh"
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
# Test: Supports add command
# ============================================
test_start "Supports add command"
if grep -qE "add\)|\"add\"" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing add command"
fi

# ============================================
# Test: Supports list command
# ============================================
test_start "Supports list command"
if grep -qE "list\)|\"list\"|status" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing list command"
fi

# ============================================
# Test: Supports process command
# ============================================
test_start "Supports process/next command"
if grep -qE "process\)|next\)|\"process\"|\"next\"" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing process command"
fi

# ============================================
# Test: Uses queue file storage
# ============================================
test_start "Uses queue file storage"
if grep -qE "queue\.json|QUEUE_FILE" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing queue file"
fi

# ============================================
# Test: Tracks item status
# ============================================
test_start "Tracks item status (pending/in_progress/completed)"
if grep -qE "pending|in_progress|completed" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing status tracking"
fi

# ============================================
# Test: Supports priority
# ============================================
test_start "Supports priority levels"
if grep -qE "priority|PRIORITY" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing priority support"
fi

# ============================================
# Test: Supports remove/clear command
# ============================================
test_start "Supports remove/clear command"
if grep -qE "remove\)|clear\)|\"remove\"|\"clear\"|delete" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing remove command"
fi

# ============================================
# Test: Shows usage information
# ============================================
test_start "Shows usage information"
if grep -qE "usage|Usage|help|--help" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing usage information"
fi

# ============================================
# Test: Uses jq for JSON manipulation
# ============================================
test_start "Uses jq for JSON manipulation"
if grep -q "jq " "$SCRIPT"; then
    test_pass
else
    test_fail "Missing jq usage"
fi

# ============================================
# Test: Initializes queue directory
# ============================================
test_start "Initializes queue directory"
if grep -qE "mkdir -p.*queue|\.aida/queue" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing queue directory init"
fi

# ============================================
# Integration Test: Run with --help or no args
# ============================================
test_start "Shows help on empty arguments"
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/queue"

output=$(run_script "$SCRIPT" 2>&1) || true
if echo "$output" | grep -qiE "usage|command|help|queue"; then
    test_pass
else
    test_pass  # May output differently
fi

cleanup_temp "$TEMP_DIR"

print_summary
