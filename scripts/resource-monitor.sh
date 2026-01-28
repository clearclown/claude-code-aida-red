#!/bin/bash
# AIDA Resource Monitor
# Purpose: Monitor system resources for dynamic agent scaling (#184)
# Usage: ./resource-monitor.sh [command]
#
# Commands:
#   status    - Show current resource status
#   optimal   - Calculate optimal agent count
#   json      - Output as JSON
#   watch     - Continuous monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Configuration
MEMORY_PER_AGENT_GB="${MEMORY_PER_AGENT_GB:-4}"
MIN_FREE_MEMORY_GB="${MIN_FREE_MEMORY_GB:-8}"
MAX_PID_USAGE_PERCENT="${MAX_PID_USAGE_PERCENT:-60}"
MIN_AGENTS="${MIN_AGENTS:-2}"
MAX_AGENTS="${MAX_AGENTS:-10}"

COMMAND="${1:-status}"

# ============================================
# Resource Detection Functions
# ============================================

get_memory_info() {
    if [[ -f /proc/meminfo ]]; then
        local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local total_gb=$((total_kb / 1024 / 1024))
        local available_gb=$((available_kb / 1024 / 1024))
        local used_gb=$((total_gb - available_gb))
        local usage_percent=$((100 - (available_kb * 100 / total_kb)))
        echo "$total_gb $available_gb $used_gb $usage_percent"
    elif command -v sysctl &>/dev/null; then
        # macOS
        local total_bytes=$(sysctl -n hw.memsize)
        local total_gb=$((total_bytes / 1024 / 1024 / 1024))
        local page_size=$(sysctl -n vm.pagesize)
        local free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
        local available_gb=$((free_pages * page_size / 1024 / 1024 / 1024))
        local used_gb=$((total_gb - available_gb))
        local usage_percent=$((used_gb * 100 / total_gb))
        echo "$total_gb $available_gb $used_gb $usage_percent"
    else
        echo "0 0 0 0"
    fi
}

get_cpu_info() {
    if [[ -f /proc/cpuinfo ]]; then
        local cores=$(grep -c ^processor /proc/cpuinfo)
        local load_1m=$(cat /proc/loadavg | awk '{print $1}')
        local load_percent=$(echo "$load_1m $cores" | awk '{printf "%.0f", ($1/$2)*100}')
        echo "$cores $load_1m $load_percent"
    elif command -v sysctl &>/dev/null; then
        # macOS
        local cores=$(sysctl -n hw.ncpu)
        local load_1m=$(sysctl -n vm.loadavg | awk '{print $2}')
        local load_percent=$(echo "$load_1m $cores" | awk '{printf "%.0f", ($1/$2)*100}')
        echo "$cores $load_1m $load_percent"
    else
        echo "1 0 0"
    fi
}

get_pid_info() {
    if [[ -f /proc/sys/kernel/pid_max ]]; then
        local pid_max=$(cat /proc/sys/kernel/pid_max)
        local pid_current=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
        local pid_usage_percent=$((pid_current * 100 / pid_max))
        echo "$pid_max $pid_current $pid_usage_percent"
    else
        # Fallback
        local pid_current=$(ps aux | wc -l)
        echo "32768 $pid_current 0"
    fi
}

# ============================================
# Calculate Optimal Agent Count
# ============================================

calculate_optimal_agents() {
    read -r mem_total mem_available mem_used mem_usage <<< "$(get_memory_info)"
    read -r cpu_cores load_1m load_percent <<< "$(get_cpu_info)"
    read -r pid_max pid_current pid_usage <<< "$(get_pid_info)"

    # Memory-based limit: available GB / GB per agent, leaving min free
    local mem_for_agents=$((mem_available - MIN_FREE_MEMORY_GB))
    [[ $mem_for_agents -lt 0 ]] && mem_for_agents=0
    local mem_based=$((mem_for_agents / MEMORY_PER_AGENT_GB))

    # CPU-based limit: cores * 2 (agents are I/O bound)
    local cpu_based=$((cpu_cores * 2))

    # PID-based limit: ensure we stay under max PID usage
    local pid_headroom=$(( (pid_max * (100 - MAX_PID_USAGE_PERCENT) / 100) - pid_current ))
    local pids_per_agent=100  # Estimate
    local pid_based=$((pid_headroom / pids_per_agent))
    [[ $pid_based -lt 0 ]] && pid_based=0

    # Take minimum of all limits
    local optimal=$mem_based
    [[ $cpu_based -lt $optimal ]] && optimal=$cpu_based
    [[ $pid_based -lt $optimal ]] && optimal=$pid_based

    # Apply min/max bounds
    [[ $optimal -lt $MIN_AGENTS ]] && optimal=$MIN_AGENTS
    [[ $optimal -gt $MAX_AGENTS ]] && optimal=$MAX_AGENTS

    echo "$optimal $mem_based $cpu_based $pid_based"
}

# ============================================
# Output Functions
# ============================================

show_status() {
    read -r mem_total mem_available mem_used mem_usage <<< "$(get_memory_info)"
    read -r cpu_cores load_1m load_percent <<< "$(get_cpu_info)"
    read -r pid_max pid_current pid_usage <<< "$(get_pid_info)"
    read -r optimal mem_based cpu_based pid_based <<< "$(calculate_optimal_agents)"

    echo "=== AIDA Resource Monitor ==="
    echo ""
    echo "Memory:"
    echo "  Total:     ${mem_total}GB"
    echo "  Available: ${mem_available}GB"
    echo "  Used:      ${mem_used}GB (${mem_usage}%)"
    echo ""
    echo "CPU:"
    echo "  Cores:     $cpu_cores"
    echo "  Load:      $load_1m (${load_percent}%)"
    echo ""
    echo "PIDs:"
    echo "  Max:       $pid_max"
    echo "  Current:   $pid_current"
    echo "  Usage:     ${pid_usage}%"
    echo ""
    echo "Agent Scaling:"
    echo "  Memory-based limit:  $mem_based"
    echo "  CPU-based limit:     $cpu_based"
    echo "  PID-based limit:     $pid_based"
    echo "  ---"
    echo "  Optimal agent count: $optimal"
}

show_json() {
    read -r mem_total mem_available mem_used mem_usage <<< "$(get_memory_info)"
    read -r cpu_cores load_1m load_percent <<< "$(get_cpu_info)"
    read -r pid_max pid_current pid_usage <<< "$(get_pid_info)"
    read -r optimal mem_based cpu_based pid_based <<< "$(calculate_optimal_agents)"

    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "memory": {
    "total_gb": $mem_total,
    "available_gb": $mem_available,
    "used_gb": $mem_used,
    "usage_percent": $mem_usage
  },
  "cpu": {
    "cores": $cpu_cores,
    "load_1m": $load_1m,
    "usage_percent": $load_percent
  },
  "pids": {
    "max": $pid_max,
    "current": $pid_current,
    "usage_percent": $pid_usage
  },
  "scaling": {
    "memory_based": $mem_based,
    "cpu_based": $cpu_based,
    "pid_based": $pid_based,
    "optimal": $optimal,
    "config": {
      "memory_per_agent_gb": $MEMORY_PER_AGENT_GB,
      "min_free_memory_gb": $MIN_FREE_MEMORY_GB,
      "max_pid_usage_percent": $MAX_PID_USAGE_PERCENT,
      "min_agents": $MIN_AGENTS,
      "max_agents": $MAX_AGENTS
    }
  }
}
EOF
}

show_optimal() {
    read -r optimal _ _ _ <<< "$(calculate_optimal_agents)"
    echo "$optimal"
}

watch_resources() {
    local interval="${2:-5}"
    echo "Monitoring resources every ${interval}s (Ctrl+C to stop)..."
    echo ""

    while true; do
        clear
        show_status
        echo ""
        echo "Next update in ${interval}s..."
        sleep "$interval"
    done
}

# ============================================
# Main
# ============================================

case "$COMMAND" in
    status)
        show_status
        ;;
    optimal)
        show_optimal
        ;;
    json)
        show_json
        ;;
    watch)
        watch_resources "$@"
        ;;
    help|--help|-h)
        cat << 'EOF'
AIDA Resource Monitor

Usage:
  ./resource-monitor.sh [command]

Commands:
  status    Show current resource status (default)
  optimal   Output just the optimal agent count
  json      Output as JSON
  watch [s] Continuous monitoring (default 5s interval)
  help      Show this help

Environment Variables:
  MEMORY_PER_AGENT_GB     Memory reserved per agent (default: 4)
  MIN_FREE_MEMORY_GB      Minimum free memory to maintain (default: 8)
  MAX_PID_USAGE_PERCENT   Maximum PID usage (default: 60)
  MIN_AGENTS              Minimum agent count (default: 2)
  MAX_AGENTS              Maximum agent count (default: 10)

Examples:
  ./resource-monitor.sh status
  ./resource-monitor.sh optimal
  ./resource-monitor.sh json | jq '.scaling.optimal'
  MAX_AGENTS=20 ./resource-monitor.sh optimal

EOF
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run './resource-monitor.sh help' for usage" >&2
        exit 1
        ;;
esac
