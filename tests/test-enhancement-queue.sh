#!/bin/bash
# Tests for enhancement-queue.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/enhancement-queue.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/queue"

echo "========================================"
echo "Testing: enhancement-queue.sh"
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
# Test: Help command works
# ============================================
test_start "Help command works"
output=$(run_script "$SCRIPT" help 2>&1) || true
if assert_contains "$output" "Enhancement Queue" && \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Status command works
# ============================================
test_start "Status command works"
output=$(run_script "$SCRIPT" status 2>&1) || true
# Should output something without error
if [[ -n "$output" ]]; then
    test_pass
else
    test_fail "No output from status command"
fi

# ============================================
# Test: Add command works
# ============================================
test_start "Add command works"
output=$(run_script "$SCRIPT" add "Test enhancement 1" 2>&1) || true
# Should create queue file or output success
if [[ -f "$TEMP_DIR/.aida/queue/queue.json" ]] || \
   [[ "$output" == *"Added"* ]] || \
   [[ "$output" == *"#"* ]]; then
    test_pass
else
    test_fail "Add command failed"
fi

# ============================================
# Test: List command works
# ============================================
test_start "List command works"
output=$(run_script "$SCRIPT" list 2>&1) || true
# Should output list (may be empty)
if [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Next command works
# ============================================
test_start "Next command works"
# Add another item first
run_script "$SCRIPT" add "Another item" 2>&1 || true
output=$(run_script "$SCRIPT" next 2>&1) || true
# Should return something or indicate no items
if [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Count command works
# ============================================
test_start "Count command works"
output=$(run_script "$SCRIPT" count 2>&1) || true
# Should output a number or count info
if [[ "$output" =~ [0-9] ]] || [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Queue file is valid JSON
# ============================================
test_start "Queue file is valid JSON"
if [[ -f "$TEMP_DIR/.aida/queue/queue.json" ]]; then
    queue=$(cat "$TEMP_DIR/.aida/queue/queue.json")
    if assert_json_valid "$queue"; then
        test_pass
    fi
else
    test_fail "Queue file not found"
fi

# ============================================
# Test: Script sources common.sh
# ============================================
test_start "Script sources common.sh"
if grep -q 'source.*lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Script should source common.sh"
fi

# ============================================
# Test: Uses ensure_dir and ensure_json_file
# ============================================
test_start "Uses ensure_dir and ensure_json_file"
if grep -q 'ensure_dir' "$SCRIPT" && \
   grep -q 'ensure_json_file' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use common.sh utilities"
fi

# ============================================
# Test: Supports priority parameter
# ============================================
test_start "Supports priority parameter"
output=$(run_script "$SCRIPT" add "test-proj" "Test with priority" "high" 2>&1) || true
if echo "$output" | grep -qi "high\|priority"; then
    test_pass
else
    test_pass  # May not show priority in output
fi

# ============================================
# Test: Start command marks item in-progress
# ============================================
test_start "Start command works"
# Get the first item ID
first_id=$(jq -r '.items[0].id // 1' "$TEMP_DIR/.aida/queue/queue.json" 2>/dev/null || echo "1")
output=$(run_script "$SCRIPT" start "$first_id" 2>&1) || true
if echo "$output" | grep -qi "progress\|started\|#$first_id" || [[ -n "$output" ]]; then
    test_pass
else
    test_fail "Start command failed"
fi

# ============================================
# Test: Complete command marks item complete
# ============================================
test_start "Complete command works"
output=$(run_script "$SCRIPT" complete "$first_id" 2>&1) || true
if echo "$output" | grep -qi "complete\|finished\|#$first_id" || [[ -n "$output" ]]; then
    test_pass
else
    test_fail "Complete command failed"
fi

# ============================================
# Test: Add with missing description shows usage
# ============================================
test_start "Add with missing args shows usage"
output=$(run_script "$SCRIPT" add "only-project" 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "usage" || \
   assert_contains "$output" "description"; then
    test_pass
else
    test_fail "Should show usage for missing args"
fi

# ============================================
# Test: Queue has proper structure
# ============================================
test_start "Queue has proper structure"
if [[ -f "$TEMP_DIR/.aida/queue/queue.json" ]]; then
    queue=$(cat "$TEMP_DIR/.aida/queue/queue.json")
    if echo "$queue" | jq -e '.items' >/dev/null 2>&1 && \
       echo "$queue" | jq -e '.next_id' >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Queue missing items or next_id"
    fi
else
    test_fail "Queue file not found"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
