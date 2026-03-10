#!/bin/bash
# AIDA-RED Auto-Trigger Hook
# Runs when AIDA completes, checks if target is ready for security scan
#
# This is a Stop hook that:
# 1. Checks if AIDA just completed (quality gates passed)
# 2. Checks if AIDA-RED scanner is initialized
# 3. Suggests running /aida:red-assault
#
# Exit codes:
#   0 = allow stop (no action needed)
#   1 = error
#   Note: This hook never blocks AIDA's stop, only suggests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

SESSION_FILE=".aida/state/session.json"
RED_CONFIG=".aida-red/config/scanner.json"

# Only proceed if AIDA session exists
if [[ ! -f "$SESSION_FILE" ]]; then
    exit 0
fi

PHASE=$(jq -r '.current_phase // "UNKNOWN"' "$SESSION_FILE" 2>/dev/null || echo "UNKNOWN")
GATES=$(jq -r '.quality_gates_passed // false' "$SESSION_FILE" 2>/dev/null || echo "false")

# Only trigger when AIDA is completing successfully
if [[ "$PHASE" != "COMPLETED" || "$GATES" != "true" ]]; then
    exit 0
fi

# Check if AIDA-RED is initialized
if [[ ! -f "$RED_CONFIG" ]]; then
    echo ""
    echo "========================================"
    echo "AIDA-RED: Security scan available"
    echo "========================================"
    echo "AIDA completed successfully. Run a security scan:"
    echo ""
    echo "  /aida:red-init       (first time setup)"
    echo "  /aida:red-assault    (run scan)"
    echo "========================================"
    echo ""
    exit 0
fi

echo ""
echo "========================================"
echo "AIDA-RED: Ready to scan"
echo "========================================"
echo "AIDA build complete. Consider running:"
echo ""
echo "  /aida:red-assault --target http://localhost:8080"
echo "========================================"
echo ""

exit 0
