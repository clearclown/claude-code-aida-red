#!/bin/bash
# AIDA Agent Coordinator
# Purpose: Coordinate agent scaling, task distribution, and resource management
# Usage: ./agent-coordinator.sh [command]
#
# This is the main orchestrator that ties together:
# - Resource monitoring (resource-monitor.sh)
# - Agent scaling (agent-scaler.sh)
# - Task seeking (task-seeker.sh)
# - Enhancement queue (enhancement-queue.sh)

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

# State
AIDA_DIR="$PROJECT_ROOT/.aida"
STATE_DIR="$AIDA_DIR/state"
COORDINATOR_STATE="$STATE_DIR/coordinator.json"

ensure_dir "$STATE_DIR"

COMMAND="${1:-status}"

# ============================================
# Initialization
# ============================================

init_state() {
    if [[ ! -f "$COORDINATOR_STATE" ]]; then
        cat << 'EOF' > "$COORDINATOR_STATE"
{
  "status": "inactive",
  "started_at": null,
  "mode": "manual",
  "last_coordination": null,
  "metrics": {
    "tasks_distributed": 0,
    "scaling_events": 0,
    "agents_managed": 0
  }
}
EOF
    fi
}

# ============================================
# Coordination Functions
# ============================================

coordinate() {
    local timestamp=$(date -Iseconds)

    log_info "Starting coordination cycle..."

    # 1. Check resources
    local optimal=$("$SCRIPT_DIR/resource-monitor.sh" optimal)
    log_info "Optimal agent count: $optimal"

    # 2. Check current scaling
    local current=$("$SCRIPT_DIR/agent-scaler.sh" json | jq -r '.current_count // 0')
    log_info "Current agent count: $current"

    # 3. Scale if needed
    if [[ $optimal -ne $current ]]; then
        log_info "Scaling from $current to $optimal..."
        "$SCRIPT_DIR/agent-scaler.sh" scale "$optimal" >/dev/null
    fi

    # 4. Check pending tasks
    local pending=$("$SCRIPT_DIR/task-seeker.sh" pending | jq 'length')
    log_info "Pending tasks: $pending"

    # 5. Check available agents
    local available=$("$SCRIPT_DIR/task-seeker.sh" list-available | jq 'length')
    log_info "Available agents: $available"

    # 6. Distribute tasks to available agents
    local distributed=0
    if [[ $pending -gt 0 ]] && [[ $available -gt 0 ]]; then
        local agents=$("$SCRIPT_DIR/task-seeker.sh" list-available)

        for agent_id in $(echo "$agents" | jq -r '.[].agent_id'); do
            local task=$("$SCRIPT_DIR/task-seeker.sh" next "$agent_id")
            if [[ "$task" != "null" ]] && [[ -n "$task" ]]; then
                local task_id=$(echo "$task" | jq -r '.id')
                "$SCRIPT_DIR/task-seeker.sh" assign "$task_id" "$agent_id" >/dev/null
                distributed=$((distributed + 1))
                log_success "Assigned task $task_id to $agent_id"
            fi
        done
    fi

    # 7. Update state
    init_state
    local updated=$(jq --arg ts "$timestamp" --argjson dist "$distributed" '
        .last_coordination = $ts |
        .metrics.tasks_distributed += $dist
    ' "$COORDINATOR_STATE")
    echo "$updated" > "$COORDINATOR_STATE"

    # 8. Output summary
    cat << EOF
{
  "timestamp": "$timestamp",
  "optimal_agents": $optimal,
  "current_agents": $current,
  "pending_tasks": $pending,
  "available_agents": $available,
  "tasks_distributed": $distributed
}
EOF
}

start_daemon() {
    local interval="${2:-30}"
    local timestamp=$(date -Iseconds)

    init_state

    # Update state
    local updated=$(jq --arg ts "$timestamp" '
        .status = "active" |
        .started_at = $ts |
        .mode = "daemon"
    ' "$COORDINATOR_STATE")
    echo "$updated" > "$COORDINATOR_STATE"

    log_info "Starting coordinator daemon (interval: ${interval}s)"
    log_info "Press Ctrl+C to stop"

    trap 'stop_daemon; exit 0' SIGINT SIGTERM

    while true; do
        coordinate
        sleep "$interval"
    done
}

stop_daemon() {
    local timestamp=$(date -Iseconds)

    if [[ -f "$COORDINATOR_STATE" ]]; then
        local updated=$(jq --arg ts "$timestamp" '
            .status = "inactive" |
            .stopped_at = $ts
        ' "$COORDINATOR_STATE")
        echo "$updated" > "$COORDINATOR_STATE"
    fi

    log_info "Coordinator stopped"
}

# ============================================
# Status and Reports
# ============================================

show_status() {
    init_state

    echo "=== AIDA Agent Coordinator ==="
    echo ""

    # Coordinator status
    local status=$(jq -r '.status' "$COORDINATOR_STATE")
    local mode=$(jq -r '.mode' "$COORDINATOR_STATE")
    echo "Coordinator Status: $status ($mode)"

    local last=$(jq -r '.last_coordination // "never"' "$COORDINATOR_STATE")
    echo "Last Coordination:  $last"
    echo ""

    # Resource summary
    echo "--- Resources ---"
    "$SCRIPT_DIR/resource-monitor.sh" status | grep -E "(Available|Cores|Optimal)" | head -5
    echo ""

    # Agent summary
    echo "--- Agents ---"
    "$SCRIPT_DIR/agent-scaler.sh" status | grep -E "(Current|Target|Optimal)" | head -5
    echo ""

    # Task summary
    echo "--- Tasks ---"
    "$SCRIPT_DIR/task-seeker.sh" status | grep -E "(Pending|Available|Active)" | head -5
    echo ""

    # Enhancement queue (if exists)
    if [[ -x "$SCRIPT_DIR/enhancement-queue.sh" ]]; then
        echo "--- Enhancement Queue ---"
        "$SCRIPT_DIR/enhancement-queue.sh" status 2>/dev/null | grep -E "(Pending|In Progress)" | head -3 || echo "  No queue data"
    fi
}

show_dashboard() {
    while true; do
        clear
        show_status
        echo ""
        echo "Refreshing every 5s... (Ctrl+C to exit)"
        sleep 5
    done
}

generate_report() {
    local timestamp=$(date -Iseconds)

    cat << EOF
{
  "report_timestamp": "$timestamp",
  "resources": $("$SCRIPT_DIR/resource-monitor.sh" json),
  "scaling": $("$SCRIPT_DIR/agent-scaler.sh" json),
  "tasks": {
    "pending": $("$SCRIPT_DIR/task-seeker.sh" pending | jq 'length'),
    "available_agents": $("$SCRIPT_DIR/task-seeker.sh" list-available | jq 'length')
  },
  "coordinator": $(cat "$COORDINATOR_STATE")
}
EOF
}

# ============================================
# Quick Actions
# ============================================

quick_scale() {
    log_info "Quick scaling to optimal..."
    local optimal=$("$SCRIPT_DIR/resource-monitor.sh" optimal)
    "$SCRIPT_DIR/agent-scaler.sh" scale "$optimal"
}

quick_distribute() {
    log_info "Quick task distribution..."
    coordinate | jq '.tasks_distributed'
}

# ============================================
# Main
# ============================================

case "$COMMAND" in
    status)
        show_status
        ;;
    coordinate)
        coordinate
        ;;
    start)
        start_daemon "$@"
        ;;
    stop)
        stop_daemon
        ;;
    dashboard)
        show_dashboard
        ;;
    report)
        generate_report
        ;;
    scale)
        quick_scale
        ;;
    distribute)
        quick_distribute
        ;;
    help|--help|-h)
        cat << 'EOF'
AIDA Agent Coordinator

Usage:
  ./agent-coordinator.sh [command] [args]

Commands:
  status              Show overall coordination status (default)
  coordinate          Run one coordination cycle
  start [interval]    Start daemon mode (default 30s interval)
  stop                Stop daemon
  dashboard           Live dashboard (refreshes every 5s)
  report              Generate full JSON report
  scale               Quick scale to optimal agent count
  distribute          Quick task distribution
  help                Show this help

Daemon Mode:
  The coordinator daemon continuously:
  1. Monitors system resources
  2. Scales agents based on capacity
  3. Distributes pending tasks
  4. Tracks agent availability

Examples:
  ./agent-coordinator.sh status
  ./agent-coordinator.sh coordinate    # Single cycle
  ./agent-coordinator.sh start 60      # Daemon with 60s interval
  ./agent-coordinator.sh dashboard     # Live view
  ./agent-coordinator.sh report | jq   # Full JSON report

Related Scripts:
  - resource-monitor.sh  - Resource monitoring
  - agent-scaler.sh      - Agent scaling
  - task-seeker.sh       - Task distribution
  - enhancement-queue.sh - Queue management

EOF
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run './agent-coordinator.sh help' for usage" >&2
        exit 1
        ;;
esac
