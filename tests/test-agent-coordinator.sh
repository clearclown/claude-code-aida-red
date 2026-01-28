#!/bin/bash
# Tests for agent-coordinator.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/agent-coordinator.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/state"

echo "========================================"
echo "Testing: agent-coordinator.sh"
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
# Test: Help command works
# ============================================
test_start "Help command works"
output=$(run_script "$SCRIPT" help 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "Agent Coordinator"; then
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
# Test: Has fallback logging functions
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
# Test: Initializes state
# ============================================
test_start "Initializes coordinator state"
if grep -q 'init_state()' "$SCRIPT" && \
   grep -q 'coordinator.json' "$SCRIPT"; then
    test_pass
else
    test_fail "Should initialize state"
fi

# ============================================
# Test: Coordinates resources
# ============================================
test_start "Coordinates resources with related scripts"
if grep -q 'resource-monitor.sh' "$SCRIPT" && \
   grep -q 'agent-scaler.sh' "$SCRIPT" && \
   grep -q 'task-seeker.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should coordinate with related scripts"
fi

# ============================================
# Test: Has daemon mode
# ============================================
test_start "Has daemon mode"
if grep -q 'start_daemon()' "$SCRIPT" && \
   grep -q 'stop_daemon()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have daemon mode"
fi

# ============================================
# Test: Has dashboard mode
# ============================================
test_start "Has dashboard mode"
if grep -q 'dashboard)' "$SCRIPT" && \
   grep -q 'show_dashboard()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have dashboard mode"
fi

# ============================================
# Test: Generates JSON report
# ============================================
test_start "Generates JSON report"
if grep -q 'generate_report()' "$SCRIPT" && \
   grep -q 'report_timestamp' "$SCRIPT"; then
    test_pass
else
    test_fail "Should generate JSON report"
fi

# ============================================
# Test: Has quick actions
# ============================================
test_start "Has quick actions (scale, distribute)"
if grep -q 'quick_scale()' "$SCRIPT" && \
   grep -q 'quick_distribute()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have quick actions"
fi

# ============================================
# Test: Handles unknown command
# ============================================
test_start "Handles unknown command"
if grep -q 'Unknown command' "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle unknown command"
fi

# ============================================
# Test: Tracks coordination metrics
# ============================================
test_start "Tracks coordination metrics"
if grep -q 'tasks_distributed' "$SCRIPT" && \
   grep -q 'scaling_events' "$SCRIPT"; then
    test_pass
else
    test_fail "Should track metrics"
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
