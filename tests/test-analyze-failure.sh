#!/bin/bash
# Tests for analyze-failure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/analyze-failure.sh"

echo "========================================"
echo "Testing: analyze-failure.sh"
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
# Test: Supports --gate option
# ============================================
test_start "Supports --gate option"
if grep -qE "\-\-gate=" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --gate option"
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
# Test: Analyzes backend build
# ============================================
test_start "Analyzes backend build"
if grep -qE "analyze_backend_build|Backend Build" "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze backend build"
fi

# ============================================
# Test: Analyzes test counts
# ============================================
test_start "Analyzes test counts"
if grep -qE "analyze_.*_tests|test_count" "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze test counts"
fi

# ============================================
# Test: Analyzes coverage
# ============================================
test_start "Analyzes coverage"
if grep -qE "analyze_coverage|coverage" "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze coverage"
fi

# ============================================
# Test: Analyzes TDD evidence
# ============================================
test_start "Analyzes TDD evidence"
if grep -qE "analyze_tdd_evidence|tdd-evidence" "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze TDD evidence"
fi

# ============================================
# Test: Provides fix suggestions
# ============================================
test_start "Provides fix suggestions"
if grep -qE "Add.*more|Run:|Create:" "$SCRIPT"; then
    test_pass
else
    test_fail "Should provide fix suggestions"
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
# Test: Has help command
# ============================================
test_start "Has help command"
if grep -qE 'help\)|--help|-h' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have help command"
fi

# ============================================
# Test: Has fix suggestions documentation
# ============================================
test_start "Has fix suggestions documentation"
if grep -qE 'fix.*suggest|suggestions' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have fix suggestions documentation"
fi

# ============================================
# Test: Has analyze functions
# ============================================
test_start "Has analyze functions"
if grep -qE 'analyze_' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have analyze functions"
fi

print_summary
