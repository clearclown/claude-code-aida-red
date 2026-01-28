#!/bin/bash
# Tests for validate-frontend-deps.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/validate-frontend-deps.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: validate-frontend-deps.sh"
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
# Test: Checks Tailwind CSS dependencies
# ============================================
test_start "Checks Tailwind CSS dependencies"
if grep -q 'TAILWIND_DEPS' "$SCRIPT" && \
   grep -q 'tailwindcss' "$SCRIPT" && \
   grep -q 'postcss' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check Tailwind dependencies"
fi

# ============================================
# Test: Checks tailwind config
# ============================================
test_start "Checks tailwind.config exists"
if grep -q 'tailwind.config' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check tailwind config"
fi

# ============================================
# Test: Checks shadcn-ui dependencies
# ============================================
test_start "Checks shadcn-ui dependencies"
if grep -q 'SHADCN_DEPS' "$SCRIPT" && \
   grep -q '@radix-ui' "$SCRIPT" && \
   grep -q 'class-variance-authority' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check shadcn dependencies"
fi

# ============================================
# Test: Checks components directory
# ============================================
test_start "Checks components directory"
if grep -q 'components/ui' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check components directory"
fi

# ============================================
# Test: Checks utils.ts
# ============================================
test_start "Checks utils.ts for cn() function"
if grep -q 'utils.ts' "$SCRIPT" && \
   grep -q 'clsx' "$SCRIPT" && \
   grep -q 'twMerge' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check utils.ts"
fi

# ============================================
# Test: Checks React dependencies
# ============================================
test_start "Checks React dependencies"
if grep -q 'REACT_DEPS' "$SCRIPT" && \
   grep -q 'react' "$SCRIPT" && \
   grep -q 'react-dom' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check React dependencies"
fi

# ============================================
# Test: Provides fix instructions
# ============================================
test_start "Provides fix instructions"
if grep -q 'npm install' "$SCRIPT" && \
   grep -q 'shadcn-ui' "$SCRIPT"; then
    test_pass
else
    test_fail "Should provide fix instructions"
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
# Test: Checks node_modules
# ============================================
test_start "Checks node_modules directory"
if grep -qE 'node_modules|dependencies' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check node_modules"
fi

# ============================================
# Test: Reports summary
# ============================================
test_start "Reports validation summary"
if grep -qE 'Summary|ERRORS|WARNINGS' "$SCRIPT"; then
    test_pass
else
    test_fail "Should report summary"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
