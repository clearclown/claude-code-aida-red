#!/bin/bash
# Tests for interactive-enhance.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/interactive-enhance.sh"

echo "========================================"
echo "Testing: interactive-enhance.sh"
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
# Test: Integrates with fzf
# ============================================
test_start "Integrates with fzf"
if grep -qE "fzf|file-picker" "$SCRIPT"; then
    test_pass
else
    test_fail "Should integrate with fzf"
fi

# ============================================
# Test: Integrates with grepai/semantic-search
# ============================================
test_start "Integrates with semantic search"
if grep -qE "grepai|semantic-search" "$SCRIPT"; then
    test_pass
else
    test_fail "Should integrate with semantic search"
fi

# ============================================
# Test: Supports --interactive flag
# ============================================
test_start "Supports --interactive flag"
if grep -qE "\-\-interactive|INTERACTIVE" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --interactive flag"
fi

# ============================================
# Test: Displays menu or prompts
# ============================================
test_start "Displays menu or prompts"
if grep -qE "select|menu|prompt|choose" "$SCRIPT"; then
    test_pass
else
    test_fail "Should display menu or prompts"
fi

# ============================================
# Test: Handles file selection
# ============================================
test_start "Handles file selection"
if grep -qE "select.*file|file.*select|FILES" "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle file selection"
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
# Test: Supports --batch flag
# ============================================
test_start "Supports --batch flag"
if grep -qE "\-\-batch|BATCH" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --batch flag"
fi

# ============================================
# Test: Supports --search option
# ============================================
test_start "Supports --search option"
if grep -qE "\-\-search=|SEARCH_QUERY" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --search option"
fi

# ============================================
# Test: Supports --files option
# ============================================
test_start "Supports --files option"
if grep -qE "\-\-files=|FILE_PATTERN" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --files option"
fi

# ============================================
# Test: Has check_dependencies function
# ============================================
test_start "Has check_dependencies function"
if grep -q 'check_dependencies()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have check_dependencies function"
fi

# ============================================
# Test: Has semantic_search function
# ============================================
test_start "Has semantic_search function"
if grep -q 'semantic_search()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have semantic_search function"
fi

print_summary
