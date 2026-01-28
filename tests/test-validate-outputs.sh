#!/bin/bash
# Tests for validate-outputs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/validate-outputs.sh"

echo "========================================"
echo "Testing: validate-outputs.sh"
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
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "project-name"; then
    test_pass
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
# Test: Validates spec phase
# ============================================
test_start "Validates spec phase outputs"
if grep -q 'validate_spec()' "$SCRIPT" && \
   grep -q 'requirements.md' "$SCRIPT" && \
   grep -q 'design.md' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate spec outputs"
fi

# ============================================
# Test: Validates impl phase
# ============================================
test_start "Validates impl phase outputs"
if grep -q 'validate_impl()' "$SCRIPT" && \
   grep -q 'backend' "$SCRIPT" && \
   grep -q 'frontend' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate impl outputs"
fi

# ============================================
# Test: Supports phase selection
# ============================================
test_start "Supports phase selection (spec, impl, all)"
if grep -q 'PHASE' "$SCRIPT" && \
   grep -q 'spec)' "$SCRIPT" && \
   grep -q 'impl)' "$SCRIPT" && \
   grep -q 'all)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support phase selection"
fi

# ============================================
# Test: Checks backend structure
# ============================================
test_start "Checks backend structure"
if grep -q 'internal/models' "$SCRIPT" && \
   grep -q 'internal/handler' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check backend structure"
fi

# ============================================
# Test: Checks frontend structure
# ============================================
test_start "Checks frontend structure"
if grep -q 'package.json' "$SCRIPT" && \
   grep -q 'App.tsx' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check frontend structure"
fi

# ============================================
# Test: Validates Docker configuration
# ============================================
test_start "Validates Docker configuration"
if grep -q 'docker-compose.yml' "$SCRIPT" && \
   grep -q 'Dockerfile' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate Docker config"
fi

# ============================================
# Test: Reports summary
# ============================================
test_start "Reports validation summary"
if grep -q 'Validation Summary' "$SCRIPT" && \
   grep -q 'ERRORS' "$SCRIPT"; then
    test_pass
else
    test_fail "Should report summary"
fi

# ============================================
# Test: Prints usage on error
# ============================================
test_start "Prints usage on error"
if grep -qE 'echo.*Usage|Usage:' "$SCRIPT"; then
    test_pass
else
    test_fail "Should print usage on error"
fi

# ============================================
# Test: Validates tests directory
# ============================================
test_start "Validates tests directory"
if grep -qE 'e2e|test|tests' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate tests directory"
fi

# ============================================
# Test: Handles missing files gracefully
# ============================================
test_start "Handles missing files gracefully"
if grep -qE '\[\[ -f|\[\[ -d|if \[' "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle missing files"
fi

print_summary
