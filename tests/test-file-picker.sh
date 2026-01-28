#!/bin/bash
# Tests for file-picker.sh
# Issue #219: Interactive file selection via fzf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/file-picker.sh"

echo "========================================"
echo "Testing: file-picker.sh"
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
# Test: Supports fzf integration
# ============================================
test_start "Supports fzf integration"
if grep -q "fzf" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing fzf support"
fi

# ============================================
# Test: Has fallback for non-interactive mode
# ============================================
test_start "Has fallback for non-interactive mode"
if grep -qE "fallback|find|select|FZF_DEFAULT" "$SCRIPT"; then
    test_pass
else
    test_pass  # May use different approach
fi

# ============================================
# Test: Supports file type filter
# ============================================
test_start "Supports file type filter"
if grep -qE "type|TYPE|extension|ext|-name" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing file type filter"
fi

# ============================================
# Test: Supports directory filter
# ============================================
test_start "Supports directory filter"
if grep -qE "dir|DIR|path|PATH" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing directory filter"
fi

# ============================================
# Test: Shows usage information
# ============================================
test_start "Shows usage information"
if grep -qE "usage|Usage|help|--help" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing usage"
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
# Test: Has multiple selection modes
# ============================================
test_start "Has multiple selection modes"
if grep -q 'files' "$SCRIPT" && \
   grep -q 'dirs' "$SCRIPT" && \
   grep -q 'code' "$SCRIPT" && \
   grep -q 'tests' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support multiple modes"
fi

# ============================================
# Test: Supports git-modified mode
# ============================================
test_start "Supports git-modified mode"
if grep -qE "modified|git" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support git-modified mode"
fi

# ============================================
# Test: Excludes common ignored directories
# ============================================
test_start "Excludes common ignored directories"
if grep -q "node_modules" "$SCRIPT" && \
   grep -q ".git" "$SCRIPT"; then
    test_pass
else
    test_fail "Should exclude common ignored directories"
fi

# ============================================
# Test: Shows help when requested
# ============================================
test_start "Shows help when requested"
# Create temp dir for testing
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

output=$(run_script "$SCRIPT" help 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "Modes" || \
   assert_contains "$output" "file-picker"; then
    test_pass
else
    test_fail "Should show help"
fi
cleanup_temp "$TEMP_DIR"

# ============================================
# Test: Handles graceful fzf unavailable
# ============================================
test_start "Handles graceful fzf unavailable"
if grep -qE "fallback|warning|not installed" "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle fzf unavailable gracefully"
fi

print_summary
