#!/bin/bash
# Tests for prompt-lint.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/prompt-lint.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
mkdir -p "$TEMP_DIR/agents" "$TEMP_DIR/skills"

echo "========================================"
echo "Testing: prompt-lint.sh"
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
if assert_contains "$output" "AIDA Prompt Linter" && \
   assert_contains "$output" "Usage"; then
    test_pass
fi

# ============================================
# Test: Lint valid prompt file
# ============================================
test_start "Lint valid prompt file"
cat << 'EOF' > "$TEMP_DIR/agents/test-agent.md"
---
name: test-agent
version: 1.0.0
---

# Test Agent

## Purpose
This is a test agent for validation.

## Instructions
Follow these steps to complete tasks.
EOF

output=$(run_script "$SCRIPT" lint "$TEMP_DIR/agents/test-agent.md" 2>&1) || true
if assert_contains "$output" "OK" || assert_contains "$output" "PASS"; then
    test_pass
fi

# ============================================
# Test: Detect unclosed code block
# ============================================
test_start "Detect unclosed code block"
cat << 'EOF' > "$TEMP_DIR/agents/bad-codeblock.md"
---
name: bad-agent
---

# Bad Agent

```javascript
console.log("unclosed")
EOF

output=$(run_script "$SCRIPT" lint "$TEMP_DIR/agents/bad-codeblock.md" 2>&1) || true
if assert_contains "$output" "Unclosed code block"; then
    test_pass
fi

# ============================================
# Test: Detect protocol version format
# ============================================
test_start "Accept protocol version format (X.Y)"
cat << 'EOF' > "$TEMP_DIR/agents/protocol-version.md"
---
name: protocol-agent
protocol_version: "2.1"
---

# Protocol Agent

## Purpose
Agent with protocol version.
EOF

output=$(VERBOSE=true run_script "$SCRIPT" lint "$TEMP_DIR/agents/protocol-version.md" 2>&1) || true
# Should NOT contain "Invalid version" warning for valid X.Y format
if [[ "$output" != *"Invalid version"* ]]; then
    test_pass
else
    test_fail "Should not warn about valid protocol version format"
fi

# ============================================
# Test: Version command works
# ============================================
test_start "Version command works"
output=$(run_script "$SCRIPT" version 2>&1) || true
if assert_contains "$output" "Prompt Versions"; then
    test_pass
fi

# ============================================
# Test: Eval command works
# ============================================
test_start "Eval command works"
output=$(run_script "$SCRIPT" eval "$TEMP_DIR/agents/test-agent.md" 2>&1) || true
if assert_contains "$output" "Quality Evaluation" && \
   assert_contains "$output" "Grade:"; then
    test_pass
fi

# ============================================
# Test: Test command works
# ============================================
test_start "Test command works"
output=$(run_script "$SCRIPT" test "$TEMP_DIR/agents/test-agent.md" 2>&1) || true
if assert_contains "$output" "PASS"; then
    test_pass
fi

# ============================================
# Test: Detect forbidden patterns
# ============================================
test_start "Detect forbidden patterns"
cat << 'EOF' > "$TEMP_DIR/agents/todo-agent.md"
---
name: todo-agent
---

# TODO Agent

TODO: Fix this later
FIXME: This needs work
EOF

output=$(run_script "$SCRIPT" lint "$TEMP_DIR/agents/todo-agent.md" 2>&1) || true
if assert_contains "$output" "TODO:" || assert_contains "$output" "FIXME:"; then
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
# Test: Uses ensure_dir from common.sh
# ============================================
test_start "Uses ensure_dir from common.sh"
if grep -q 'ensure_dir' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use ensure_dir"
fi

# ============================================
# Test: Report command works
# ============================================
test_start "Report command works"
output=$(run_script "$SCRIPT" report 2>&1) || true
if assert_contains "$output" "report" || assert_contains "$output" "Generating"; then
    test_pass
fi

# ============================================
# Test: Has find_prompts function
# ============================================
test_start "Has find_prompts function"
if grep -q 'find_prompts()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have find_prompts function"
fi

# ============================================
# Test: Checks TDD compliance for player files
# ============================================
test_start "Checks TDD compliance for player files"
if grep -q 'check_tdd_compliance' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check TDD compliance"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
