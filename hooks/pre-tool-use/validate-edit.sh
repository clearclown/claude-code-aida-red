#!/bin/bash
# AIDA PreToolUse Hook: Validate Edit Operations
# Purpose: Validate file edits before execution
# Ensures edits follow project conventions
#
# This hook runs before Edit/Write tools to:
# - Check for forbidden patterns (secrets, credentials)
# - Validate file types
# - Create automatic backups

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source common utilities
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Read stdin for tool input
INPUT=$(cat)

# Extract tool info
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || echo "")

# Skip if not an edit/write operation
if [[ "$TOOL_NAME" != "Edit" ]] && [[ "$TOOL_NAME" != "Write" ]]; then
    # Allow all other tools
    echo '{"decision": "allow", "permissionDecisionReason": "Non-edit operation"}'
    exit 0
fi

# ============================================
# Check for forbidden patterns in content
# ============================================
check_forbidden_patterns() {
    local content="$1"

    # Common secret patterns
    if echo "$content" | grep -qiE 'password\s*=\s*["\x27][^"\x27]+["\x27]' 2>/dev/null; then
        return 1
    fi
    if echo "$content" | grep -qiE 'api_key\s*=\s*["\x27][^"\x27]+["\x27]' 2>/dev/null; then
        return 1
    fi
    if echo "$content" | grep -qiE 'AWS_ACCESS_KEY_ID\s*=' 2>/dev/null; then
        return 1
    fi
    if echo "$content" | grep -qiE 'PRIVATE_KEY' 2>/dev/null; then
        return 1
    fi

    return 0
}

if ! check_forbidden_patterns "$CONTENT"; then
    log_warning "Potential secret detected in edit" >&2
    echo '{"decision": "deny", "permissionDecisionReason": "Content may contain secrets. Use environment variables instead."}'
    exit 0
fi

# ============================================
# Validate file extensions
# ============================================
EXTENSION="${FILE_PATH##*.}"
case "$EXTENSION" in
    exe|dll|so|dylib|bin)
        echo "{\"decision\": \"deny\", \"permissionDecisionReason\": \"Cannot edit binary files: $EXTENSION\"}"
        exit 0
        ;;
esac

# ============================================
# Create backup for existing files
# ============================================
if [[ -n "$FILE_PATH" ]] && [[ -f "$FILE_PATH" ]]; then
    BACKUP_DIR="$PROJECT_ROOT/.aida/backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/$(basename "$FILE_PATH").$(date +%Y%m%d_%H%M%S)"
    cp "$FILE_PATH" "$BACKUP_FILE" 2>/dev/null || true
    log_debug "Backup created: $BACKUP_FILE" >&2
fi

# ============================================
# Allow the edit
# ============================================
echo '{"decision": "allow", "permissionDecisionReason": "Edit validated and backup created"}'
exit 0
