#!/bin/bash
# AIDA Enhancement Quality Gate Hook
# Purpose: Prevent exit until enhancement quality gates pass
# Exit code 0 = allow exit, Exit code 2 = block exit
#
# This hook enforces quality gates for project enhancement:
# - Verifies baseline tests still pass (no regression)
# - Checks that test count has not decreased
# - Runs build and lint checks
# - Only allows exit when ALL gates pass

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available, otherwise use detected root
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# ============================================
# Check if AIDA session is active
# ============================================
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"
if [[ ! -f "$SESSION_FILE" ]]; then
    # No active session, allow exit
    exit 0
fi

# ============================================
# Check if in enhance mode
# ============================================
MODE=$(jq -r '.mode // empty' "$SESSION_FILE" 2>/dev/null)
if [[ "$MODE" != "aida:enhance" ]]; then
    # Not in enhance mode, allow exit (other hooks handle other modes)
    exit 0
fi

# ============================================
# Get project info from session
# ============================================
PROJECT=$(jq -r '.project_name // empty' "$SESSION_FILE" 2>/dev/null)
PROJECT_PATH=$(jq -r '.project_path // empty' "$SESSION_FILE" 2>/dev/null)

if [[ -z "$PROJECT" ]] || [[ -z "$PROJECT_PATH" ]]; then
    echo "Error: Project name or path not found in session" >&2
    exit 0  # Allow exit but with warning
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Error: Project directory does not exist: $PROJECT_PATH" >&2
    exit 0  # Allow exit but with warning
fi

# ============================================
# Check for required files
# ============================================
ANALYSIS_FILE="$PROJECT_ROOT/.aida/artifacts/${PROJECT}-analysis.json"
BASELINE_FILE="$PROJECT_ROOT/.aida/state/enhance-baseline.json"

if [[ ! -f "$ANALYSIS_FILE" ]]; then
    echo "Warning: Analysis file not found: $ANALYSIS_FILE" >&2
    echo "Running analysis is recommended before completing enhancement." >&2
    # Don't block, but warn
    exit 0
fi

# ============================================
# Run enhancement quality gates
# ============================================
echo "=== AIDA Enhancement Quality Gate ===" >&2
echo "Project: $PROJECT" >&2
echo "Path: $PROJECT_PATH" >&2
echo "Mode: Enhancement" >&2
echo "" >&2

GATE_SCRIPT="$PROJECT_ROOT/scripts/enhance-quality-gates.sh"

if [[ ! -x "$GATE_SCRIPT" ]]; then
    echo "Warning: Enhancement quality gates script not found or not executable" >&2
    echo "Location: $GATE_SCRIPT" >&2
    exit 0
fi

# Run enhancement quality gates
GATE_RESULT=0
if [[ -f "$BASELINE_FILE" ]]; then
    echo "Running quality gates with baseline comparison..." >&2
    "$GATE_SCRIPT" "$ANALYSIS_FILE" "$PROJECT_PATH" "$BASELINE_FILE" 2>&1 || GATE_RESULT=$?
else
    echo "Running quality gates (no baseline - initial enhancement)..." >&2
    "$GATE_SCRIPT" "$ANALYSIS_FILE" "$PROJECT_PATH" 2>&1 || GATE_RESULT=$?
fi

echo "" >&2

if [[ $GATE_RESULT -ne 0 ]]; then
    # Quality gates failed - block exit and force iteration
    echo "=== ENHANCEMENT QUALITY GATES NOT PASSED ===" >&2
    echo "" >&2
    echo "You must fix the following issues before completing:" >&2
    echo "" >&2
    echo "  1. Baseline Preservation:" >&2
    echo "     - All existing tests must continue to pass" >&2
    echo "     - Test count must not decrease" >&2
    echo "" >&2
    echo "  2. Build Requirements:" >&2
    echo "     - All components must build successfully" >&2
    echo "" >&2
    echo "  3. Enhancement Requirements:" >&2
    echo "     - New features should have tests" >&2
    echo "" >&2
    echo "Review the gate output above and fix any failures." >&2
    echo "Continue implementation and try again." >&2
    echo "" >&2

    # Output JSON response to block exit (Official Claude Code format)
    # Note: exit 0 with decision:block is correct - exit 2 would ignore JSON
    output_block "Enhancement quality gates not passed" \
        "Fix regressions: 1) All baseline tests must pass 2) Test count must not decrease 3) Build must succeed 4) New features need tests"
    exit 0  # JSON is only processed with exit 0
fi

# ============================================
# All gates passed - allow exit
# ============================================
echo "=== ENHANCEMENT QUALITY GATES PASSED ===" >&2
echo "" >&2
echo "Enhancement complete!" >&2
echo "" >&2
echo "Summary:" >&2
echo "  - Baseline tests: PRESERVED" >&2
echo "  - Build: PASS" >&2
echo "  - No regressions detected" >&2
echo "" >&2

# Update session to mark completion
jq '.quality_gates_passed = true | .enhancement_complete = true | .completed_at = (now | todate)' \
    "$SESSION_FILE" > "${SESSION_FILE}.tmp" && \
    mv "${SESSION_FILE}.tmp" "$SESSION_FILE" 2>/dev/null || true

# Write completion result
RESULT_FILE="$PROJECT_ROOT/.aida/results/enhance-complete.json"
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" << EOF
{
  "task_id": "enhance-$PROJECT",
  "status": "completed",
  "completed_at": "$(date -Iseconds)",
  "project": "$PROJECT",
  "project_path": "$PROJECT_PATH",
  "quality_gates": "passed",
  "baseline_preserved": true
}
EOF

# Output JSON response to allow exit (Official Claude Code format)
output_allow "Enhancement complete - all quality gates passed, baseline preserved"
exit 0
