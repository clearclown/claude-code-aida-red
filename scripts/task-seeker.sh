#!/bin/bash
# AIDA Task Seeker
# Purpose: Proactive task-seeking for idle agents (#174)
# Usage: ./task-seeker.sh [command]
#
# Commands:
#   available   - Publish agent availability
#   seek        - Actively seek tasks
#   poll        - Check for pending tasks
#   status      - Show task queue status
#   assign      - Assign task to agent

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Source common library
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    log_info() { echo "[INFO] $*" >&2; }
    log_success() { echo "[SUCCESS] $*" >&2; }
    log_warning() { echo "[WARNING] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# State files
AIDA_DIR="$PROJECT_ROOT/.aida"
STATE_DIR="$AIDA_DIR/state"
TASKS_DIR="$AIDA_DIR/tasks"
QUEUE_FILE="$AIDA_DIR/queue/queue.json"
AVAILABLE_FILE="$STATE_DIR/available-agents.json"
ASSIGNMENTS_FILE="$STATE_DIR/task-assignments.json"

ensure_dir "$STATE_DIR"
ensure_dir "$TASKS_DIR"
ensure_dir "$AIDA_DIR/queue"

COMMAND="${1:-status}"
AGENT_ID="${AGENT_ID:-agent-$(hostname)-$$}"

# ============================================
# Initialization
# ============================================

init_available() {
    if [[ ! -f "$AVAILABLE_FILE" ]]; then
        cat << 'EOF' > "$AVAILABLE_FILE"
{
  "available_agents": [],
  "last_updated": ""
}
EOF
    fi
}

init_assignments() {
    if [[ ! -f "$ASSIGNMENTS_FILE" ]]; then
        cat << 'EOF' > "$ASSIGNMENTS_FILE"
{
  "assignments": [],
  "completed": [],
  "last_updated": ""
}
EOF
    fi
}

# ============================================
# Availability Management
# ============================================

publish_available() {
    local agent_id="${1:-$AGENT_ID}"
    local leader="${2:-leader-impl}"
    local capabilities="${3:-general}"
    local timestamp=$(date -Iseconds)

    init_available

    # Update available agents list
    local updated=$(jq --arg id "$agent_id" --arg leader "$leader" \
        --arg caps "$capabilities" --arg ts "$timestamp" '
        # Remove existing entry for this agent
        .available_agents = [.available_agents[] | select(.agent_id != $id)] |
        # Add new entry
        .available_agents += [{
            "agent_id": $id,
            "leader": $leader,
            "capabilities": $caps,
            "available_since": $ts,
            "last_heartbeat": $ts
        }] |
        .last_updated = $ts
    ' "$AVAILABLE_FILE")

    echo "$updated" > "$AVAILABLE_FILE"

    # Output availability message
    cat << EOF
{
  "type": "AVAILABLE",
  "agent_id": "$agent_id",
  "leader": "$leader",
  "capabilities": "$capabilities",
  "timestamp": "$timestamp"
}
EOF
}

withdraw_available() {
    local agent_id="${1:-$AGENT_ID}"
    local timestamp=$(date -Iseconds)

    [[ ! -f "$AVAILABLE_FILE" ]] && return 0

    local updated=$(jq --arg id "$agent_id" --arg ts "$timestamp" '
        .available_agents = [.available_agents[] | select(.agent_id != $id)] |
        .last_updated = $ts
    ' "$AVAILABLE_FILE")

    echo "$updated" > "$AVAILABLE_FILE"
    log_info "Withdrew availability: $agent_id"
}

list_available() {
    init_available

    # Clean up stale entries (older than 5 minutes)
    local cutoff=$(date -d "5 minutes ago" -Iseconds 2>/dev/null || date -v-5M -Iseconds 2>/dev/null || echo "")

    if [[ -n "$cutoff" ]]; then
        local cleaned=$(jq --arg cutoff "$cutoff" '
            .available_agents = [.available_agents[] | select(.last_heartbeat >= $cutoff)]
        ' "$AVAILABLE_FILE")
        echo "$cleaned" > "$AVAILABLE_FILE"
    fi

    jq '.available_agents' "$AVAILABLE_FILE"
}

# ============================================
# Task Queue Operations
# ============================================

get_pending_tasks() {
    if [[ -f "$QUEUE_FILE" ]]; then
        jq '[.items[] | select(.status == "pending")]' "$QUEUE_FILE" 2>/dev/null || echo "[]"
    else
        # Check for task files
        local tasks="[]"
        for task_file in "$TASKS_DIR"/*.json; do
            [[ -f "$task_file" ]] || continue
            local status=$(jq -r '.status // "pending"' "$task_file")
            if [[ "$status" == "pending" ]]; then
                tasks=$(echo "$tasks" | jq --slurpfile t "$task_file" '. + $t')
            fi
        done
        echo "$tasks"
    fi
}

get_next_task() {
    local agent_id="${1:-$AGENT_ID}"
    local pending=$(get_pending_tasks)
    local count=$(echo "$pending" | jq 'length')

    if [[ $count -eq 0 ]]; then
        echo "null"
        return 1
    fi

    # Get highest priority task
    local next=$(echo "$pending" | jq '
        sort_by(.priority // 50) |
        reverse |
        .[0]
    ')

    echo "$next"
}

# ============================================
# Task Assignment
# ============================================

assign_task() {
    local task_id="$1"
    local agent_id="${2:-$AGENT_ID}"
    local timestamp=$(date -Iseconds)

    init_assignments

    # Record assignment
    local updated=$(jq --arg task "$task_id" --arg agent "$agent_id" --arg ts "$timestamp" '
        .assignments += [{
            "task_id": $task,
            "agent_id": $agent,
            "assigned_at": $ts,
            "status": "in_progress"
        }] |
        .last_updated = $ts
    ' "$ASSIGNMENTS_FILE")

    echo "$updated" > "$ASSIGNMENTS_FILE"

    # Update task status if using queue
    if [[ -f "$QUEUE_FILE" ]]; then
        local queue_updated=$(jq --arg id "$task_id" --arg agent "$agent_id" --arg ts "$timestamp" '
            .items = [.items[] |
                if .id == $id then
                    .status = "in_progress" |
                    .assigned_to = $agent |
                    .started_at = $ts
                else . end
            ]
        ' "$QUEUE_FILE")
        echo "$queue_updated" > "$QUEUE_FILE"
    fi

    # Withdraw availability
    withdraw_available "$agent_id"

    log_success "Assigned task $task_id to $agent_id"
}

complete_task() {
    local task_id="$1"
    local agent_id="${2:-$AGENT_ID}"
    local result="${3:-success}"
    local timestamp=$(date -Iseconds)

    init_assignments

    # Move from assignments to completed
    local updated=$(jq --arg task "$task_id" --arg agent "$agent_id" \
        --arg result "$result" --arg ts "$timestamp" '
        .assignments = [.assignments[] | select(.task_id != $task)] |
        .completed += [{
            "task_id": $task,
            "agent_id": $agent,
            "result": $result,
            "completed_at": $ts
        }] |
        .last_updated = $ts |
        # Keep only last 100 completed
        .completed = .completed[-100:]
    ' "$ASSIGNMENTS_FILE")

    echo "$updated" > "$ASSIGNMENTS_FILE"

    # Update queue
    if [[ -f "$QUEUE_FILE" ]]; then
        local queue_updated=$(jq --arg id "$task_id" --arg result "$result" --arg ts "$timestamp" '
            .items = [.items[] |
                if .id == $id then
                    .status = (if $result == "success" then "completed" else "failed" end) |
                    .completed_at = $ts
                else . end
            ]
        ' "$QUEUE_FILE")
        echo "$queue_updated" > "$QUEUE_FILE"
    fi

    log_success "Completed task $task_id ($result)"
}

# ============================================
# Proactive Task Seeking
# ============================================

seek_task() {
    local agent_id="${1:-$AGENT_ID}"
    local leader="${2:-leader-impl}"

    log_info "Agent $agent_id seeking task from $leader..."

    # First, publish availability
    publish_available "$agent_id" "$leader" > /dev/null

    # Then, check for pending tasks
    local next=$(get_next_task "$agent_id")

    if [[ "$next" != "null" ]] && [[ -n "$next" ]]; then
        local task_id=$(echo "$next" | jq -r '.id')
        local task_title=$(echo "$next" | jq -r '.title // .subject // "Unknown"')

        log_success "Found task: $task_id - $task_title"

        # Assign to self
        assign_task "$task_id" "$agent_id"

        # Output task for processing
        echo "$next"
        return 0
    else
        log_info "No pending tasks available"

        # Stay available
        echo '{"status": "idle", "message": "No tasks available"}'
        return 1
    fi
}

poll_loop() {
    local agent_id="${1:-$AGENT_ID}"
    local interval="${2:-3}"

    log_info "Starting poll loop for $agent_id (interval: ${interval}s)"
    log_info "Press Ctrl+C to stop"

    while true; do
        # Send heartbeat
        local timestamp=$(date -Iseconds)
        if [[ -f "$AVAILABLE_FILE" ]]; then
            local updated=$(jq --arg id "$agent_id" --arg ts "$timestamp" '
                .available_agents = [.available_agents[] |
                    if .agent_id == $id then .last_heartbeat = $ts else . end
                ]
            ' "$AVAILABLE_FILE")
            echo "$updated" > "$AVAILABLE_FILE"
        fi

        # Check for tasks
        local next=$(get_next_task "$agent_id")
        if [[ "$next" != "null" ]] && [[ -n "$next" ]]; then
            local task_id=$(echo "$next" | jq -r '.id')
            log_success "Task available: $task_id"
            echo "$next"
            return 0
        fi

        sleep "$interval"
    done
}

# ============================================
# Status Display
# ============================================

show_status() {
    echo "=== AIDA Task Seeker ==="
    echo ""

    # Pending tasks
    local pending=$(get_pending_tasks)
    local pending_count=$(echo "$pending" | jq 'length')
    echo "Pending Tasks: $pending_count"

    if [[ $pending_count -gt 0 ]]; then
        echo "$pending" | jq -r '.[] | "  - \(.id // "?"): \(.title // .subject // "Unknown")"' | head -5
        [[ $pending_count -gt 5 ]] && echo "  ... and $((pending_count - 5)) more"
    fi
    echo ""

    # Available agents
    init_available
    local available=$(jq '.available_agents | length' "$AVAILABLE_FILE")
    echo "Available Agents: $available"

    if [[ $available -gt 0 ]]; then
        jq -r '.available_agents[] | "  - \(.agent_id) (for \(.leader))"' "$AVAILABLE_FILE"
    fi
    echo ""

    # Current assignments
    init_assignments
    local assigned=$(jq '.assignments | length' "$ASSIGNMENTS_FILE")
    echo "Active Assignments: $assigned"

    if [[ $assigned -gt 0 ]]; then
        jq -r '.assignments[] | "  - \(.task_id) → \(.agent_id)"' "$ASSIGNMENTS_FILE"
    fi
    echo ""

    # Recent completions
    local completed=$(jq '.completed[-5:]' "$ASSIGNMENTS_FILE")
    local completed_count=$(echo "$completed" | jq 'length')

    if [[ $completed_count -gt 0 ]]; then
        echo "Recent Completions:"
        echo "$completed" | jq -r '.[] | "  - \(.task_id): \(.result)"'
    fi
}

# ============================================
# Main
# ============================================

case "$COMMAND" in
    status)
        show_status
        ;;
    available)
        publish_available "${2:-$AGENT_ID}" "${3:-leader-impl}" "${4:-general}"
        ;;
    withdraw)
        withdraw_available "${2:-$AGENT_ID}"
        ;;
    list-available)
        list_available
        ;;
    seek)
        seek_task "${2:-$AGENT_ID}" "${3:-leader-impl}"
        ;;
    poll)
        poll_loop "${2:-$AGENT_ID}" "${3:-3}"
        ;;
    next)
        get_next_task "${2:-$AGENT_ID}"
        ;;
    assign)
        assign_task "${2:?Task ID required}" "${3:-$AGENT_ID}"
        ;;
    complete)
        complete_task "${2:?Task ID required}" "${3:-$AGENT_ID}" "${4:-success}"
        ;;
    pending)
        get_pending_tasks
        ;;
    help|--help|-h)
        cat << 'EOF'
AIDA Task Seeker - Proactive Task Seeking for Idle Agents

Usage:
  ./task-seeker.sh [command] [args]

Commands:
  status              Show current status (default)
  available [id]      Publish agent availability
  withdraw [id]       Withdraw availability
  list-available      List all available agents
  seek [id] [leader]  Actively seek and claim a task
  poll [id] [sec]     Continuous polling for tasks
  next [id]           Get next available task (no assignment)
  assign <task> [id]  Assign task to agent
  complete <task>     Mark task as completed
  pending             List pending tasks
  help                Show this help

Environment:
  AGENT_ID  Agent identifier (default: auto-generated)

Examples:
  ./task-seeker.sh status
  ./task-seeker.sh available player-impl-1 leader-impl
  ./task-seeker.sh seek player-impl-1
  ./task-seeker.sh poll player-impl-1 5
  ./task-seeker.sh assign task-123 player-impl-1
  ./task-seeker.sh complete task-123 player-impl-1 success

Workflow:
  1. Agent publishes availability when idle
  2. Agent seeks tasks proactively
  3. Leader assigns tasks to available agents
  4. Agent completes task and re-publishes availability

EOF
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run './task-seeker.sh help' for usage" >&2
        exit 1
        ;;
esac
