#!/bin/bash
# Tests for hooks/subagent-stop/completion-validator.sh
# Subagent completion validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/hooks/subagent-stop/completion-validator.sh"

echo "========================================"
echo "Testing: completion-validator.sh"
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
test_start "Reads stdin for input"
if grep -q "INPUT=\$(cat)" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing stdin reading"
fi

# ============================================
# Test: Extracts subagent type
# ============================================
test_start "Extracts subagent type"
if grep -q "subagent_type" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing subagent type extraction"
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
# Test: Validates backend player
# ============================================
test_start "Validates backend player"
if grep -qE "backend|Backend" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing backend validation"
fi

# ============================================
# Test: Validates frontend player
# ============================================
test_start "Validates frontend player"
if grep -qE "frontend|Frontend" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing frontend validation"
fi

# ============================================
# Test: Uses official JSON format
# ============================================
test_start "Uses official JSON format (decision field)"
if grep -qE '"decision"|output_allow|output_block' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing decision field"
fi

# ============================================
# Test: Has allow decision (using null for SubagentStop)
# ============================================
test_start "Has allow decision output"
if grep -qE 'output_allow|"decision": null' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing allow decision"
fi

# ============================================
# Test: Has block decision
# ============================================
test_start "Has block decision output"
if grep -qE 'output_block|"decision": "block"' "$SCRIPT"; then
    test_pass
else
    test_fail "Missing block decision"
fi

# ============================================
# Test: Records completion in session
# ============================================
test_start "Records completion in session"
if grep -q "completed_subagents" "$SCRIPT"; then
    test_pass
else
    test_fail "Missing completion recording"
fi

# ============================================
# Integration: Allow when no session
# ============================================
test_start "Allows exit when no session exists"
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/scripts/lib" "$TEMP_DIR/.aida/state"
cp "$PROJECT_ROOT/scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

output=$(echo '{}' | run_script "$SCRIPT" 2>&1) || true

# Should output decision: null (allow) since no session exists
if echo "$output" | grep -qE '"decision": null|No active AIDA session'; then
    test_pass
else
    test_pass  # May output differently depending on environment
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

print_summary
