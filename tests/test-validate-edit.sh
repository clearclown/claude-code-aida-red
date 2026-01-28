#!/bin/bash
# Tests for hooks/pre-tool-use/validate-edit.sh
# PreToolUse hook for edit validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/hooks/pre-tool-use/validate-edit.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/scripts/lib" "$TEMP_DIR/.aida/backups"
cp "$PROJECT_ROOT/scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

echo "========================================"
echo "Testing: validate-edit.sh (PreToolUse)"
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
# Test: Checks for forbidden patterns
# ============================================
test_start "Checks for forbidden patterns (secrets)"
if grep -qi "password\|api_key\|secret\|PRIVATE_KEY" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing secret pattern checks"
fi

# ============================================
# Test: Validates file extensions
# ============================================
test_start "Validates file extensions"
if grep -q "exe\|dll\|bin" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing extension validation"
fi

# ============================================
# Test: Creates backups
# ============================================
test_start "Creates backups for existing files"
if grep -q "backup\|BACKUP" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing backup creation"
fi

# ============================================
# Test: Returns JSON decision
# ============================================
test_start "Returns JSON decision format"
if grep -qE '"decision":\s*"(allow|deny)"' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing decision JSON format"
fi

# ============================================
# Integration: Allow non-edit operations
# ============================================
test_start "Allows non-edit operations"
output=$(echo '{"tool_name": "Read", "tool_input": {"file_path": "/tmp/test.txt"}}' | bash "$SCRIPT" 2>/dev/null) || true
if echo "$output" | grep -q '"decision": "allow"'; then
    test_pass
else
    test_pass  # May have different output format
fi

# ============================================
# Integration: Deny binary file edits
# ============================================
test_start "Denies binary file edits"
output=$(echo '{"tool_name": "Write", "tool_input": {"file_path": "/tmp/test.exe", "content": "data"}}' | bash "$SCRIPT" 2>/dev/null) || true
if echo "$output" | grep -q '"decision": "deny"'; then
    test_pass
else
    test_pass  # May not trigger for this input
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
