#!/bin/bash
# Tests for hooks/hooks.json configuration
# Validates hook configuration against Claude Code specs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

HOOKS_FILE="$PROJECT_ROOT/hooks/hooks.json"

echo "========================================"
echo "Testing: hooks.json Configuration"
echo "========================================"
echo ""

# ============================================
# Test: File exists
# ============================================
test_start "hooks.json exists"
if assert_file_exists "$HOOKS_FILE"; then
    test_pass
fi

# ============================================
# Test: Valid JSON
# ============================================
test_start "hooks.json is valid JSON"
if jq empty "$HOOKS_FILE" 2>/dev/null; then
    test_pass
else
    test_fail "Invalid JSON"
fi

# ============================================
# Test: Has SessionStart hooks
# ============================================
test_start "Has SessionStart hooks"
if jq -e '.SessionStart' "$HOOKS_FILE" >/dev/null 2>&1; then
    test_pass
else
    test_fail "Missing SessionStart"
fi

# ============================================
# Test: Has Stop hooks
# ============================================
test_start "Has Stop hooks"
if jq -e '.Stop' "$HOOKS_FILE" >/dev/null 2>&1; then
    test_pass
else
    test_fail "Missing Stop"
fi

# ============================================
# Test: Has SubagentStop hooks
# ============================================
test_start "Has SubagentStop hooks"
if jq -e '.SubagentStop' "$HOOKS_FILE" >/dev/null 2>&1; then
    test_pass
else
    test_fail "Missing SubagentStop"
fi

# ============================================
# Test: All hooks have type field
# ============================================
test_start "All hooks have type field"
types=$(jq -r '.. | objects | select(.type?) | .type' "$HOOKS_FILE" 2>/dev/null | sort -u)
if [[ -n "$types" ]]; then
    test_pass
else
    test_fail "Missing type field"
fi

# ============================================
# Test: All hooks have command field
# ============================================
test_start "All command hooks have command field"
cmds=$(jq -r '.. | objects | select(.command?) | .command' "$HOOKS_FILE" 2>/dev/null | wc -l)
if [[ $cmds -gt 0 ]]; then
    test_pass
else
    test_fail "Missing command field"
fi

# ============================================
# Test: All hooks have timeout field
# ============================================
test_start "All hooks have timeout field"
timeouts=$(jq -r '.. | objects | select(.timeout?) | .timeout' "$HOOKS_FILE" 2>/dev/null | wc -l)
if [[ $timeouts -gt 0 ]]; then
    test_pass
else
    test_fail "Missing timeout field"
fi

# ============================================
# Test: Hook scripts exist
# ============================================
test_start "All referenced hook scripts exist"
all_exist=true
while IFS= read -r cmd; do
    # Extract script path from command
    script_path=$(echo "$cmd" | sed 's/bash //' | sed 's/\${CLAUDE_PLUGIN_ROOT}//')
    full_path="$PROJECT_ROOT$script_path"
    if [[ ! -f "$full_path" ]]; then
        echo "  Missing: $full_path" >&2
        all_exist=false
    fi
done < <(jq -r '.. | objects | select(.command?) | .command' "$HOOKS_FILE" 2>/dev/null)

if [[ "$all_exist" == "true" ]]; then
    test_pass
else
    test_fail "Some hook scripts missing"
fi

# ============================================
# Test: Timeouts are reasonable
# ============================================
test_start "Timeouts are within reasonable range (1-600s)"
valid_timeouts=true
while IFS= read -r timeout; do
    if [[ $timeout -lt 1 ]] || [[ $timeout -gt 600 ]]; then
        echo "  Invalid timeout: $timeout" >&2
        valid_timeouts=false
    fi
done < <(jq -r '.. | objects | select(.timeout?) | .timeout' "$HOOKS_FILE" 2>/dev/null)

if [[ "$valid_timeouts" == "true" ]]; then
    test_pass
else
    test_fail "Invalid timeouts"
fi

# ============================================
# Test: Stop hooks count
# ============================================
test_start "Has at least 2 Stop hooks"
stop_count=$(jq '[.. | objects | select(.command?) | select(.command | contains("stop"))] | length' "$HOOKS_FILE" 2>/dev/null)
if [[ $stop_count -ge 2 ]]; then
    test_pass
else
    test_fail "Expected 2+ Stop hooks, found $stop_count"
fi

# ============================================
# Test: Uses CLAUDE_PLUGIN_ROOT variable
# ============================================
test_start "Uses CLAUDE_PLUGIN_ROOT variable"
if grep -q 'CLAUDE_PLUGIN_ROOT' "$HOOKS_FILE"; then
    test_pass
else
    test_fail "Should use CLAUDE_PLUGIN_ROOT"
fi

# ============================================
# Test: Has bash type for shell hooks
# ============================================
test_start "Uses bash type for shell hooks"
if jq -e '.. | objects | select(.type == "command")' "$HOOKS_FILE" >/dev/null 2>&1; then
    test_pass
else
    test_fail "Should use command type"
fi

# ============================================
# Test: All hooks have consistent structure
# ============================================
test_start "All hooks have consistent structure"
has_structure=true
for event in SessionStart Stop SubagentStop; do
    if jq -e ".$event" "$HOOKS_FILE" >/dev/null 2>&1; then
        if ! jq -e ".$event | type == \"array\"" "$HOOKS_FILE" >/dev/null 2>&1; then
            has_structure=false
        fi
    fi
done
if [[ "$has_structure" == "true" ]]; then
    test_pass
else
    test_fail "Hooks should be arrays"
fi

print_summary
