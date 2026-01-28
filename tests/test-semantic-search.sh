#!/bin/bash
# Tests for semantic-search.sh
# Issue #216: Token consumption reduction via grepai

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/semantic-search.sh"

echo "========================================"
echo "Testing: semantic-search.sh"
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
# Test: Supports grepai integration
# ============================================
test_start "Supports grepai integration"
if grep -q "grepai" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing grepai support"
fi

# ============================================
# Test: Has fallback or error for missing grepai
# ============================================
test_start "Has fallback or error for missing grepai"
if grep -qE "fallback|error|grep|rg" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing fallback"
fi

# ============================================
# Test: Supports query parameter
# ============================================
test_start "Supports query parameter"
if grep -qE "query|QUERY|\\\$1" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing query parameter"
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
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -q 'ensure_dir' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir from common.sh"
fi

# ============================================
# Test: Has cache functionality
# ============================================
test_start "Has cache functionality"
if grep -qE "CACHE|cache" "$SCRIPT"; then
    test_pass
else
    test_fail "Should have cache functionality"
fi

# ============================================
# Test: Supports max_results parameter
# ============================================
test_start "Supports max_results parameter"
if grep -qE "MAX_RESULTS|max_results|limit" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support max results"
fi

# ============================================
# Test: Shows efficiency report
# ============================================
test_start "Shows efficiency report"
if grep -qE "Efficiency|efficiency|token" "$SCRIPT"; then
    test_pass
else
    test_fail "Should show efficiency report"
fi

# ============================================
# Test: Shows usage when run without args
# ============================================
test_start "Shows usage when run without args"
# Create temp dir for test
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/search-cache"

output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "Semantic Search"; then
    test_pass
else
    test_fail "Should show usage when run without args"
fi
cleanup_temp "$TEMP_DIR"

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
