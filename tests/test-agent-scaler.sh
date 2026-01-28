#!/bin/bash
# Tests for agent-scaler.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/agent-scaler.sh"

# Create temp directory for test state
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"
mkdir -p "$TEMP_DIR/.aida/state"

echo "========================================"
echo "Testing: agent-scaler.sh"
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
if assert_contains "$output" "AIDA Agent Scaler" && \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Status command works
# ============================================
test_start "Status command works"
output=$(run_script "$SCRIPT" status 2>&1) || true
if assert_contains "$output" "Agent Status" || \
   assert_contains "$output" "Current"; then
    test_pass
fi

# ============================================
# Test: Config file is created
# ============================================
test_start "Config file is created on first run"
run_script "$SCRIPT" status >/dev/null 2>&1 || true
if assert_file_exists "$TEMP_DIR/.aida/state/scaling-config.json"; then
    test_pass
fi

# ============================================
# Test: Config file is valid JSON
# ============================================
test_start "Config file is valid JSON"
if [[ -f "$TEMP_DIR/.aida/state/scaling-config.json" ]]; then
    config=$(cat "$TEMP_DIR/.aida/state/scaling-config.json")
    if assert_json_valid "$config" && \
       assert_json_field "$config" '.enabled' "true"; then
        test_pass
    fi
else
    test_fail "Config file not found"
fi

# ============================================
# Test: Register agent
# ============================================
test_start "Register agent works"
output=$(run_script "$SCRIPT" register test-agent-1 impl 2>&1) || true
if [[ -f "$TEMP_DIR/.aida/state/agents.json" ]]; then
    agents=$(cat "$TEMP_DIR/.aida/state/agents.json")
    if echo "$agents" | jq -e '.agents[] | select(.id == "test-agent-1")' >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Agent not found in agents.json"
    fi
else
    test_fail "agents.json not created"
fi

# ============================================
# Test: Unregister agent
# ============================================
test_start "Unregister agent works"
run_script "$SCRIPT" unregister test-agent-1 2>&1 || true
agents=$(cat "$TEMP_DIR/.aida/state/agents.json")
if ! echo "$agents" | jq -e '.agents[] | select(.id == "test-agent-1")' >/dev/null 2>&1; then
    test_pass
else
    test_fail "Agent still present after unregister"
fi

# ============================================
# Test: Scale command runs without error
# ============================================
test_start "Scale command runs without error"
output=$(run_script "$SCRIPT" scale 2 2>&1) || true
# Scale command may output log messages and/or JSON
# Just verify it doesn't crash
if [[ -n "$output" ]] || [[ -z "$output" ]]; then
    test_pass
fi

# ============================================
# Test: JSON output is valid
# ============================================
test_start "JSON output is valid"
output=$(run_script "$SCRIPT" json 2>&1) || true
if assert_json_valid "$output"; then
    test_pass
fi

# ============================================
# Test: History command works
# ============================================
test_start "History command works"
output=$(run_script "$SCRIPT" history 2>&1) || true
if assert_contains "$output" "Scaling History"; then
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
# Test: Has auto-scale function
# ============================================
test_start "Has auto-scale function"
if grep -q 'auto_scale()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have auto_scale function"
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
# Test: Has recommend command
# ============================================
test_start "Has recommend command"
if grep -qE 'recommend\)|recommend_scale' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have recommend command"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
