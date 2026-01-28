#!/bin/bash
# Test: Stop Hooks Integration
# Validates all Stop hooks follow official Claude Code format
# Reference: https://docs.anthropic.com/en/docs/claude-code/hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

HOOKS_DIR="$SCRIPT_DIR/../hooks/stop"

echo "========================================"
echo "Testing: Stop Hooks Integration"
echo "========================================"
echo ""

# ============================================
# Test: All hooks exist
# ============================================
test_start "All required hooks exist"
hooks_exist=true
for hook in quality-gate-enforcer.sh enhance-gate.sh subagent-validator.sh; do
    if [[ ! -f "$HOOKS_DIR/$hook" ]]; then
        hooks_exist=false
        echo "Missing: $hook" >&2
    fi
done
if $hooks_exist; then
    test_pass
else
    test_fail "Some hooks are missing"
fi

# ============================================
# Test: All hooks are executable
# ============================================
test_start "All hooks are executable"
all_executable=true
for hook in "$HOOKS_DIR"/*.sh; do
    if [[ ! -x "$hook" ]]; then
        all_executable=false
        echo "Not executable: $hook" >&2
    fi
done
if $all_executable; then
    test_pass
else
    test_fail "Some hooks are not executable"
fi

# ============================================
# Test: All hooks have valid bash syntax
# ============================================
test_start "All hooks have valid bash syntax"
all_valid=true
for hook in "$HOOKS_DIR"/*.sh; do
    if ! bash -n "$hook" 2>/dev/null; then
        all_valid=false
        echo "Syntax error: $hook" >&2
    fi
done
if $all_valid; then
    test_pass
else
    test_fail "Some hooks have syntax errors"
fi

# ============================================
# Test: All hooks source common.sh
# ============================================
test_start "All hooks source common.sh"
all_source=true
for hook in "$HOOKS_DIR"/*.sh; do
    if ! grep -q "source.*common.sh" "$hook"; then
        all_source=false
        echo "Missing common.sh: $hook" >&2
    fi
done
if $all_source; then
    test_pass
else
    test_fail "Some hooks don't source common.sh"
fi

# ============================================
# Test: Block decision uses correct format
# ============================================
test_start "Block decision uses correct JSON format"
all_correct=true
for hook in "$HOOKS_DIR"/*.sh; do
    # Check for correct block format (either inline JSON or utility function)
    if grep -q "decision.*block" "$hook" || grep -q "output_block" "$hook"; then
        if ! grep -qE '"decision": "block"|output_block' "$hook"; then
            all_correct=false
            echo "Incorrect block format: $hook" >&2
        fi
    fi
done
if $all_correct; then
    test_pass
else
    test_fail "Some hooks use incorrect block format"
fi

# ============================================
# Test: Allow decision uses null (not "approve")
# ============================================
test_start "Allow decision uses null (not approve)"
all_null=true
for hook in "$HOOKS_DIR"/*.sh; do
    # Check that allow uses null, not "approve"
    if grep -q '"decision": "approve"' "$hook"; then
        all_null=false
        echo "Uses 'approve' instead of null: $hook" >&2
    fi
done
if $all_null; then
    test_pass
else
    test_fail "Some hooks use 'approve' instead of null"
fi

# ============================================
# Test: Hooks use correct exit codes (Official: exit 0 always, decision:block for blocking)
# ============================================
test_start "Hooks use exit 0 (JSON requires exit 0 for processing)"
all_codes=true
for hook in "$HOOKS_DIR"/*.sh; do
    has_exit_0=$(grep -c "exit 0" "$hook" 2>/dev/null | tr -d ' \n' || echo "0")
    has_exit_0=${has_exit_0:-0}

    # Official Claude Code format: exit 0 for JSON to be processed
    # decision:block in JSON handles the blocking, not exit code 2
    if [[ "$has_exit_0" -eq 0 ]]; then
        all_codes=false
        echo "Missing exit 0: $hook" >&2
    fi
done
if $all_codes; then
    test_pass
else
    test_fail "Some hooks missing exit 0"
fi

# ============================================
# Test: Hooks output valid JSON on block
# ============================================
test_start "Block output is valid JSON structure"
valid_json=true
for hook in "$HOOKS_DIR"/*.sh; do
    # Extract JSON blocks and validate structure (inline or utility function)
    if grep -qE '"decision": "block"|output_block' "$hook"; then
        # Check for required fields in block response (inline or via utility function)
        if ! grep -qE '"reason"|output_block' "$hook"; then
            valid_json=false
            echo "Missing 'reason' field: $hook" >&2
        fi
    fi
done
if $valid_json; then
    test_pass
else
    test_fail "Some hooks have invalid JSON structure"
fi

# ============================================
# Test: Hooks check for session file
# ============================================
test_start "Hooks check for session file"
all_session=true
for hook in "$HOOKS_DIR"/*.sh; do
    if ! grep -q "SESSION_FILE\|session.json" "$hook"; then
        all_session=false
        echo "No session check: $hook" >&2
    fi
done
if $all_session; then
    test_pass
else
    test_fail "Some hooks don't check session"
fi

# ============================================
# Test: Hooks handle missing session gracefully
# ============================================
test_start "Hooks handle missing session gracefully"
graceful=true
for hook in "$HOOKS_DIR"/*.sh; do
    # Should exit 0 (allow) when no session
    if grep -q "SESSION_FILE" "$hook"; then
        if ! grep -qE '(\[[ ]*![ ]*-f.*SESSION|\[\[.*!.*-f.*session).*exit 0' "$hook" && \
           ! grep -qE 'if \[\[.*!.*-f.*SESSION.*\]\]' "$hook"; then
            # Check for alternative pattern
            if ! grep -A2 'SESSION_FILE' "$hook" | grep -q "exit 0"; then
                graceful=false
                echo "May not handle missing session: $hook" >&2
            fi
        fi
    fi
done
if $graceful; then
    test_pass
else
    test_fail "Some hooks may not handle missing session"
fi

# ============================================
# Test: No deprecated "continue" format (Issue #198)
# ============================================
test_start "No deprecated 'continue' format (Issue #198)"
no_continue=true
for hook in "$HOOKS_DIR"/*.sh; do
    # Check for old format: {"continue": false}
    if grep -q '"continue":' "$hook"; then
        no_continue=false
        echo "Uses deprecated 'continue' format: $hook" >&2
    fi
done
if $no_continue; then
    test_pass
else
    test_fail "Some hooks use deprecated 'continue' format"
fi

# ============================================
# Test: Has stopReason field when blocking
# ============================================
test_start "Uses stopReason field when blocking"
has_reason=true
for hook in "$HOOKS_DIR"/*.sh; do
    if grep -qE '"decision": "block"|output_block' "$hook"; then
        # Should have stopReason or reason field (or use utility function which provides it)
        if ! grep -qE '"stopReason"|"reason"|output_block' "$hook"; then
            has_reason=false
            echo "Missing stopReason when blocking: $hook" >&2
        fi
    fi
done
if $has_reason; then
    test_pass
else
    test_fail "Some hooks missing stopReason field"
fi

# ============================================
# Test: Hooks use set -e or set -euo pipefail
# ============================================
test_start "Hooks use strict mode (set -e or set -euo pipefail)"
strict_mode=true
for hook in "$HOOKS_DIR"/*.sh; do
    if ! grep -qE 'set -e|set -euo pipefail' "$hook"; then
        strict_mode=false
        echo "Missing strict mode: $hook" >&2
    fi
done
if $strict_mode; then
    test_pass
else
    test_fail "Some hooks not using strict mode"
fi

# ============================================
# Test: Ralph-gate.sh exists (Issue #217)
# ============================================
test_start "Ralph-gate.sh exists for iteration tracking"
if [[ -f "$HOOKS_DIR/ralph-gate.sh" ]] && [[ -x "$HOOKS_DIR/ralph-gate.sh" ]]; then
    test_pass
else
    test_fail "ralph-gate.sh should exist and be executable"
fi

print_summary
