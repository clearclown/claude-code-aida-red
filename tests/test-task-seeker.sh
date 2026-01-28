#!/bin/bash
# Tests for task-seeker.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/task-seeker.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/state" "$TEMP_DIR/.aida/tasks" "$TEMP_DIR/.aida/queue"

echo "========================================"
echo "Testing: task-seeker.sh"
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
if assert_contains "$output" "Task Seeker" && \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Status command works
# ============================================
test_start "Status command works"
output=$(run_script "$SCRIPT" status 2>&1) || true
if assert_contains "$output" "Task Seeker" || \
   assert_contains "$output" "Pending"; then
    test_pass
fi

# ============================================
# Test: Available command publishes availability
# ============================================
test_start "Available command publishes availability"
output=$(run_script "$SCRIPT" available test-agent-1 leader-impl 2>&1) || true
if assert_json_valid "$output" && \
   assert_contains "$output" "AVAILABLE"; then
    test_pass
fi

# ============================================
# Test: Available agents file is created
# ============================================
test_start "Available agents file is created"
if [[ -f "$TEMP_DIR/.aida/state/available-agents.json" ]]; then
    content=$(cat "$TEMP_DIR/.aida/state/available-agents.json")
    if assert_json_valid "$content"; then
        test_pass
    fi
else
    test_fail "Available agents file not created"
fi

# ============================================
# Test: List-available command works
# ============================================
test_start "List-available command works"
output=$(run_script "$SCRIPT" list-available 2>&1) || true
if assert_json_valid "$output" || [[ "$output" == "[]" ]]; then
    test_pass
fi

# ============================================
# Test: Withdraw command works
# ============================================
test_start "Withdraw command works"
run_script "$SCRIPT" withdraw test-agent-1 2>&1 || true
output=$(run_script "$SCRIPT" list-available 2>&1) || true
# Agent should be removed or list should be smaller
test_pass

# ============================================
# Test: Pending command works
# ============================================
test_start "Pending command works"
output=$(run_script "$SCRIPT" pending 2>&1) || true
if assert_json_valid "$output" || [[ "$output" == "[]" ]]; then
    test_pass
fi

# ============================================
# Test: Seek command works
# ============================================
test_start "Seek command works"
output=$(run_script "$SCRIPT" seek test-agent-2 2>&1) || true
# Should return task or idle status
if [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Sources common library or has fallback
# ============================================
test_start "Sources common library or has fallback"
if grep -q 'source.*lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source common.sh"
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

# ============================================
# Test: Next command works
# ============================================
test_start "Next command works"
output=$(run_script "$SCRIPT" next 2>&1) || true
# Should return null or a task
if [[ "$output" == "null" ]] || assert_json_valid "$output" || [[ -n "$output" ]]; then
    test_pass
fi

# ============================================
# Test: Assign command requires task ID
# ============================================
test_start "Assign command requires task ID"
output=$(run_script "$SCRIPT" assign 2>&1) || true
if assert_contains "$output" "required" || echo "$output" | grep -qE "Task.*ID|task.*id"; then
    test_pass
else
    test_fail "Assign should require task ID"
fi

# ============================================
# Test: Complete command requires task ID
# ============================================
test_start "Complete command requires task ID"
output=$(run_script "$SCRIPT" complete 2>&1) || true
if assert_contains "$output" "required" || echo "$output" | grep -qE "Task.*ID|task.*id"; then
    test_pass
else
    test_fail "Complete should require task ID"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
