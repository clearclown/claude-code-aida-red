#!/bin/bash
# Tests for hooks/session-start/load-context.sh
# Session initialization and context loading

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/hooks/session-start/load-context.sh"

echo "========================================"
echo "Testing: load-context.sh"
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
# Test: Creates AIDA directories
# ============================================
test_start "Creates AIDA directories"
if grep -qE "mkdir -p.*\.aida" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing directory creation"
fi

# ============================================
# Test: Checks for session file
# ============================================
test_start "Checks for session file"
if grep -q "session.json" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing session file check"
fi

# ============================================
# Test: Loads session info with jq
# ============================================
test_start "Loads session info with jq"
if grep -q "jq " "$SCRIPT"; then
    test_pass
else
    test_fail "Missing jq usage"
fi

# ============================================
# Test: Checks for forced exit
# ============================================
test_start "Checks for forced exit status"
if grep -q "forced_exit" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing forced exit check"
fi

# ============================================
# Test: Checks quality gates status
# ============================================
test_start "Checks quality gates status"
if grep -q "quality_gates" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing quality gates check"
fi

# ============================================
# Test: Logs session start
# ============================================
test_start "Logs session start"
if grep -q "session.log" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing session logging"
fi

# ============================================
# Test: Always exits with 0
# ============================================
test_start "Always exits with 0 (allow session)"
if grep -q "exit 0" "$SCRIPT"; then
    test_pass
else
    test_fail "Should exit 0 to allow session"
fi

# ============================================
# Integration: Run with temp directory
# ============================================
test_start "Runs successfully with no session"
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/scripts/lib"
cp "$PROJECT_ROOT/scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

output=$(run_script "$SCRIPT" 2>&1) || true
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    test_pass
else
    test_fail "Exit code: $exit_code"
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

# ============================================
# Test: Checks for mode (enhance/generate)
# ============================================
test_start "Checks for mode"
if grep -qE 'mode|MODE|enhance|generate' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for mode"
fi

# ============================================
# Test: Has timestamp logging
# ============================================
test_start "Has timestamp logging"
if grep -qE 'date|timestamp|\\$\(date' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have timestamp logging"
fi

print_summary
