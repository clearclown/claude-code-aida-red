#!/bin/bash
# Tests for hooks/post-tool-use/verify-edit.sh
# PostToolUse hook for edit verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/hooks/post-tool-use/verify-edit.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/scripts/lib" "$TEMP_DIR/.aida/state" "$TEMP_DIR/.aida/tdd-evidence"
cp "$PROJECT_ROOT/scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

echo "========================================"
echo "Testing: verify-edit.sh (PostToolUse)"
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
# Test: Reads stdin for input
# ============================================
test_start "Reads stdin for tool input"
if grep -q 'INPUT=\$(cat)' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing stdin reading"
fi

# ============================================
# Test: Extracts tool name
# ============================================
test_start "Extracts tool name from input"
if grep -q "tool_name" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing tool_name extraction"
fi

# ============================================
# Test: Checks for Edit tool
# ============================================
test_start "Checks for Edit tool"
if grep -q '"Edit"' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing Edit tool check"
fi

# ============================================
# Test: Checks for Write tool
# ============================================
test_start "Checks for Write tool"
if grep -q '"Write"' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing Write tool check"
fi

# ============================================
# Test: Validates bash syntax
# ============================================
test_start "Validates bash file syntax"
if grep -q "bash -n" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing bash syntax validation"
fi

# ============================================
# Test: Validates JSON syntax
# ============================================
test_start "Validates JSON file syntax"
if grep -q "jq empty" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing JSON syntax validation"
fi

# ============================================
# Test: Validates Python syntax
# ============================================
test_start "Validates Python file syntax"
if grep -q "py_compile" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing Python syntax validation"
fi

# ============================================
# Test: Logs TDD evidence
# ============================================
test_start "Logs TDD evidence"
if grep -q "tdd-evidence" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing TDD evidence logging"
fi

# ============================================
# Integration: Non-edit operations pass through
# ============================================
test_start "Non-edit operations pass through"
result=$(echo '{"tool_name": "Read", "tool_input": {"file_path": "/tmp/test.txt"}}' | bash "$SCRIPT" 2>/dev/null)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    test_pass
else
    test_fail "Should exit 0 for non-edit operations"
fi

# ============================================
# Integration: Verify bash file validation
# ============================================
test_start "Validates bash files correctly"
echo '#!/bin/bash
echo "valid"' > "$TEMP_DIR/valid.sh"
result=$(echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$TEMP_DIR/valid.sh\"}}" | bash "$SCRIPT" 2>/dev/null)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    test_pass
else
    test_fail "Should pass for valid bash"
fi

# ============================================
# Test: Uses strict mode
# ============================================
test_start "Uses strict mode"
if grep -qE 'set -e|set -euo pipefail' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use strict mode"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
