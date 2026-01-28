#!/bin/bash
# AIDA Interactive Enhancement Mode
# Purpose: Interactive file selection and semantic search for enhancements
# Usage: ./interactive-enhance.sh <project-name> [--interactive]
#
# This script provides an interactive mode for AIDA enhancements,
# allowing users to select files with fzf and search with grepai.
#
# Issue #219: Interactive file selection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Additional color
CYAN='\033[0;36m'

# ============================================
# Usage
# ============================================
usage() {
    cat << EOF
Usage: $(basename "$0") <project-name> [options]

Interactive enhancement mode with file selection and semantic search.

Options:
    --interactive       Enable interactive mode (default if terminal)
    --batch             Disable interactive mode
    --search=QUERY      Semantic search query
    --files=PATTERN     File pattern to select
    --help              Show this help message

Menu Options:
    1. Select files to enhance (fzf)
    2. Semantic search (grepai)
    3. View current selection
    4. Run enhancement
    5. Exit

Examples:
    $(basename "$0") my-project --interactive
    $(basename "$0") my-project --search="authentication"
    $(basename "$0") my-project --files="*.go"

Requirements:
    - fzf (for file selection)
    - grepai (for semantic search)
EOF
}

# ============================================
# Parse arguments
# ============================================
PROJECT=""
INTERACTIVE=false
BATCH=false
SEARCH_QUERY=""
FILE_PATTERN=""

# Auto-detect interactive mode
if [[ -t 0 && -t 1 ]]; then
    INTERACTIVE=true
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --batch)
            BATCH=true
            INTERACTIVE=false
            shift
            ;;
        --search=*)
            SEARCH_QUERY="${1#*=}"
            shift
            ;;
        --files=*)
            FILE_PATTERN="${1#*=}"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            exit 1
            ;;
        *)
            PROJECT=$1
            shift
            ;;
    esac
done

if [[ -z "$PROJECT" ]]; then
    usage
    exit 1
fi

# ============================================
# Check dependencies
# ============================================
check_dependencies() {
    local missing=()

    if ! command -v fzf &>/dev/null; then
        missing+=("fzf")
    fi

    if ! command -v grepai &>/dev/null; then
        # Check for semantic-search.sh as fallback
        if [[ ! -x "$SCRIPT_DIR/semantic-search.sh" ]]; then
            missing+=("grepai")
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warning: Missing optional tools: ${missing[*]}${NC}" >&2
        echo "Some features may be limited." >&2
        echo "" >&2
        echo "Install:" >&2
        for tool in "${missing[@]}"; do
            case $tool in
                fzf)
                    echo "  fzf: https://github.com/junegunn/fzf#installation" >&2
                    ;;
                grepai)
                    echo "  grepai: go install github.com/yoanbernabeu/grepai@latest" >&2
                    ;;
            esac
        done
        echo "" >&2
    fi
}

# ============================================
# File selection with fzf
# ============================================
select_files_fzf() {
    local project_dir="$PROJECT_ROOT/$PROJECT"

    if ! command -v fzf &>/dev/null; then
        echo -e "${RED}fzf not installed. Using basic file picker.${NC}" >&2
        "$SCRIPT_DIR/file-picker.sh" "$project_dir"
        return
    fi

    echo -e "${BLUE}Select files to enhance (Tab to multi-select, Enter to confirm):${NC}"

    local selected
    selected=$(find "$project_dir" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/vendor/*" \
        ! -path "*/__pycache__/*" \
        ! -name "*.lock" \
        ! -name "*.sum" \
        2>/dev/null | \
        fzf --multi \
            --preview 'head -50 {}' \
            --preview-window 'right:50%' \
            --header 'Select files to enhance' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-d:deselect-all')

    if [[ -n "$selected" ]]; then
        echo "$selected"
        SELECTED_FILES="$selected"
    fi
}

# ============================================
# Semantic search with grepai
# ============================================
semantic_search() {
    local query="$1"
    local project_dir="$PROJECT_ROOT/$PROJECT"

    echo -e "${BLUE}Searching: $query${NC}"

    if command -v grepai &>/dev/null; then
        grepai "$query" "$project_dir" 2>/dev/null || true
    elif [[ -x "$SCRIPT_DIR/semantic-search.sh" ]]; then
        "$SCRIPT_DIR/semantic-search.sh" "$query" "$project_dir"
    else
        echo -e "${YELLOW}Falling back to grep...${NC}" >&2
        grep -r "$query" "$project_dir" --include="*.go" --include="*.ts" --include="*.py" 2>/dev/null | head -20
    fi
}

# ============================================
# Interactive menu
# ============================================
SELECTED_FILES=""

show_menu() {
    echo ""
    echo -e "${CYAN}=== AIDA Interactive Enhancement ===${NC}"
    echo -e "${CYAN}Project: $PROJECT${NC}"
    echo ""
    echo "  1. Select files to enhance (fzf)"
    echo "  2. Semantic search (grepai)"
    echo "  3. View current selection"
    echo "  4. Run enhancement"
    echo "  5. Exit"
    echo ""
    echo -n "Choose option [1-5]: "
}

run_interactive() {
    check_dependencies

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                select_files_fzf
                ;;
            2)
                echo -n "Enter search query: "
                read -r query
                if [[ -n "$query" ]]; then
                    semantic_search "$query"
                fi
                ;;
            3)
                if [[ -n "$SELECTED_FILES" ]]; then
                    echo -e "${GREEN}Selected files:${NC}"
                    echo "$SELECTED_FILES" | while read -r file; do
                        echo "  - $file"
                    done
                else
                    echo -e "${YELLOW}No files selected.${NC}"
                fi
                ;;
            4)
                if [[ -n "$SELECTED_FILES" ]]; then
                    echo -e "${GREEN}Running enhancement on selected files...${NC}"
                    # Save selection for enhancement
                    echo "$SELECTED_FILES" > "$PROJECT_ROOT/.aida/state/selected-files.txt"
                    echo "Selection saved. Run /aida:enhance to continue."
                else
                    echo -e "${YELLOW}No files selected. Please select files first.${NC}"
                fi
                ;;
            5|q|Q)
                echo -e "${GREEN}Exiting interactive mode.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 1-5.${NC}"
                ;;
        esac
    done
}

# ============================================
# Batch mode
# ============================================
run_batch() {
    check_dependencies

    if [[ -n "$SEARCH_QUERY" ]]; then
        semantic_search "$SEARCH_QUERY"
    fi

    if [[ -n "$FILE_PATTERN" ]]; then
        find "$PROJECT_ROOT/$PROJECT" -name "$FILE_PATTERN" -type f 2>/dev/null
    fi
}

# ============================================
# Main
# ============================================
echo -e "${BLUE}AIDA Interactive Enhancement${NC}"
echo "======================================"
echo ""

if [[ "$INTERACTIVE" == true && "$BATCH" != true ]]; then
    run_interactive
else
    run_batch
fi
