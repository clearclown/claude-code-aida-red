#!/bin/bash
# Tests for resource-monitor.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/resource-monitor.sh"

echo "========================================"
echo "Testing: resource-monitor.sh"
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
if assert_contains "$output" "AIDA Resource Monitor" && \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Status command returns valid output
# ============================================
test_start "Status command returns valid output"
output=$(run_script "$SCRIPT" status 2>&1) || true
if assert_contains "$output" "Memory:" && \
   assert_contains "$output" "CPU:" && \
   assert_contains "$output" "PIDs:"; then
    test_pass
fi

# ============================================
# Test: Optimal command returns a number
# ============================================
test_start "Optimal command returns a number"
output=$(run_script "$SCRIPT" optimal 2>&1) || true
if [[ "$output" =~ ^[0-9]+$ ]]; then
    test_pass
else
    test_fail "Expected a number, got: $output"
fi

# ============================================
# Test: JSON output is valid
# ============================================
test_start "JSON output is valid"
output=$(run_script "$SCRIPT" json 2>&1) || true
if assert_json_valid "$output"; then
    # Check required fields
    if assert_json_field "$output" '.memory.total_gb' && \
       assert_json_field "$output" '.cpu.cores' && \
       assert_json_field "$output" '.scaling.optimal'; then
        test_pass
    fi
fi

# ============================================
# Test: JSON contains scaling config
# ============================================
test_start "JSON contains scaling config"
output=$(run_script "$SCRIPT" json 2>&1) || true
if echo "$output" | jq -e '.scaling.config.memory_per_agent_gb' >/dev/null 2>&1; then
    test_pass
else
    test_fail "Missing scaling config in JSON"
fi

# ============================================
# Test: Environment variables affect output
# ============================================
test_start "Environment variables affect output"
output1=$(run_script "$SCRIPT" optimal 2>&1) || true
output2=$(MAX_AGENTS=3 run_script "$SCRIPT" optimal 2>&1) || true

# With MAX_AGENTS=3, optimal should be at most 3
if [[ "$output2" =~ ^[0-9]+$ ]] && [[ "$output2" -le 3 ]]; then
    test_pass
else
    test_fail "MAX_AGENTS=3 should limit optimal to 3, got: $output2"
fi

# ============================================
# Test: Unknown command shows error
# ============================================
test_start "Unknown command shows error"
output=$(run_script "$SCRIPT" invalidcommand 2>&1) || true
if assert_contains "$output" "Unknown command"; then
    test_pass
fi

# ============================================
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q 'source.*lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source common.sh"
fi

# ============================================
# Test: Supports watch command
# ============================================
test_start "Supports watch command"
if grep -qE "watch\)" "$SCRIPT" && grep -q 'watch_resources()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support watch command"
fi

# ============================================
# Test: Configuration via environment variables
# ============================================
test_start "Configurable via environment variables"
if grep -qE "MEMORY_PER_AGENT_GB|MIN_FREE_MEMORY_GB|MAX_PID_USAGE_PERCENT" "$SCRIPT"; then
    test_pass
else
    test_fail "Should be configurable via environment variables"
fi

# ============================================
# Test: Has get_memory_info function
# ============================================
test_start "Has get_memory_info function"
if grep -q 'get_memory_info()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have get_memory_info function"
fi

# ============================================
# Test: Has get_cpu_info function
# ============================================
test_start "Has get_cpu_info function"
if grep -q 'get_cpu_info()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have get_cpu_info function"
fi

# ============================================
# Test: Has calculate_optimal_agents function
# ============================================
test_start "Has calculate_optimal_agents function"
if grep -q 'calculate_optimal_agents()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have calculate_optimal_agents function"
fi

print_summary
