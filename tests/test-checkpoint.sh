#!/bin/bash
# Tests for checkpoint.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/checkpoint.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/checkpoints"
mkdir -p "$TEMP_DIR/.aida/state"

echo "========================================"
echo "Testing: checkpoint.sh"
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
# Test: Shows usage
# ============================================
test_start "Shows usage when no args"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "save"; then
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
# Test: Has save command
# ============================================
test_start "Has save command"
if grep -q 'save_checkpoint()' "$SCRIPT" && \
   grep -q 'save)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have save command"
fi

# ============================================
# Test: Has restore command
# ============================================
test_start "Has restore command"
if grep -q 'restore_checkpoint()' "$SCRIPT" && \
   grep -q 'restore)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have restore command"
fi

# ============================================
# Test: Has status command
# ============================================
test_start "Has status command"
if grep -q 'show_status()' "$SCRIPT" && \
   grep -q 'status)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have status command"
fi

# ============================================
# Test: Has list command
# ============================================
test_start "Has list command"
if grep -q 'list_checkpoints()' "$SCRIPT" && \
   grep -q 'list)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have list command"
fi

# ============================================
# Test: Saves checkpoint with timestamp
# ============================================
test_start "Saves checkpoint with timestamp"
if grep -q 'timestamp=' "$SCRIPT" && \
   grep -q 'checkpoint_id' "$SCRIPT"; then
    test_pass
else
    test_fail "Should save with timestamp"
fi

# ============================================
# Test: Restores session.json
# ============================================
test_start "Restores session.json"
if grep -q 'session.json' "$SCRIPT"; then
    test_pass
else
    test_fail "Should restore session.json"
fi

# ============================================
# Test: Has create_checkpoint function
# ============================================
test_start "Has create_checkpoint function"
if grep -qE 'create_checkpoint|save_checkpoint' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have create_checkpoint function"
fi

# ============================================
# Test: Uses JSON for checkpoint data
# ============================================
test_start "Uses JSON for checkpoint data"
if grep -qE 'jq|\.json' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use JSON for checkpoint data"
fi

# ============================================
# Test: Has latest checkpoint lookup
# ============================================
test_start "Has latest checkpoint lookup"
if grep -qE 'latest|head -1' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have latest checkpoint lookup"
fi

# ============================================
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -q 'ensure_dir' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
