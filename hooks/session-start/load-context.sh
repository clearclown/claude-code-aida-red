#!/bin/bash
# AIDA Session Start Hook
# Purpose: Load context and check for pending work (#151)
#
# This hook runs at session start to:
# - Initialize AIDA directories
# - Load previous session state
# - Check for pending pipeline work
# - Provide context to the agent

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
# Initialize AIDA directories
# ============================================
mkdir -p "$PROJECT_ROOT/.aida/state"
mkdir -p "$PROJECT_ROOT/.aida/artifacts"
mkdir -p "$PROJECT_ROOT/.aida/logs"
mkdir -p "$PROJECT_ROOT/.aida/tdd-evidence"
mkdir -p "$PROJECT_ROOT/.aida/results"

# ============================================
# Check for existing session
# ============================================
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"

if [[ -f "$SESSION_FILE" ]]; then
    # Load session info
    PROJECT=$(jq -r '.project_name // empty' "$SESSION_FILE" 2>/dev/null)
    CURRENT_PHASE=$(jq -r '.current_phase // empty' "$SESSION_FILE" 2>/dev/null)
    MODE=$(jq -r '.mode // empty' "$SESSION_FILE" 2>/dev/null)
    ITERATION=$(jq -r '.iteration // 1' "$SESSION_FILE" 2>/dev/null)
    FORCED_EXIT=$(jq -r '.forced_exit // false' "$SESSION_FILE" 2>/dev/null)

    if [[ -n "$PROJECT" ]]; then
        echo "=== AIDA Session Detected ===" >&2
        echo "Project: $PROJECT" >&2
        echo "Phase: ${CURRENT_PHASE:-not set}" >&2
        echo "Mode: ${MODE:-not set}" >&2
        echo "Iteration: $ITERATION" >&2
        echo "" >&2

        # Check if previous session was force-exited
        if [[ "$FORCED_EXIT" == "true" ]]; then
            EXIT_REASON=$(jq -r '.exit_reason // "unknown"' "$SESSION_FILE")
            echo "Previous session was force-exited: $EXIT_REASON" >&2
            echo "Consider running /aida:resume to continue." >&2
            echo "" >&2
        fi

        # Check for pending work
        QUALITY_GATES_PASSED=$(jq -r '.quality_gates_passed // false' "$SESSION_FILE")
        if [[ "$QUALITY_GATES_PASSED" != "true" ]] && [[ "$CURRENT_PHASE" == "IMPL_PHASE" ]]; then
            echo "Pending work detected: Quality gates not yet passed" >&2
            echo "Run /aida:status for details or continue implementation." >&2
            echo "" >&2
        fi

        # Check for pending queue items
        QUEUE_FILE="$PROJECT_ROOT/.aida/queue/queue.json"
        if [[ -f "$QUEUE_FILE" ]]; then
            PENDING_COUNT=$(jq '[.items[] | select(.status == "pending")] | length' "$QUEUE_FILE" 2>/dev/null || echo "0")
            IN_PROGRESS_COUNT=$(jq '[.items[] | select(.status == "in_progress")] | length' "$QUEUE_FILE" 2>/dev/null || echo "0")

            if [[ $PENDING_COUNT -gt 0 ]] || [[ $IN_PROGRESS_COUNT -gt 0 ]]; then
                echo "Enhancement queue: $PENDING_COUNT pending, $IN_PROGRESS_COUNT in progress" >&2
                echo "Run /aida:queue status for details." >&2
                echo "" >&2
            fi
        fi
    fi
else
    echo "No active AIDA session. Run /aida to start a new project." >&2
fi

# ============================================
# Log session start
# ============================================
LOG_FILE="$PROJECT_ROOT/.aida/logs/session.log"
echo "[$(date -Iseconds)] Session started" >> "$LOG_FILE"

# Always allow session to start
exit 0
