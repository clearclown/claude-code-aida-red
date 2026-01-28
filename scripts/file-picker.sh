#!/bin/bash
# AIDA File Picker (fzf integration)
# Purpose: Interactive file selection for enhancement tasks
# Usage: ./file-picker.sh [options]
#
# Uses fzf for fuzzy file selection, reducing manual file specification.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# ============================================
# Check fzf installation (using require_command from common.sh)
# ============================================
check_fzf() {
    if ! require_command fzf "sudo apt install fzf (Debian/Ubuntu), brew install fzf (macOS), or sudo pacman -S fzf (Arch)" 2>/dev/null; then
        log_warning "fzf not installed - falling back to basic file listing"
        return 1
    fi
    return 0
}

# ============================================
# Parse arguments
# ============================================
MODE="${1:-files}"
SEARCH_PATH="${2:-$PROJECT_ROOT}"
PATTERN="${3:-}"

print_usage() {
    cat << 'EOF'
AIDA File Picker

Usage:
  ./file-picker.sh [mode] [path] [pattern]

Modes:
  files     Select files (default)
  dirs      Select directories
  code      Select code files only
  tests     Select test files only
  modified  Select git-modified files
  staged    Select git-staged files

Examples:
  ./file-picker.sh                    # Pick any file
  ./file-picker.sh code ./src         # Pick code file from src/
  ./file-picker.sh tests              # Pick test file
  ./file-picker.sh modified           # Pick from git changes

Options with fzf:
  - Type to filter
  - Tab to select multiple
  - Enter to confirm
  - Ctrl-C to cancel

EOF
}

# ============================================
# File listing functions
# ============================================
list_files() {
    local path="$1"
    find "$path" -type f \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/.aida/*" \
        ! -path "*/vendor/*" \
        ! -path "*/__pycache__/*" \
        2>/dev/null | sort
}

list_dirs() {
    local path="$1"
    find "$path" -type d \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/.aida/*" \
        ! -path "*/vendor/*" \
        2>/dev/null | sort
}

list_code() {
    local path="$1"
    find "$path" -type f \( \
        -name "*.go" -o \
        -name "*.ts" -o \
        -name "*.tsx" -o \
        -name "*.js" -o \
        -name "*.jsx" -o \
        -name "*.py" -o \
        -name "*.rs" -o \
        -name "*.java" -o \
        -name "*.rb" -o \
        -name "*.sh" \
    \) \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/.aida/*" \
        ! -name "*_test.go" \
        ! -name "*.test.ts" \
        ! -name "*.test.tsx" \
        ! -name "*.spec.ts" \
        ! -name "*_test.py" \
        2>/dev/null | sort
}

list_tests() {
    local path="$1"
    find "$path" -type f \( \
        -name "*_test.go" -o \
        -name "*.test.ts" -o \
        -name "*.test.tsx" -o \
        -name "*.spec.ts" -o \
        -name "*_test.py" -o \
        -name "*_spec.rb" \
    \) \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        2>/dev/null | sort
}

list_modified() {
    cd "$PROJECT_ROOT"
    git diff --name-only 2>/dev/null || true
    git diff --cached --name-only 2>/dev/null || true
}

list_staged() {
    cd "$PROJECT_ROOT"
    git diff --cached --name-only 2>/dev/null
}

# ============================================
# Select with fzf
# ============================================
select_with_fzf() {
    local items="$1"
    local preview_cmd="head -50 {}"

    if check_fzf; then
        echo "$items" | fzf \
            --multi \
            --preview "$preview_cmd" \
            --preview-window "right:50%:wrap" \
            --header "Select files (Tab to multi-select, Enter to confirm)" \
            --bind "ctrl-a:toggle-all"
    else
        # Fallback without fzf
        echo "$items" | head -20
        echo ""
        echo "Enter file path(s) to select (or press Enter for first result):"
        read -r selection
        if [[ -z "$selection" ]]; then
            echo "$items" | head -1
        else
            echo "$selection"
        fi
    fi
}

# ============================================
# Main
# ============================================
case "$MODE" in
    files)
        items=$(list_files "$SEARCH_PATH")
        ;;
    dirs)
        items=$(list_dirs "$SEARCH_PATH")
        ;;
    code)
        items=$(list_code "$SEARCH_PATH")
        ;;
    tests)
        items=$(list_tests "$SEARCH_PATH")
        ;;
    modified)
        items=$(list_modified)
        ;;
    staged)
        items=$(list_staged)
        ;;
    help|--help|-h)
        print_usage
        exit 0
        ;;
    *)
        echo "Unknown mode: $MODE" >&2
        print_usage
        exit 1
        ;;
esac

if [[ -z "$items" ]]; then
    echo "No files found for mode: $MODE" >&2
    exit 1
fi

# Filter by pattern if provided
if [[ -n "$PATTERN" ]]; then
    items=$(echo "$items" | grep -E "$PATTERN" || true)
fi

# Select
selected=$(select_with_fzf "$items")

if [[ -n "$selected" ]]; then
    echo "$selected"
fi
