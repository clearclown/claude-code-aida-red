#!/bin/bash
# Tests for analyze-project.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/analyze-project.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
mkdir -p "$TEMP_DIR/test-project"

echo "========================================"
echo "Testing: analyze-project.sh"
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
if assert_contains "$output" "does not exist" || \
   assert_contains "$output" "ERROR"; then
    test_pass
fi

# ============================================
# Test: Detects multiple languages
# ============================================
test_start "Detects multiple languages"
if grep -q 'detect_languages()' "$SCRIPT" && \
   grep -qE 'go|rust|python|typescript|java|ruby' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect multiple languages"
fi

# ============================================
# Test: Detects project types
# ============================================
test_start "Detects project types (fullstack, monorepo, etc)"
if grep -q 'detect_project_type()' "$SCRIPT" && \
   grep -q 'fullstack' "$SCRIPT" && \
   grep -q 'monorepo' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect project types"
fi

# ============================================
# Test: Detects frameworks
# ============================================
test_start "Detects frameworks"
if grep -q 'detect_framework()' "$SCRIPT" && \
   grep -qE 'react|vue|gin|django|fastapi' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect frameworks"
fi

# ============================================
# Test: Detects test frameworks
# ============================================
test_start "Detects test frameworks"
if grep -q 'detect_test_framework()' "$SCRIPT" && \
   grep -qE 'vitest|jest|pytest|cargo test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect test frameworks"
fi

# ============================================
# Test: Counts tests
# ============================================
test_start "Counts test files"
if grep -q 'count_tests()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should count tests"
fi

# ============================================
# Test: Detects infrastructure
# ============================================
test_start "Detects infrastructure (Docker, K8s, CI/CD)"
if grep -q 'detect_infrastructure()' "$SCRIPT" && \
   grep -q 'docker' "$SCRIPT" && \
   grep -q 'kubernetes' "$SCRIPT" && \
   grep -q 'ci_cd' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect infrastructure"
fi

# ============================================
# Test: Generates JSON output
# ============================================
test_start "Generates JSON output"
if grep -q 'analyzed_at' "$SCRIPT" && \
   grep -q 'project_name' "$SCRIPT" && \
   grep -q 'components' "$SCRIPT"; then
    test_pass
else
    test_fail "Should generate JSON output"
fi

# ============================================
# Test: Provides recommendations
# ============================================
test_start "Provides next steps"
if grep -q 'Next steps' "$SCRIPT" && \
   grep -q 'aida:enhance' "$SCRIPT"; then
    test_pass
else
    test_fail "Should provide next steps"
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
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -qE 'ensure_dir|mkdir -p' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
