#!/bin/bash
# AIDA Worktree Cleanup
# Purpose: Remove isolated development environment
# Usage: ./cleanup-worktree.sh <project-name> [--force]
#
# Cleans up worktrees created by init-worktree.sh

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
# Usage
# ============================================
usage() {
    cat << EOF
Usage: $(basename "$0") <project-name> [options]

Cleanup AIDA worktrees.

Options:
    --force     Force cleanup without confirmation
    --all       Remove all worktrees for the project
    --list      List all worktrees
    --help      Show this help message

Examples:
    $(basename "$0") my-project           # Cleanup most recent worktree
    $(basename "$0") my-project --all     # Cleanup all project worktrees
    $(basename "$0") --list               # List all worktrees
EOF
}

# ============================================
# Parse arguments
# ============================================
PROJECT=""
FORCE=false
ALL=false
LIST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --all)
            ALL=true
            shift
            ;;
        --list)
            LIST=true
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

WORKTREE_BASE="$PROJECT_ROOT/.aida/worktrees"

# ============================================
# List worktrees
# ============================================
list_worktrees() {
    echo -e "${BLUE}AIDA Worktrees${NC}"
    echo "======================================"

    if [[ ! -d "$WORKTREE_BASE" ]]; then
        echo "No worktrees found."
        return 0
    fi

    local count=0
    for wt in "$WORKTREE_BASE"/*; do
        [[ -d "$wt" ]] || continue

        local info_file="$wt/.aida-worktree"
        if [[ -f "$info_file" ]]; then
            local proj=$(jq -r '.project // "unknown"' "$info_file" 2>/dev/null)
            local branch=$(jq -r '.branch // "unknown"' "$info_file" 2>/dev/null)
            local backend=$(jq -r '.backend // "unknown"' "$info_file" 2>/dev/null)
            local created=$(jq -r '.created_at // "unknown"' "$info_file" 2>/dev/null)

            echo ""
            echo "  Project:  $proj"
            echo "  Branch:   $branch"
            echo "  Backend:  $backend"
            echo "  Created:  $created"
            echo "  Path:     $wt"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "No worktrees found."
    else
        echo ""
        echo "Total: $count worktrees"
    fi
}

if [[ "$LIST" == true ]]; then
    list_worktrees
    exit 0
fi

if [[ -z "$PROJECT" ]]; then
    usage
    exit 1
fi

# ============================================
# Find worktrees to cleanup
# ============================================
echo -e "${BLUE}AIDA Worktree Cleanup${NC}"
echo "======================================"
echo ""

if [[ ! -d "$WORKTREE_BASE" ]]; then
    echo "No worktrees found."
    exit 0
fi

# Find matching worktrees
WORKTREES=()
for wt in "$WORKTREE_BASE"/"$PROJECT"-*; do
    [[ -d "$wt" ]] && WORKTREES+=("$wt")
done

if [[ ${#WORKTREES[@]} -eq 0 ]]; then
    echo "No worktrees found for project: $PROJECT"
    exit 0
fi

echo "Found ${#WORKTREES[@]} worktree(s) for project: $PROJECT"
echo ""

# If not --all, only cleanup the most recent
if [[ "$ALL" != true && ${#WORKTREES[@]} -gt 1 ]]; then
    # Sort by modification time, get most recent
    WORKTREES=("$(ls -td "$WORKTREE_BASE/$PROJECT"-* 2>/dev/null | head -1)")
    echo "Cleaning up most recent worktree only (use --all for all)"
fi

# ============================================
# Cleanup each worktree
# ============================================
for wt in "${WORKTREES[@]}"; do
    [[ -d "$wt" ]] || continue

    info_file="$wt/.aida-worktree"
    backend="git"
    branch=""

    if [[ -f "$info_file" ]]; then
        backend=$(jq -r '.backend // "git"' "$info_file" 2>/dev/null)
        branch=$(jq -r '.branch // ""' "$info_file" 2>/dev/null)
    fi

    echo "Removing: $wt"
    echo "  Backend: $backend"

    if [[ "$FORCE" != true ]]; then
        read -r -p "  Continue? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "  Skipped."
            continue
        fi
    fi

    case "$backend" in
        jj)
            # Remove jj workspace
            jj workspace forget "$wt" 2>/dev/null || true
            rm -rf "$wt"
            ;;
        git)
            # Remove git worktree
            git -C "$PROJECT_ROOT" worktree remove "$wt" --force 2>/dev/null || rm -rf "$wt"

            # Optionally delete the branch
            if [[ -n "${branch:-}" && "$branch" =~ ^aida- ]]; then
                git -C "$PROJECT_ROOT" branch -D "$branch" 2>/dev/null || true
            fi
            ;;
        *)
            rm -rf "$wt"
            ;;
    esac

    echo -e "  ${GREEN}Removed${NC}"
done

# Update session file using safe_jq_update
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"
if [[ -f "$SESSION_FILE" ]]; then
    safe_jq_update "$SESSION_FILE" '.worktree = {"active": false}' 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Cleanup complete${NC}"
