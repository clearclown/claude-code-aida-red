#!/bin/bash
# AIDA PostToolUse Hook: Verify Edit Operations
# Purpose: Verify file edits after execution
# Ensures edits maintain code quality
#
# This hook runs after Edit/Write tools to:
# - Validate syntax for known file types
# - Log changes for TDD evidence
# - Check for common issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Read stdin for tool output
INPUT=$(cat)

# Extract tool info
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' 2>/dev/null || echo "")

# Skip if not an edit/write operation
if [[ "$TOOL_NAME" != "Edit" ]] && [[ "$TOOL_NAME" != "Write" ]]; then
    exit 0
fi

# Skip if file doesn't exist (failed write)
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# ============================================
# Syntax validation by file type
# ============================================
validate_syntax() {
    local file="$1"
    local extension="${file##*.}"

    case "$extension" in
        sh|bash)
            bash -n "$file" 2>/dev/null || return 1
            ;;
        json)
            jq empty < "$file" 2>/dev/null || return 1
            ;;
        py)
            python3 -m py_compile "$file" 2>/dev/null || return 1
            ;;
        go)
            if command -v gofmt &>/dev/null; then
                gofmt -e "$file" >/dev/null 2>&1 || return 1
            fi
            ;;
        ts|tsx|js|jsx)
            # Skip syntax check for JS/TS (requires node)
            return 0
            ;;
        *)
            # Unknown file type, skip validation
            return 0
            ;;
    esac

    return 0
}

# ============================================
# Log edit for TDD evidence
# ============================================
log_edit_evidence() {
    local file="$1"
    local evidence_dir="$PROJECT_ROOT/.aida/tdd-evidence"

    # Only log if AIDA session is active
    if [[ ! -f "$PROJECT_ROOT/.aida/state/session.json" ]]; then
        return 0
    fi

    mkdir -p "$evidence_dir"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local evidence_file="$evidence_dir/edit_${timestamp}.json"

    cat << EOF > "$evidence_file"
{
  "timestamp": "$(date -Iseconds)",
  "tool": "$TOOL_NAME",
  "file": "$file",
  "phase": "implementation"
}
EOF

    log_debug "Edit evidence logged: $evidence_file" >&2
}

# ============================================
# Main verification
# ============================================

# Validate syntax
if ! validate_syntax "$FILE_PATH"; then
    log_warning "Syntax validation failed for: $FILE_PATH" >&2
    # Don't block, just warn - the edit already happened
fi

# Log for TDD evidence
log_edit_evidence "$FILE_PATH"

# PostToolUse hooks don't need to output anything on success
exit 0
