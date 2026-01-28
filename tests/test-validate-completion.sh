#!/bin/bash
# Tests for validate-completion.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/validate-completion.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: validate-completion.sh"
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
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q 'lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source lib/common.sh"
fi

# ============================================
# Test: Has fallback logging
# ============================================
test_start "Has fallback logging functions"
if grep -q 'log_info()' "$SCRIPT" && \
   grep -q 'log_success()' "$SCRIPT" && \
   grep -q 'log_error()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have fallback logging"
fi

# ============================================
# Test: Validates backend
# ============================================
test_start "Validates backend directory"
if grep -q 'Backend Validation' "$SCRIPT" && \
   grep -q 'go.mod' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate backend"
fi

# ============================================
# Test: Validates frontend
# ============================================
test_start "Validates frontend directory"
if grep -q 'Frontend Validation' "$SCRIPT" && \
   grep -q 'package.json' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate frontend"
fi

# ============================================
# Test: Checks for test files
# ============================================
test_start "Checks for test files"
if grep -q '_test.go' "$SCRIPT" && \
   grep -q '\.test\.tsx' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for test files"
fi

# ============================================
# Test: Reports summary with counts
# ============================================
test_start "Reports summary with counts"
if grep -q 'Validation Summary' "$SCRIPT" && \
   grep -q 'Errors:' "$SCRIPT" && \
   grep -q 'Warnings:' "$SCRIPT"; then
    test_pass
else
    test_fail "Should report summary"
fi

# ============================================
# Test: Validates E2E tests
# ============================================
test_start "Validates E2E tests"
if grep -q 'E2E Tests Validation' "$SCRIPT"; then
    test_pass
else
    test_fail "Should validate E2E tests"
fi

# ============================================
# Test: Has exit codes for results
# ============================================
test_start "Has exit codes for results"
if grep -qE 'exit [012]|return [012]' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have exit codes"
fi

# ============================================
# Test: Checks Docker configuration
# ============================================
test_start "Checks Docker configuration"
if grep -qE 'Dockerfile|docker-compose' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check Docker configuration"
fi

# ============================================
# Test: Counts file structure
# ============================================
test_start "Counts file structure"
if grep -qE 'find.*wc|count|COUNT' "$SCRIPT"; then
    test_pass
else
    test_fail "Should count file structure"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
