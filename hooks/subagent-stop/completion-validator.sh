#!/bin/bash
# AIDA Subagent Completion Validator
# Purpose: Ensure subagents properly complete and return control (#215)
# Exit code 0 = allow exit, Exit code 2 = block exit
#
# This hook addresses Issue #215:
# - Validates subagent has actually completed its assigned task
# - Ensures proper handoff back to main agent
# - Prevents premature completion claims

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# ============================================
# Read stdin for tool input (subagent context)
# ============================================
INPUT=$(cat)

# Extract subagent info if available
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // empty' 2>/dev/null || echo "")
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty' 2>/dev/null || echo "")

# ============================================
# Check if AIDA session is active
# ============================================
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"
if [[ ! -f "$SESSION_FILE" ]]; then
    # No session, allow subagent to complete
    output_allow "No active AIDA session"
    exit 0
fi

# ============================================
# Get project and phase info
# ============================================
PROJECT=$(jq -r '.project_name // empty' "$SESSION_FILE" 2>/dev/null)
CURRENT_PHASE=$(jq -r '.current_phase // empty' "$SESSION_FILE" 2>/dev/null)

if [[ -z "$PROJECT" ]]; then
    output_allow "No project in session"
    exit 0
fi

# ============================================
# Validate based on subagent type
# ============================================
echo "=== Subagent Completion Validator ===" >&2
echo "Project: $PROJECT" >&2
echo "Subagent: ${SUBAGENT_TYPE:-unknown}" >&2
echo "Task ID: ${TASK_ID:-none}" >&2
echo "" >&2

PROJECT_DIR="$PROJECT_ROOT/$PROJECT"

# Backend Player validation
if [[ "$SUBAGENT_TYPE" == *"backend"* ]] || [[ "$SUBAGENT_TYPE" == *"Backend"* ]]; then
    if [[ -d "$PROJECT_DIR/backend" ]]; then
        # Check for minimum deliverables
        GO_FILES=$(find "$PROJECT_DIR/backend" -name "*.go" ! -name "*_test.go" 2>/dev/null | wc -l)
        TEST_FILES=$(find "$PROJECT_DIR/backend" -name "*_test.go" 2>/dev/null | wc -l)

        echo "Backend files: $GO_FILES" >&2
        echo "Test files: $TEST_FILES" >&2

        if [[ $GO_FILES -lt 5 ]]; then
            output_block "Backend Player incomplete - insufficient implementation" \
                "Backend needs at least 5 Go files. Currently: $GO_FILES. Continue implementing handlers, models, and services."
            exit 0  # JSON requires exit 0
        fi

        if [[ $TEST_FILES -lt 3 ]]; then
            output_block "Backend Player incomplete - missing tests" \
                "Backend needs at least 3 test files. Currently: $TEST_FILES. Add tests for handlers and services."
            exit 0  # JSON requires exit 0
        fi
    fi
fi

# Frontend Player validation
if [[ "$SUBAGENT_TYPE" == *"frontend"* ]] || [[ "$SUBAGENT_TYPE" == *"Frontend"* ]]; then
    if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
        TSX_FILES=$(find "$PROJECT_DIR/frontend/src" -name "*.tsx" ! -name "*.test.tsx" 2>/dev/null | wc -l)
        TEST_FILES=$(find "$PROJECT_DIR/frontend/src" -name "*.test.tsx" 2>/dev/null | wc -l)

        echo "Frontend files: $TSX_FILES" >&2
        echo "Test files: $TEST_FILES" >&2

        if [[ $TSX_FILES -lt 5 ]]; then
            output_block "Frontend Player incomplete - insufficient components" \
                "Frontend needs at least 5 TSX files. Currently: $TSX_FILES. Continue implementing components and pages."
            exit 0  # JSON requires exit 0
        fi

        if [[ $TEST_FILES -lt 3 ]]; then
            output_block "Frontend Player incomplete - missing tests" \
                "Frontend needs at least 3 test files. Currently: $TEST_FILES. Add tests for components."
            exit 0  # JSON requires exit 0
        fi
    fi
fi

# ============================================
# Record completion in session
# ============================================
if [[ -n "$SUBAGENT_TYPE" ]]; then
    jq --arg type "$SUBAGENT_TYPE" '
        .completed_subagents = ((.completed_subagents // []) + [$type]) |
        .last_subagent_completion = (now | todate)
    ' "$SESSION_FILE" > "${SESSION_FILE}.tmp" && \
        mv "${SESSION_FILE}.tmp" "$SESSION_FILE" 2>/dev/null || true
fi

echo "Subagent validation: PASSED" >&2
echo "" >&2

# ============================================
# Allow completion with proper handoff message
# ============================================
output_allow "Subagent task completed successfully" \
    "Subagent has completed its assigned task. Control will return to the main agent."
exit 0
