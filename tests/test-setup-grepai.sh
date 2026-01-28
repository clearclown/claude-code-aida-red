#!/bin/bash
# Tests for setup-grepai.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/setup-grepai.sh"

echo "========================================"
echo "Testing: setup-grepai.sh"
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
# Test: Shows usage with --help
# ============================================
test_start "Shows usage with --help"
output=$(run_script "$SCRIPT" --help 2>&1) || true
if assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Supports --check option
# ============================================
test_start "Supports --check option"
if grep -qE "\-\-check" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --check option"
fi

# ============================================
# Test: Supports --install option
# ============================================
test_start "Supports --install option"
if grep -qE "\-\-install" "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --install option"
fi

# ============================================
# Test: Checks for Go installation
# ============================================
test_start "Checks for Go installation"
if grep -qE "go version|command -v go" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for Go"
fi

# ============================================
# Test: References grepai repository
# ============================================
test_start "References grepai repository"
if grep -q "yoanbernabeu/grepai" "$SCRIPT"; then
    test_pass
else
    test_fail "Should reference grepai repo"
fi

# ============================================
# Test: Checks for API keys
# ============================================
test_start "Checks for API keys"
if grep -qE "OPENAI_API_KEY|ANTHROPIC_API_KEY" "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for API keys"
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
# Test: Handles unknown options
# ============================================
test_start "Handles unknown options"
output=$(run_script "$SCRIPT" --unknown-option 2>&1) || true
if assert_contains "$output" "Unknown option"; then
    test_pass
else
    test_fail "Should show error for unknown options"
fi

# ============================================
# Test: Has check_grepai function
# ============================================
test_start "Has check_grepai function"
if grep -q 'check_grepai()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have check_grepai function"
fi

# ============================================
# Test: Has install_grepai function
# ============================================
test_start "Has install_grepai function"
if grep -q 'install_grepai()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have install_grepai function"
fi

# ============================================
# Test: Has usage function
# ============================================
test_start "Has usage function"
if grep -q 'usage()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have usage function"
fi

# ============================================
# Test: Uses go install for installation
# ============================================
test_start "Uses go install for installation"
if grep -q 'go install' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use go install"
fi

print_summary
