#!/bin/bash
# AIDA Worktree Initializer
# Purpose: Create isolated development environment using jj or git worktree
# Usage: ./init-worktree.sh <project-name> [--backend=jj|git]
#
# This script creates an isolated environment for AIDA development,
# preventing conflicts between parallel enhancement tasks.
# Supports both jj (Jujutsu) and git worktree backends.
#
# Issue #220: Environment isolation enforcement

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

Create an isolated development environment for AIDA projects.

Options:
    --backend=jj|git    Backend to use (default: auto-detect, prefer jj)
    --branch=NAME       Branch name (default: aida-<project>-<timestamp>)
    --help              Show this help message

Examples:
    $(basename "$0") my-project
    $(basename "$0") my-project --backend=jj
    $(basename "$0") my-project --backend=git --branch=feature/new-api

Environment Variables (exported on success):
    AIDA_WORKTREE       = true
    WORKTREE_PATH       = path to worktree
    WORKTREE_BRANCH     = branch name
    WORKTREE_BACKEND    = jj or git

To cleanup, run: ./cleanup-worktree.sh <project-name>
Or delete the worktree manually and remove the branch.
EOF
}

# ============================================
# Parse arguments
# ============================================
PROJECT=""
BACKEND=""
BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend=*)
            BACKEND="${1#*=}"
            shift
            ;;
        --branch=*)
            BRANCH="${1#*=}"
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
# Check for required tools (using common.sh)
# ============================================

# Auto-detect backend if not specified
if [[ -z "$BACKEND" ]]; then
    if command -v jj &>/dev/null; then
        BACKEND="jj"
    elif command -v git &>/dev/null; then
        BACKEND="git"
    else
        log_error "Neither jj nor git found. Install one to continue."
        exit 1
    fi
fi

# Validate backend
case "$BACKEND" in
    jj)
        if ! require_command jj "cargo install --locked jj-cli"; then
            exit 1
        fi
        ;;
    git)
        if ! require_command git; then
            exit 1
        fi
        ;;
    *)
        log_error "Unknown backend '$BACKEND'. Use 'jj' or 'git'."
        exit 1
        ;;
esac

# ============================================
# Generate branch name if not specified
# ============================================
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
if [[ -z "$BRANCH" ]]; then
    BRANCH="aida-${PROJECT}-${TIMESTAMP}"
fi

# ============================================
# Worktree paths
# ============================================
WORKTREE_BASE="$PROJECT_ROOT/.aida/worktrees"
WORKTREE_PATH="$WORKTREE_BASE/$PROJECT-$TIMESTAMP"

ensure_dir "$WORKTREE_BASE"

echo -e "${BLUE}AIDA Worktree Initializer${NC}"
echo "======================================"
echo ""
echo "Project:  $PROJECT"
echo "Backend:  $BACKEND"
echo "Branch:   $BRANCH"
echo "Path:     $WORKTREE_PATH"
echo ""

# ============================================
# Create worktree
# ============================================
case "$BACKEND" in
    jj)
        echo -e "${YELLOW}Creating jj worktree...${NC}"

        # Check if in a jj repo
        if [[ ! -d "$PROJECT_ROOT/.jj" ]]; then
            echo "Initializing jj repository..." >&2
            jj git init --colocate 2>/dev/null || jj init 2>/dev/null || true
        fi

        # Create new change (jj's equivalent to a branch)
        ensure_dir "$WORKTREE_PATH"
        cd "$WORKTREE_PATH"

        # Initialize as a new jj workspace
        jj workspace add "$WORKTREE_PATH" 2>/dev/null || {
            # Fallback: copy and init
            cp -r "$PROJECT_ROOT" "$WORKTREE_PATH" 2>/dev/null || true
            cd "$WORKTREE_PATH"
            jj new -m "AIDA Enhancement: $PROJECT" 2>/dev/null || true
        }

        echo -e "${GREEN}jj worktree created successfully${NC}"
        ;;

    git)
        echo -e "${YELLOW}Creating git worktree...${NC}"

        # Check if in a git repo
        if ! git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null; then
            echo -e "${RED}Error: Not a git repository${NC}" >&2
            exit 1
        fi

        cd "$PROJECT_ROOT"

        # Create worktree with new branch
        git worktree add -b "$BRANCH" "$WORKTREE_PATH" 2>/dev/null || {
            # Branch might exist, try without -b
            git worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null || {
                echo -e "${RED}Failed to create git worktree${NC}" >&2
                exit 1
            }
        }

        echo -e "${GREEN}git worktree created successfully${NC}"
        ;;
esac

# ============================================
# Export environment variables
# ============================================
export AIDA_WORKTREE="true"
export WORKTREE_PATH="$WORKTREE_PATH"
export WORKTREE_BRANCH="$BRANCH"
export WORKTREE_BACKEND="$BACKEND"

# Save to session file
SESSION_FILE="$PROJECT_ROOT/.aida/state/session.json"
if [[ -f "$SESSION_FILE" ]]; then
    jq --arg wt "$WORKTREE_PATH" \
       --arg br "$BRANCH" \
       --arg be "$BACKEND" \
       '.worktree = {
           "active": true,
           "path": $wt,
           "branch": $br,
           "backend": $be,
           "created_at": (now | todate)
       }' "$SESSION_FILE" > "${SESSION_FILE}.tmp" && \
       mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
fi

# Create worktree info file
cat > "$WORKTREE_PATH/.aida-worktree" << EOF
{
    "project": "$PROJECT",
    "branch": "$BRANCH",
    "backend": "$BACKEND",
    "created_at": "$(date -Iseconds)",
    "parent": "$PROJECT_ROOT"
}
EOF

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Worktree Created Successfully${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Environment Variables:"
echo "  AIDA_WORKTREE=$AIDA_WORKTREE"
echo "  WORKTREE_PATH=$WORKTREE_PATH"
echo "  WORKTREE_BRANCH=$WORKTREE_BRANCH"
echo "  WORKTREE_BACKEND=$WORKTREE_BACKEND"
echo ""
echo -e "${YELLOW}To work in the worktree:${NC}"
echo "  cd $WORKTREE_PATH"
echo ""
echo -e "${YELLOW}To cleanup when done:${NC}"
echo "  ./scripts/cleanup-worktree.sh $PROJECT"
echo ""
