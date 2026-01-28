#!/bin/bash
# Tests for validate-go-module.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/validate-go-module.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: validate-go-module.sh"
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
# Test: Handles missing directory
# ============================================
test_start "Handles missing directory"
output=$(run_script "$SCRIPT" "$TEMP_DIR/nonexistent" 2>&1) || true
if assert_contains "$output" "not found" || \
   assert_contains "$output" "Error"; then
    test_pass
fi

# ============================================
# Test: Checks go.mod exists
# ============================================
test_start "Checks go.mod exists"
if grep -q 'go.mod' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check go.mod"
fi

# ============================================
# Test: Checks go.sum exists
# ============================================
test_start "Checks go.sum exists"
if grep -q 'go.sum' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check go.sum"
fi

# ============================================
# Test: Checks module name
# ============================================
test_start "Checks module name"
if grep -q 'MODULE_NAME' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check module name"
fi

# ============================================
# Test: Checks Go version
# ============================================
test_start "Checks Go version"
if grep -q 'GO_VERSION' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check Go version"
fi

# ============================================
# Test: Checks project structure
# ============================================
test_start "Checks project structure (cmd, internal, pkg)"
if grep -qE 'cmd.*internal.*pkg|internal.*cmd' "$SCRIPT" || \
   (grep -q 'cmd/' "$SCRIPT" && grep -q 'internal/' "$SCRIPT"); then
    test_pass
else
    test_fail "Should check project structure"
fi

# ============================================
# Test: Checks compilation
# ============================================
test_start "Checks compilation"
if grep -q 'go build' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check compilation"
fi

# ============================================
# Test: Counts test files
# ============================================
test_start "Counts test files"
if grep -q 'TEST_FILES' "$SCRIPT" && \
   grep -q '_test.go' "$SCRIPT"; then
    test_pass
else
    test_fail "Should count test files"
fi

# ============================================
# Test: Reports summary
# ============================================
test_start "Reports validation summary"
if grep -q 'Validation Summary' "$SCRIPT"; then
    test_pass
else
    test_fail "Should report summary"
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
# Test: Checks dependencies
# ============================================
test_start "Checks dependencies"
if grep -qE 'dependencies|DEPS|imports' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check dependencies"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
