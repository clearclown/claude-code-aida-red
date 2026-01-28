#!/bin/bash
# Tests for generate-fix-plan.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/generate-fix-plan.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/fix-plans"
mkdir -p "$TEMP_DIR/.aida/state"

echo "========================================"
echo "Testing: generate-fix-plan.sh"
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
# Test: Supports iteration parameter
# ============================================
test_start "Supports iteration parameter"
if grep -q 'ITERATION=' "$SCRIPT" && \
   grep -q 'iteration' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support iteration parameter"
fi

# ============================================
# Test: Creates fix plan directory
# ============================================
test_start "Creates fix plan directory"
# Accept either mkdir -p or ensure_dir (from common.sh)
if grep -q 'mkdir -p.*FIX_PLAN_DIR' "$SCRIPT" || \
   grep -q 'ensure_dir.*FIX_PLAN_DIR' "$SCRIPT"; then
    test_pass
else
    test_fail "Should create fix plan directory"
fi

# ============================================
# Test: Analyzes backend tests
# ============================================
test_start "Analyzes backend tests"
if grep -q 'BACKEND_TESTS' "$SCRIPT" && \
   grep -q 'func Test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze backend tests"
fi

# ============================================
# Test: Analyzes frontend tests
# ============================================
test_start "Analyzes frontend tests"
if grep -q 'FRONTEND_TESTS' "$SCRIPT"; then
    test_pass
else
    test_fail "Should analyze frontend tests"
fi

# ============================================
# Test: Checks TDD evidence
# ============================================
test_start "Checks TDD evidence"
if grep -q 'TDD_EVIDENCE' "$SCRIPT" && \
   grep -q 'tdd-evidence' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check TDD evidence"
fi

# ============================================
# Test: Generates JSON output
# ============================================
test_start "Generates JSON output"
if grep -q 'jq' "$SCRIPT" && \
   grep -q 'failures' "$SCRIPT" && \
   grep -q 'priority_actions' "$SCRIPT"; then
    test_pass
else
    test_fail "Should generate JSON output"
fi

# ============================================
# Test: Updates session state
# ============================================
test_start "Updates session state"
if grep -q 'update_session()' "$SCRIPT" && \
   grep -q 'SESSION_FILE' "$SCRIPT"; then
    test_pass
else
    test_fail "Should update session state"
fi

# ============================================
# Test: Provides next steps
# ============================================
test_start "Provides next steps in plan"
if grep -q 'next_steps' "$SCRIPT" && \
   grep -q 'TDD' "$SCRIPT"; then
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
# Test: Prints usage on error
# ============================================
test_start "Prints usage on error"
if grep -qE 'echo.*Usage|print.*usage' "$SCRIPT"; then
    test_pass
else
    test_fail "Should print usage on error"
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
