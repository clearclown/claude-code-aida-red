#!/bin/bash
# AIDA Enhancement Queue Manager
# Purpose: Manage parallel enhancement tasks
# Usage: ./enhancement-queue.sh <command> [args]
#
# Commands:
#   add <project> <description>  - Add enhancement to queue
#   list                         - List queued enhancements
#   next                         - Get next enhancement to work on
#   start <id>                   - Mark enhancement as in-progress
#   complete <id>                - Mark enhancement as complete
#   cancel <id>                  - Cancel enhancement
#   status                       - Show queue status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

QUEUE_DIR="$PROJECT_ROOT/.aida/queue"
QUEUE_FILE="$QUEUE_DIR/queue.json"
COMMAND="${1:-help}"
shift || true

# ============================================
# Initialize queue
# ============================================
init_queue() {
    ensure_dir "$QUEUE_DIR"
    ensure_json_file "$QUEUE_FILE" '{"items": [], "next_id": 1}'
}

# ============================================
# Add to queue
# ============================================
add_to_queue() {
    local project="${1:-}"
    local description="${2:-}"
    local priority="${3:-medium}"  # Priority: high, medium, low

    if [[ -z "$project" ]] || [[ -z "$description" ]]; then
        echo "Usage: enhancement-queue.sh add <project> <description> [priority]" >&2
        echo "  priority: high, medium (default), low" >&2
        exit 1
    fi

    # Validate priority
    case "$priority" in
        high|medium|low) ;;
        *)
            echo "Invalid priority: $priority (use: high, medium, low)" >&2
            exit 1
            ;;
    esac

    init_queue

    local id
    id=$(jq -r '.next_id' "$QUEUE_FILE")

    # Map priority to numeric value for sorting
    local priority_num=2
    case "$priority" in
        high) priority_num=1 ;;
        medium) priority_num=2 ;;
        low) priority_num=3 ;;
    esac

    local updated
    updated=$(jq --arg proj "$project" --arg desc "$description" --argjson id "$id" \
        --arg pri "$priority" --argjson pri_num "$priority_num" '
        .items += [{
            "id": $id,
            "project": $proj,
            "description": $desc,
            "status": "pending",
            "priority": $pri,
            "priority_num": $pri_num,
            "created_at": (now | todate),
            "worktree": null
        }] |
        .next_id = ($id + 1)
    ' "$QUEUE_FILE")

    echo "$updated" > "$QUEUE_FILE"

    echo "Added enhancement #$id to queue:"
    echo "  Project: $project"
    echo "  Description: $description"
    echo "  Priority: $priority"
}

# ============================================
# List queue
# ============================================
list_queue() {
    init_queue

    echo "=== Enhancement Queue ==="
    echo ""

    # Show items with priority
    jq -r '.items[] | "[\(.status | ascii_upcase)] #\(.id) [\(.priority // "medium" | ascii_upcase)] - \(.project): \(.description)"' "$QUEUE_FILE"

    local pending in_progress completed
    pending=$(jq '[.items[] | select(.status == "pending")] | length' "$QUEUE_FILE")
    in_progress=$(jq '[.items[] | select(.status == "in_progress")] | length' "$QUEUE_FILE")
    completed=$(jq '[.items[] | select(.status == "completed")] | length' "$QUEUE_FILE")

    echo ""
    echo "Summary: $pending pending, $in_progress in progress, $completed completed"
}

# ============================================
# Get next item (sorted by priority)
# ============================================
get_next() {
    init_queue

    # Sort by priority_num (lower = higher priority), then by id (FIFO)
    local next
    next=$(jq -r '[.items[] | select(.status == "pending")] | sort_by(.priority_num, .id) | .[0] | "\(.id):\(.project):\(.description):\(.priority // "medium")"' "$QUEUE_FILE" 2>/dev/null)

    if [[ -z "$next" ]] || [[ "$next" == "null" ]] || [[ "$next" == ":::" ]]; then
        echo "No pending enhancements in queue"
        return 1
    fi

    local id project description priority
    IFS=':' read -r id project description priority <<< "$next"

    echo "Next enhancement: #$id"
    echo "  Project: $project"
    echo "  Description: $description"
    echo "  Priority: ${priority:-medium}"
    echo ""
    echo "To start: ./enhancement-queue.sh start $id"
}

# ============================================
# Start enhancement
# ============================================
start_enhancement() {
    local id="${1:-}"

    if [[ -z "$id" ]]; then
        echo "Usage: enhancement-queue.sh start <id>" >&2
        exit 1
    fi

    init_queue

    # Check if item exists
    local exists
    exists=$(jq --argjson id "$id" '[.items[] | select(.id == $id)] | length' "$QUEUE_FILE")

    if [[ "$exists" -eq 0 ]]; then
        echo "Enhancement #$id not found" >&2
        exit 1
    fi

    # Get project name
    local project
    project=$(jq -r --argjson id "$id" '.items[] | select(.id == $id) | .project' "$QUEUE_FILE")

    # Create worktree for this enhancement
    local worktree_name="enhance-$id"

    if [[ -x "$SCRIPT_DIR/jj-worktree.sh" ]]; then
        "$SCRIPT_DIR/jj-worktree.sh" create "$worktree_name" || true
    fi

    # Update status
    local updated
    updated=$(jq --argjson id "$id" --arg wt "$worktree_name" '
        .items = [.items[] | if .id == $id then
            .status = "in_progress" |
            .started_at = (now | todate) |
            .worktree = $wt
        else . end]
    ' "$QUEUE_FILE")

    echo "$updated" > "$QUEUE_FILE"

    echo "Started enhancement #$id"
    echo "Worktree: $worktree_name"
    echo ""
    echo "To work on this enhancement:"
    echo "  cd .aida/worktrees/$worktree_name"
}

# ============================================
# Complete enhancement
# ============================================
complete_enhancement() {
    local id="${1:-}"

    if [[ -z "$id" ]]; then
        echo "Usage: enhancement-queue.sh complete <id>" >&2
        exit 1
    fi

    init_queue

    # Get worktree
    local worktree
    worktree=$(jq -r --argjson id "$id" '.items[] | select(.id == $id) | .worktree // empty' "$QUEUE_FILE")

    # Update status
    local updated
    updated=$(jq --argjson id "$id" '
        .items = [.items[] | if .id == $id then
            .status = "completed" |
            .completed_at = (now | todate)
        else . end]
    ' "$QUEUE_FILE")

    echo "$updated" > "$QUEUE_FILE"

    # Cleanup worktree
    if [[ -n "$worktree" ]] && [[ -x "$SCRIPT_DIR/jj-worktree.sh" ]]; then
        "$SCRIPT_DIR/jj-worktree.sh" delete "$worktree" 2>/dev/null || true
    fi

    echo "Completed enhancement #$id"
}

# ============================================
# Cancel enhancement
# ============================================
cancel_enhancement() {
    local id="${1:-}"

    if [[ -z "$id" ]]; then
        echo "Usage: enhancement-queue.sh cancel <id>" >&2
        exit 1
    fi

    init_queue

    # Get worktree
    local worktree
    worktree=$(jq -r --argjson id "$id" '.items[] | select(.id == $id) | .worktree // empty' "$QUEUE_FILE")

    # Update status
    local updated
    updated=$(jq --argjson id "$id" '
        .items = [.items[] | if .id == $id then
            .status = "cancelled" |
            .cancelled_at = (now | todate)
        else . end]
    ' "$QUEUE_FILE")

    echo "$updated" > "$QUEUE_FILE"

    # Cleanup worktree
    if [[ -n "$worktree" ]] && [[ -x "$SCRIPT_DIR/jj-worktree.sh" ]]; then
        "$SCRIPT_DIR/jj-worktree.sh" delete "$worktree" 2>/dev/null || true
    fi

    echo "Cancelled enhancement #$id"
}

# ============================================
# Show status
# ============================================
show_status() {
    init_queue

    echo "=== Queue Status ==="
    echo ""

    local total pending in_progress completed cancelled
    total=$(jq '.items | length' "$QUEUE_FILE")
    pending=$(jq '[.items[] | select(.status == "pending")] | length' "$QUEUE_FILE")
    in_progress=$(jq '[.items[] | select(.status == "in_progress")] | length' "$QUEUE_FILE")
    completed=$(jq '[.items[] | select(.status == "completed")] | length' "$QUEUE_FILE")
    cancelled=$(jq '[.items[] | select(.status == "cancelled")] | length' "$QUEUE_FILE")

    echo "Total: $total"
    echo "Pending: $pending"
    echo "In Progress: $in_progress"
    echo "Completed: $completed"
    echo "Cancelled: $cancelled"

    if [[ $in_progress -gt 0 ]]; then
        echo ""
        echo "Currently active:"
        jq -r '.items[] | select(.status == "in_progress") | "  #\(.id) - \(.project): \(.description)"' "$QUEUE_FILE"
    fi
}

# ============================================
# Print help
# ============================================
print_help() {
    cat << 'EOF'
AIDA Enhancement Queue Manager

Usage:
  ./enhancement-queue.sh <command> [args]

Commands:
  add <project> <desc> [priority]  Add enhancement to queue
  list                             List all enhancements
  next                             Get next pending enhancement (by priority)
  start <id>                       Start working on enhancement
  complete <id>                    Mark enhancement as complete
  cancel <id>                      Cancel enhancement
  status                           Show queue status
  help                             Show this help

Priority Levels:
  high    - Critical features, bugs, blockers
  medium  - Normal features (default)
  low     - Nice-to-have, refactoring

Examples:
  # Add enhancements with priority
  ./enhancement-queue.sh add my-app "Fix security bug" high
  ./enhancement-queue.sh add my-app "Add user auth" medium
  ./enhancement-queue.sh add my-app "Refactor utils" low

  # Work through queue (highest priority first)
  ./enhancement-queue.sh next
  ./enhancement-queue.sh start 1
  # ... work ...
  ./enhancement-queue.sh complete 1

Parallel Work:
  Each enhancement gets its own worktree (if jj is configured).
  Multiple enhancements can be in progress simultaneously.

EOF
}

# ============================================
# Main
# ============================================
case "$COMMAND" in
    add)
        add_to_queue "$@"
        ;;
    list)
        list_queue
        ;;
    next)
        get_next
        ;;
    start)
        start_enhancement "$@"
        ;;
    complete)
        complete_enhancement "$@"
        ;;
    cancel)
        cancel_enhancement "$@"
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
