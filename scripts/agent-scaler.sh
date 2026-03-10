#!/bin/bash
# AIDA Agent Scaler
# Purpose: Scale agents dynamically based on resources (#183, #184)
# Usage: ./agent-scaler.sh [command]
#
# Commands:
#   status      - Show current scaling status
#   scale       - Apply optimal scaling
#   scale N     - Scale to N agents
#   recommend   - Show recommended scaling
#   config      - Show/update configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Source common library (required - use ensure_dir, ensure_json_file, etc.)
source "$SCRIPT_DIR/lib/common.sh"

# State and config files
AIDA_DIR="$PROJECT_ROOT/.aida"
STATE_DIR="$AIDA_DIR/state"
CONFIG_FILE="$STATE_DIR/scaling-config.json"
AGENTS_FILE="$STATE_DIR/agents.json"

# Use ensure_dir from common.sh
ensure_dir "$STATE_DIR"

COMMAND="${1:-status}"

# ============================================
# Default Configuration
# ============================================

init_config() {
    # Use ensure_json_file from common.sh with default config
    local default_config='{
  "enabled": true,
  "auto_scale": false,
  "spawn_interval_ms": 5000,
  "resource_thresholds": {
    "memory_per_agent_gb": 4,
    "min_free_memory_gb": 8,
    "max_pid_usage_percent": 60
  },
  "agent_limits": {
    "min_impl_players": 2,
    "max_impl_players": 10,
    "min_spec_players": 1,
    "max_spec_players": 3
  },
  "cooldown": {
    "scale_up_delay_ms": 5000,
    "scale_down_delay_ms": 30000
  }
}'
    ensure_json_file "$CONFIG_FILE" "$default_config"
}

# ============================================
# Agent State Management
# ============================================

init_agents() {
    # Use ensure_json_file from common.sh with default agents state
    local default_agents='{"last_updated": "", "target_count": 2, "current_count": 0, "agents": [], "scaling_history": []}'
    ensure_json_file "$AGENTS_FILE" "$default_agents"
}

get_optimal_count() {
    "$SCRIPT_DIR/resource-monitor.sh" optimal
}

get_current_agents() {
    # Check for running Claude Code agents
    # This is a heuristic - actual implementation depends on deployment
    local count=0

    # Check for task agent processes
    if command -v pgrep &>/dev/null; then
        count=$(pgrep -f "claude.*agent" 2>/dev/null | wc -l | tr -d ' ')
        count="${count:-0}"
    fi

    # Also check agents.json for registered agents
    if [[ -f "$AGENTS_FILE" ]]; then
        local registered=$(jq -r '.agents | length' "$AGENTS_FILE" 2>/dev/null || echo "0")
        [[ $registered -gt $count ]] && count=$registered
    fi

    echo "$count"
}

register_agent() {
    local agent_id="$1"
    local agent_type="${2:-impl}"
    local timestamp=$(date -Iseconds)

    init_agents

    # Add agent to list
    local updated=$(jq --arg id "$agent_id" --arg type "$agent_type" --arg ts "$timestamp" '
        .agents += [{
            "id": $id,
            "type": $type,
            "status": "active",
            "started_at": $ts,
            "last_heartbeat": $ts
        }] |
        .current_count = (.agents | length) |
        .last_updated = $ts
    ' "$AGENTS_FILE")

    echo "$updated" > "$AGENTS_FILE"
    log_info "Registered agent: $agent_id ($agent_type)"
}

unregister_agent() {
    local agent_id="$1"
    local timestamp=$(date -Iseconds)

    [[ ! -f "$AGENTS_FILE" ]] && return 0

    local updated=$(jq --arg id "$agent_id" --arg ts "$timestamp" '
        .agents = [.agents[] | select(.id != $id)] |
        .current_count = (.agents | length) |
        .last_updated = $ts
    ' "$AGENTS_FILE")

    echo "$updated" > "$AGENTS_FILE"
    log_info "Unregistered agent: $agent_id"
}

# ============================================
# Scaling Operations
# ============================================

record_scaling() {
    local from_count="$1"
    local to_count="$2"
    local reason="$3"
    local timestamp=$(date -Iseconds)

    init_agents

    local updated=$(jq --arg from "$from_count" --arg to "$to_count" \
        --arg reason "$reason" --arg ts "$timestamp" '
        .scaling_history += [{
            "timestamp": $ts,
            "from": ($from | tonumber),
            "to": ($to | tonumber),
            "reason": $reason
        }] |
        .target_count = ($to | tonumber) |
        .last_updated = $ts |
        # Keep only last 100 entries
        .scaling_history = .scaling_history[-100:]
    ' "$AGENTS_FILE")

    echo "$updated" > "$AGENTS_FILE"
}

scale_to() {
    local target_count="$1"
    local current_count=$(get_current_agents)
    local reason="${2:-manual}"

    init_config
    init_agents

    # Read limits
    local min_agents=$(jq -r '.agent_limits.min_impl_players' "$CONFIG_FILE")
    local max_agents=$(jq -r '.agent_limits.max_impl_players' "$CONFIG_FILE")

    # Apply bounds
    [[ $target_count -lt $min_agents ]] && target_count=$min_agents
    [[ $target_count -gt $max_agents ]] && target_count=$max_agents

    if [[ $target_count -eq $current_count ]]; then
        log_info "Already at target count: $target_count"
        return 0
    fi

    log_info "Scaling from $current_count to $target_count agents"
    record_scaling "$current_count" "$target_count" "$reason"

    # Update target in state
    local updated=$(jq --arg target "$target_count" '
        .target_count = ($target | tonumber)
    ' "$AGENTS_FILE")
    echo "$updated" > "$AGENTS_FILE"

    # Output scaling instruction
    cat << EOF
{
  "action": "scale",
  "from": $current_count,
  "to": $target_count,
  "delta": $((target_count - current_count)),
  "reason": "$reason",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

auto_scale() {
    local optimal=$(get_optimal_count)
    scale_to "$optimal" "auto_scale"
}

# ============================================
# Status and Recommendations
# ============================================

show_status() {
    init_config
    init_agents

    local current=$(get_current_agents)
    local optimal=$(get_optimal_count)
    local target=$(jq -r '.target_count // 2' "$AGENTS_FILE")

    echo "=== AIDA Agent Scaler ==="
    echo ""
    echo "Agent Status:"
    echo "  Current:  $current agents"
    echo "  Target:   $target agents"
    echo "  Optimal:  $optimal agents"
    echo ""

    # Show registered agents
    if [[ -f "$AGENTS_FILE" ]]; then
        local agent_count=$(jq '.agents | length' "$AGENTS_FILE")
        if [[ $agent_count -gt 0 ]]; then
            echo "Registered Agents:"
            jq -r '.agents[] | "  - \(.id) (\(.type)): \(.status)"' "$AGENTS_FILE"
            echo ""
        fi
    fi

    # Show config
    if [[ -f "$CONFIG_FILE" ]]; then
        local enabled=$(jq -r '.enabled' "$CONFIG_FILE")
        local auto=$(jq -r '.auto_scale' "$CONFIG_FILE")
        echo "Configuration:"
        echo "  Scaling enabled: $enabled"
        echo "  Auto-scale:      $auto"
        echo "  Min agents:      $(jq -r '.agent_limits.min_impl_players' "$CONFIG_FILE")"
        echo "  Max agents:      $(jq -r '.agent_limits.max_impl_players' "$CONFIG_FILE")"
    fi
}

show_recommendation() {
    local optimal=$(get_optimal_count)
    local current=$(get_current_agents)

    echo "=== Scaling Recommendation ==="
    echo ""

    # Get resource details
    "$SCRIPT_DIR/resource-monitor.sh" status | grep -A 20 "Agent Scaling:"
    echo ""

    if [[ $optimal -gt $current ]]; then
        echo "Recommendation: SCALE UP"
        echo "  Current: $current agents"
        echo "  Optimal: $optimal agents"
        echo ""
        echo "Run: ./agent-scaler.sh scale $optimal"
    elif [[ $optimal -lt $current ]]; then
        echo "Recommendation: SCALE DOWN"
        echo "  Current: $current agents"
        echo "  Optimal: $optimal agents"
        echo ""
        echo "Run: ./agent-scaler.sh scale $optimal"
    else
        echo "Recommendation: NO CHANGE NEEDED"
        echo "  Current agent count ($current) is optimal"
    fi
}

show_config() {
    init_config

    if [[ -n "${2:-}" ]]; then
        # Update config
        local key="$2"
        local value="$3"
        local updated=$(jq --arg k "$key" --arg v "$value" '
            setpath($k | split("."); ($v | try tonumber // $v))
        ' "$CONFIG_FILE")
        echo "$updated" > "$CONFIG_FILE"
        log_success "Updated $key = $value"
    fi

    cat "$CONFIG_FILE" | jq '.'
}

show_history() {
    init_agents

    echo "=== Scaling History ==="
    echo ""

    if [[ -f "$AGENTS_FILE" ]]; then
        jq -r '.scaling_history[-10:][] |
            "\(.timestamp): \(.from) → \(.to) (\(.reason))"
        ' "$AGENTS_FILE" 2>/dev/null || echo "No scaling history"
    else
        echo "No scaling history"
    fi
}

# ============================================
# Main
# ============================================

case "$COMMAND" in
    status)
        show_status
        ;;
    scale)
        if [[ -n "${2:-}" ]]; then
            scale_to "$2" "manual"
        else
            auto_scale
        fi
        ;;
    recommend)
        show_recommendation
        ;;
    config)
        show_config "$@"
        ;;
    register)
        register_agent "${2:?Agent ID required}" "${3:-impl}"
        ;;
    unregister)
        unregister_agent "${2:?Agent ID required}"
        ;;
    history)
        show_history
        ;;
    json)
        init_config
        init_agents
        jq -s '.[0] * .[1]' "$CONFIG_FILE" "$AGENTS_FILE"
        ;;
    help|--help|-h)
        cat << 'EOF'
AIDA Agent Scaler

Usage:
  ./agent-scaler.sh [command] [args]

Commands:
  status              Show current scaling status (default)
  scale [N]           Scale to N agents (or auto-scale if N omitted)
  recommend           Show scaling recommendation
  config [key value]  Show or update configuration
  register ID [type]  Register a new agent
  unregister ID       Unregister an agent
  history             Show scaling history
  json                Output full state as JSON
  help                Show this help

Examples:
  ./agent-scaler.sh status
  ./agent-scaler.sh scale 5
  ./agent-scaler.sh scale         # Auto-scale to optimal
  ./agent-scaler.sh config agent_limits.max_impl_players 8
  ./agent-scaler.sh register player-impl-3 impl

Configuration:
  Config file: .aida/state/scaling-config.json
  Agents file: .aida/state/agents.json

EOF
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run './agent-scaler.sh help' for usage" >&2
        exit 1
        ;;
esac
