#!/bin/bash
# AIDA Ralph-Loop Gate
# Purpose: Prevent TDD infinite loops in ralph-loop mode
#
# Problem: When TDD is enforced, agents may write tests endlessly
# Solution: Track progress and enforce "minimum viable tests" philosophy
#
# Philosophy:
#   - Tests are necessary but should not block progress
#   - Each feature needs a "baseline" of tests (not 100% coverage)
#   - After baseline is met, allow moving to next task
#   - Record TDD evidence, but don't demand perfection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Configuration
MAX_TEST_ITERATIONS=3     # Max iterations on same test file
MIN_TESTS_PER_FEATURE=2   # Minimum tests before moving on
PROGRESS_TIMEOUT=5        # Minutes without new file = allow exit
TDD_REQUIRED=true         # Require TDD evidence? Set false to disable

# State files
AIDA_DIR="$PROJECT_ROOT/.aida"
STATE_DIR="$AIDA_DIR/state"
PROGRESS_FILE="$STATE_DIR/ralph-progress.json"
RALPH_LOCAL="$PROJECT_ROOT/.claude/ralph-loop.local.md"

mkdir -p "$STATE_DIR"

# ============================================
# Check if ralph-loop is active
# ============================================
if [[ ! -f "$RALPH_LOCAL" ]]; then
    # No ralph-loop active
    exit 0
fi

# Check if active
if ! grep -q "^active: true" "$RALPH_LOCAL" 2>/dev/null; then
    exit 0
fi

# ============================================
# Get current iteration
# ============================================
CURRENT_ITERATION=$(grep "^iteration:" "$RALPH_LOCAL" | awk '{print $2}' | tr -d ' ')
MAX_ITERATIONS=$(grep "^max_iterations:" "$RALPH_LOCAL" | awk '{print $2}' | tr -d ' ')

# ============================================
# Initialize progress tracking
# ============================================
init_progress() {
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        cat << EOF > "$PROGRESS_FILE"
{
  "started_at": "$(date -Iseconds)",
  "last_file_change": "$(date -Iseconds)",
  "files_created": [],
  "files_modified": [],
  "tests_written": 0,
  "features_completed": 0,
  "test_iterations": {},
  "current_task": null,
  "stuck_count": 0
}
EOF
    fi
}

# ============================================
# Track file changes
# ============================================
update_progress() {
    local timestamp=$(date -Iseconds)

    # Get recently modified files (last 2 minutes)
    local recent_files=$(find "$PROJECT_ROOT" -type f \
        -not -path "*/.git/*" \
        -not -path "*/.aida/*" \
        -not -path "*/node_modules/*" \
        -newer "$PROGRESS_FILE" 2>/dev/null | head -20)

    if [[ -n "$recent_files" ]]; then
        # Count test files
        local test_count=$(echo "$recent_files" | grep -E "_test\.|\.test\.|\.spec\." | wc -l || echo 0)

        # Update progress
        local updated=$(jq --arg ts "$timestamp" --argjson tests "$test_count" '
            .last_file_change = $ts |
            .tests_written += $tests
        ' "$PROGRESS_FILE")
        echo "$updated" > "$PROGRESS_FILE"
    fi
}

# ============================================
# Check for stuck condition
# ============================================
check_stuck() {
    local last_change=$(jq -r '.last_file_change' "$PROGRESS_FILE")
    local now=$(date -Iseconds)

    # Calculate minutes since last change
    local last_ts=$(date -d "$last_change" +%s 2>/dev/null || echo 0)
    local now_ts=$(date +%s)
    local diff_minutes=$(( (now_ts - last_ts) / 60 ))

    if [[ $diff_minutes -ge $PROGRESS_TIMEOUT ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# ============================================
# Check minimum test coverage
# ============================================
check_min_tests() {
    local tests_written=$(jq -r '.tests_written' "$PROGRESS_FILE")

    if [[ $tests_written -ge $MIN_TESTS_PER_FEATURE ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# ============================================
# Check TDD evidence
# ============================================
check_tdd_evidence() {
    local evidence_dir="$AIDA_DIR/tdd-evidence"

    if [[ ! -d "$evidence_dir" ]]; then
        echo "false"
        return
    fi

    local evidence_count=$(find "$evidence_dir" -name "*.json" -not -name ".*" | wc -l)

    if [[ $evidence_count -ge 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# ============================================
# Main Logic
# ============================================
init_progress
update_progress

# Get current state
IS_STUCK=$(check_stuck)
MIN_TESTS_MET=$(check_min_tests)
HAS_TDD_EVIDENCE=$(check_tdd_evidence)
TESTS_WRITTEN=$(jq -r '.tests_written' "$PROGRESS_FILE")

echo "=== Ralph-Loop Gate ===" >&2
echo "Iteration: $CURRENT_ITERATION" >&2
echo "Tests written: $TESTS_WRITTEN (min: $MIN_TESTS_PER_FEATURE)" >&2
echo "TDD evidence: $HAS_TDD_EVIDENCE" >&2
echo "Stuck status: $IS_STUCK" >&2
echo "" >&2

# Decision logic
DECISION="approve"
REASON=""

# Case 1: Stuck for too long - allow exit
if [[ "$IS_STUCK" == "true" ]]; then
    DECISION="approve"
    REASON="No progress for ${PROGRESS_TIMEOUT}+ minutes. Allowing exit to prevent infinite loop."

# Case 2: Minimum tests met and has TDD evidence - allow exit
elif [[ "$MIN_TESTS_MET" == "true" ]] && [[ "$HAS_TDD_EVIDENCE" == "true" ]]; then
    DECISION="approve"
    REASON="Minimum tests ($MIN_TESTS_PER_FEATURE) met with TDD evidence. Ready to move to next task."

# Case 3: Minimum tests met but no TDD evidence
elif [[ "$MIN_TESTS_MET" == "true" ]] && [[ "$HAS_TDD_EVIDENCE" == "false" ]]; then
    if [[ "$TDD_REQUIRED" == "true" ]]; then
        DECISION="block"
        REASON="Tests written but TDD evidence missing. Run: ./scripts/tdd-logger.sh start <feature>"
    else
        DECISION="approve"
        REASON="Minimum tests met (TDD evidence not required)."
    fi

# Case 4: High iteration count - allow exit to prevent endless loop
elif [[ -n "$CURRENT_ITERATION" ]] && [[ $CURRENT_ITERATION -ge 10 ]]; then
    DECISION="approve"
    REASON="High iteration count ($CURRENT_ITERATION). Allowing progress."

# Case 5: Still need tests
else
    # Only block if we're explicitly in test phase
    session_file="$STATE_DIR/session.json"
    current_phase=""
    if [[ -f "$session_file" ]]; then
        current_phase=$(jq -r '.current_phase // ""' "$session_file")
    fi

    if [[ "$current_phase" == "IMPL_PHASE" ]]; then
        DECISION="block"
        REASON="Implementation phase: Need at least $MIN_TESTS_PER_FEATURE tests. Current: $TESTS_WRITTEN"
    else
        DECISION="approve"
        REASON="Not in implementation phase."
    fi
fi

# Output decision with official Claude Code format
# Note: Always exit 0 for JSON to be processed. decision:block handles blocking.
if [[ "$DECISION" == "block" ]]; then
    output_block "$REASON" "Ralph-Loop Gate: $REASON"
else
    output_allow "$REASON"
fi
exit 0
