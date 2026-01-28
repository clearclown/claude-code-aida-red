#!/bin/bash
# AIDA jj Worktree Manager
# Purpose: Manage isolated work environments using jj
# Usage: ./jj-worktree.sh <command> [args]
#
# Commands:
#   create <name>   - Create new isolated worktree
#   list            - List all worktrees
#   switch <name>   - Switch to worktree
#   delete <name>   - Delete worktree
#   status          - Show current worktree status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

WORKTREE_BASE="$PROJECT_ROOT/.aida/worktrees"
COMMAND="${1:-help}"
shift || true

# ============================================
# Ensure jj is available (using require_command from common.sh)
# ============================================
ensure_jj() {
    if ! require_command jj "./scripts/setup-jj.sh (or cargo install --locked jj-cli)"; then
        exit 1
    fi

    if [[ ! -d "$PROJECT_ROOT/.jj" ]] && [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        log_error "Not in a jj or git repository"
        exit 1
    fi
}

# ============================================
# Create worktree
# ============================================
create_worktree() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Usage: jj-worktree.sh create <name>" >&2
        exit 1
    fi

    local worktree_path="$WORKTREE_BASE/$name"

    if [[ -d "$worktree_path" ]]; then
        echo "Worktree '$name' already exists at $worktree_path" >&2
        exit 1
    fi

    echo "Creating worktree: $name"
    ensure_dir "$WORKTREE_BASE"

    # Initialize jj if needed
    if [[ ! -d "$PROJECT_ROOT/.jj" ]]; then
        echo "Initializing jj in main repository..."
        cd "$PROJECT_ROOT"
        if [[ -d ".git" ]]; then
            jj git init --colocate
        else
            jj init
        fi
    fi

    # Create new change for this worktree
    cd "$PROJECT_ROOT"
    local change_id
    change_id=$(jj new -m "worktree: $name" --quiet 2>&1 | grep -oE '[a-z]{8,}' | head -1 || jj log -r @ --no-graph -T 'change_id.short(8)')

    # Create workspace
    jj workspace add "$worktree_path" --name "$name"

    echo "Created worktree: $name"
    echo "Path: $worktree_path"
    echo "Change: $change_id"

    # Save metadata
    cat > "$worktree_path/.aida-worktree.json" << EOF
{
  "name": "$name",
  "created_at": "$(date -Iseconds)",
  "change_id": "$change_id",
  "base_path": "$PROJECT_ROOT"
}
EOF

    echo ""
    echo "To switch to this worktree:"
    echo "  cd $worktree_path"
}

# ============================================
# List worktrees
# ============================================
list_worktrees() {
    echo "=== AIDA Worktrees ==="

    if [[ ! -d "$WORKTREE_BASE" ]]; then
        echo "No worktrees found."
        return 0
    fi

    # List jj workspaces if available
    if [[ -d "$PROJECT_ROOT/.jj" ]]; then
        echo ""
        echo "jj workspaces:"
        cd "$PROJECT_ROOT"
        jj workspace list
    fi

    echo ""
    echo "Worktree directories:"
    for wt in "$WORKTREE_BASE"/*; do
        if [[ -d "$wt" ]]; then
            local name
            name=$(basename "$wt")
            local info=""
            if [[ -f "$wt/.aida-worktree.json" ]]; then
                info=$(jq -r '"created: \(.created_at)"' "$wt/.aida-worktree.json" 2>/dev/null || echo "")
            fi
            echo "  - $name ($info)"
        fi
    done
}

# ============================================
# Switch to worktree
# ============================================
switch_worktree() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Usage: jj-worktree.sh switch <name>" >&2
        exit 1
    fi

    local worktree_path="$WORKTREE_BASE/$name"

    if [[ ! -d "$worktree_path" ]]; then
        echo "Worktree '$name' does not exist" >&2
        exit 1
    fi

    echo "Switched to worktree: $name"
    echo "Path: $worktree_path"
    echo ""
    echo "Run: cd $worktree_path"
}

# ============================================
# Delete worktree
# ============================================
delete_worktree() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Usage: jj-worktree.sh delete <name>" >&2
        exit 1
    fi

    local worktree_path="$WORKTREE_BASE/$name"

    if [[ ! -d "$worktree_path" ]]; then
        echo "Worktree '$name' does not exist" >&2
        exit 1
    fi

    echo "Deleting worktree: $name"

    # Remove jj workspace
    if [[ -d "$PROJECT_ROOT/.jj" ]]; then
        cd "$PROJECT_ROOT"
        jj workspace forget "$name" 2>/dev/null || true
    fi

    # Remove directory
    rm -rf "$worktree_path"

    echo "Worktree '$name' deleted"
}

# ============================================
# Show status
# ============================================
show_status() {
    echo "=== Worktree Status ==="

    # Check if we're in a worktree
    local current_dir
    current_dir=$(pwd)

    if [[ "$current_dir" == "$WORKTREE_BASE"/* ]]; then
        local wt_name
        wt_name=$(echo "$current_dir" | sed "s|$WORKTREE_BASE/||" | cut -d/ -f1)
        echo "Current worktree: $wt_name"

        if [[ -f ".aida-worktree.json" ]]; then
            jq . ".aida-worktree.json"
        fi
    else
        echo "Not in a worktree (main workspace)"
    fi

    # Show jj status if available
    if command -v jj &>/dev/null; then
        echo ""
        echo "jj status:"
        jj status 2>/dev/null || true
    fi
}

# ============================================
# Print help
# ============================================
print_help() {
    cat << 'EOF'
AIDA jj Worktree Manager

Usage:
  ./jj-worktree.sh <command> [args]

Commands:
  create <name>   Create new isolated worktree
  list            List all worktrees
  switch <name>   Show path to switch to worktree
  delete <name>   Delete worktree
  status          Show current worktree status
  help            Show this help

Examples:
  ./jj-worktree.sh create feature-auth
  cd .aida/worktrees/feature-auth
  # ... work in isolation ...
  ./jj-worktree.sh delete feature-auth

Benefits:
  - Complete isolation from main workspace
  - Automatic change tracking with jj
  - No conflicts with other work
  - Easy cleanup when done

EOF
}

# ============================================
# Main
# ============================================
case "$COMMAND" in
    create)
        ensure_jj
        create_worktree "$@"
        ;;
    list)
        list_worktrees
        ;;
    switch)
        switch_worktree "$@"
        ;;
    delete)
        delete_worktree "$@"
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        print_help
        exit 1
        ;;
esac
