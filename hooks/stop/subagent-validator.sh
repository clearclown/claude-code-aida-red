#!/bin/bash
# AIDA Subagent Validator Hook
# Purpose: Validate Player (subagent) completion before allowing exit
# Exit code 0 = allow exit, Exit code 2 = block exit
#
# This hook ensures that subagents (Backend Player, Frontend Player)
# have met minimum test requirements before they can exit.
# This prevents premature completion claims.

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
# Get project from session
# ============================================
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"
if [[ ! -f "$SESSION_FILE" ]]; then
    exit 0  # No session, allow exit
fi

PROJECT=$(jq -r '.project_name // empty' "$SESSION_FILE" 2>/dev/null)
if [[ -z "$PROJECT" ]]; then
    exit 0  # No project, allow exit
fi

# ============================================
# Define paths
# ============================================
BACKEND_DIR="$PROJECT_ROOT/$PROJECT/backend"
FRONTEND_DIR="$PROJECT_ROOT/$PROJECT/frontend"

# ============================================
# Minimum requirements
# ============================================
MIN_BACKEND_TESTS=80
MIN_FRONTEND_TESTS=100
MIN_BACKEND_COVERAGE=75
MIN_FRONTEND_COVERAGE=70

# ============================================
# Backend Player validation
# ============================================
if [[ -d "$BACKEND_DIR" ]]; then
    echo "=== Validating Backend Player ===" >&2

    # Count test functions
    BACKEND_TESTS=$(grep -r "func Test" "$BACKEND_DIR" --include="*_test.go" 2>/dev/null | wc -l)
    echo "Backend tests: $BACKEND_TESTS / $MIN_BACKEND_TESTS required" >&2

    if [[ $BACKEND_TESTS -lt $MIN_BACKEND_TESTS ]]; then
        echo "" >&2
        echo "INSUFFICIENT BACKEND TESTS" >&2
        echo "Add $((MIN_BACKEND_TESTS - BACKEND_TESTS)) more test functions." >&2
        echo "" >&2

        # Official Claude Code format
        output_block "Backend needs $MIN_BACKEND_TESTS+ tests (currently: $BACKEND_TESTS)" \
            "Add $((MIN_BACKEND_TESTS - BACKEND_TESTS)) more Go test functions to backend/"
        exit 0  # JSON requires exit 0
    fi

    # Check test files exist for each handler
    HANDLER_COUNT=$(find "$BACKEND_DIR/internal/handler" -name "*.go" ! -name "*_test.go" 2>/dev/null | wc -l)
    HANDLER_TEST_COUNT=$(find "$BACKEND_DIR/internal/handler" -name "*_test.go" 2>/dev/null | wc -l)

    if [[ $HANDLER_COUNT -gt 0 && $HANDLER_TEST_COUNT -lt $HANDLER_COUNT ]]; then
        echo "WARNING: Not all handlers have test files ($HANDLER_TEST_COUNT/$HANDLER_COUNT)" >&2
    fi

    echo "Backend validation: PASSED" >&2
fi

# ============================================
# Frontend Player validation
# ============================================
if [[ -d "$FRONTEND_DIR/src" ]]; then
    echo "" >&2
    echo "=== Validating Frontend Player ===" >&2

    # Count test cases (it/test blocks)
    FRONTEND_TESTS=$(grep -rE "^\s*(it|test)\s*\(" "$FRONTEND_DIR/src" --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | wc -l)
    echo "Frontend tests: $FRONTEND_TESTS / $MIN_FRONTEND_TESTS required" >&2

    if [[ $FRONTEND_TESTS -lt $MIN_FRONTEND_TESTS ]]; then
        echo "" >&2
        echo "INSUFFICIENT FRONTEND TESTS" >&2
        echo "Add $((MIN_FRONTEND_TESTS - FRONTEND_TESTS)) more test cases." >&2
        echo "" >&2

        # Official Claude Code format
        output_block "Frontend needs $MIN_FRONTEND_TESTS+ tests (currently: $FRONTEND_TESTS)" \
            "Add $((MIN_FRONTEND_TESTS - FRONTEND_TESTS)) more Jest/Vitest test cases to frontend/src/"
        exit 0  # JSON requires exit 0
    fi

    # Check test files exist for each page
    PAGE_COUNT=$(find "$FRONTEND_DIR/src/pages" -name "*.tsx" ! -name "*.test.tsx" 2>/dev/null | wc -l)
    PAGE_TEST_COUNT=$(find "$FRONTEND_DIR/src/pages" -name "*.test.tsx" 2>/dev/null | wc -l)

    if [[ $PAGE_COUNT -gt 0 && $PAGE_TEST_COUNT -lt $PAGE_COUNT ]]; then
        echo "WARNING: Not all pages have test files ($PAGE_TEST_COUNT/$PAGE_COUNT)" >&2
    fi

    echo "Frontend validation: PASSED" >&2
fi

# ============================================
# E2E validation
# ============================================
E2E_DIR="$FRONTEND_DIR/e2e"
if [[ -d "$E2E_DIR" ]]; then
    echo "" >&2
    echo "=== Validating E2E Tests ===" >&2

    E2E_COUNT=$(find "$E2E_DIR" \( -name "*.spec.ts" -o -name "*.test.ts" \) 2>/dev/null | wc -l)
    E2E_TEST_COUNT=$(grep -rE "^\s*(it|test)\s*\(" "$E2E_DIR" --include="*.spec.ts" --include="*.test.ts" 2>/dev/null | wc -l)

    echo "E2E test files: $E2E_COUNT" >&2
    echo "E2E test cases: $E2E_TEST_COUNT / 20 required" >&2

    if [[ $E2E_TEST_COUNT -lt 20 ]]; then
        echo "WARNING: E2E tests below minimum ($E2E_TEST_COUNT/20)" >&2
    fi
fi

echo "" >&2
echo "=== Subagent Validation Complete ===" >&2

# All validations passed - Official Claude Code format
output_allow "All subagent validations passed"
exit 0
