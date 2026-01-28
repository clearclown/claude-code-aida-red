#!/bin/bash
# AIDA Checkpoint Manager
# Saves and restores session state for resumption
#
# Usage:
#   ./scripts/checkpoint.sh save <project-name>
#   ./scripts/checkpoint.sh restore <project-name>
#   ./scripts/checkpoint.sh status <project-name>
#   ./scripts/checkpoint.sh list

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

CHECKPOINT_DIR="$PROJECT_ROOT/.aida/checkpoints"

# Use ensure_dir from common.sh
ensure_dir "$CHECKPOINT_DIR"

# Parse arguments
ACTION=${1:-}
PROJECT=${2:-}

show_usage() {
    echo "Usage: $0 <action> [project-name]"
    echo ""
    echo "Actions:"
    echo "  save <project>    Save current session state"
    echo "  restore <project> Restore session from checkpoint"
    echo "  status <project>  Show checkpoint status"
    echo "  list              List all checkpoints"
    exit 1
}

# Save checkpoint
save_checkpoint() {
    local project=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local checkpoint_file="$CHECKPOINT_DIR/${project}_${timestamp}.json"

    log_section "Saving Checkpoint - $project"

    # Check if session exists
    local session_file="$PROJECT_ROOT/.aida/state/session.json"
    if [[ ! -f "$session_file" ]]; then
        log_error "No active session found"
        exit 1
    fi

    # Create checkpoint data
    local checkpoint_data=$(cat <<EOF
{
  "checkpoint_id": "${project}_${timestamp}",
  "created_at": "$(date -Iseconds)",
  "project": "$project",
  "session": $(cat "$session_file"),
  "files": {
    "specs": $(find "$PROJECT_ROOT/.aida/specs" -name "${project}*" -type f 2>/dev/null | jq -R . | jq -s .),
    "results": $(find "$PROJECT_ROOT/.aida/results" -name "*${project}*" -type f 2>/dev/null | jq -R . | jq -s .),
    "project_exists": $([ -d "$PROJECT_ROOT/$project" ] && echo "true" || echo "false")
  },
  "quality_gates": {
    "last_run": "$(stat -c %Y "$PROJECT_ROOT/.aida/results/impl-complete.json" 2>/dev/null || echo 'null')"
  }
}
EOF
)

    echo "$checkpoint_data" > "$checkpoint_file"

    log_success "Checkpoint saved: $checkpoint_file"
    echo ""
    echo "To restore: $0 restore $project"
}

# Restore from checkpoint
restore_checkpoint() {
    local project=$1

    log_section "Restoring Checkpoint - $project"

    # Find latest checkpoint for project
    local latest=$(ls -t "$CHECKPOINT_DIR/${project}_"*.json 2>/dev/null | head -1)

    if [[ -z "$latest" ]]; then
        log_error "No checkpoint found for project: $project"
        exit 1
    fi

    log_info "Found checkpoint: $latest"

    # Extract session from checkpoint
    local session=$(jq '.session' "$latest")

    # Restore session.json
    echo "$session" > "$PROJECT_ROOT/.aida/state/session.json"

    # Show status
    local phase=$(echo "$session" | jq -r '.current_phase')
    local phase_num=$(echo "$session" | jq -r '.phase')

    log_success "Session restored"
    echo ""
    echo "Current state:"
    echo "  Phase: $phase (Phase $phase_num)"
    echo "  Leaders:"
    echo "    Spec: $(echo "$session" | jq -r '.leaders.spec')"
    echo "    Impl: $(echo "$session" | jq -r '.leaders.impl')"
    echo ""
    echo "To continue: Use /aida:work command"
}

# Show checkpoint status
show_status() {
    local project=$1

    log_section "Checkpoint Status - $project"

    # Find all checkpoints for project
    local checkpoints=$(ls -t "$CHECKPOINT_DIR/${project}_"*.json 2>/dev/null)

    if [[ -z "$checkpoints" ]]; then
        log_warning "No checkpoints found for project: $project"
        exit 0
    fi

    echo "Available checkpoints:"
    echo ""

    for cp in $checkpoints; do
        local name=$(basename "$cp")
        local created=$(jq -r '.created_at' "$cp")
        local phase=$(jq -r '.session.current_phase' "$cp")
        echo "  $name"
        echo "    Created: $created"
        echo "    Phase: $phase"
        echo ""
    done
}

# List all checkpoints
list_checkpoints() {
    log_section "All Checkpoints"

    local checkpoints=$(ls -t "$CHECKPOINT_DIR"/*.json 2>/dev/null)

    if [[ -z "$checkpoints" ]]; then
        log_warning "No checkpoints found"
        exit 0
    fi

    echo ""
    printf "%-40s %-25s %-15s\n" "Checkpoint" "Created" "Phase"
    echo "--------------------------------------------------------------------------------"

    for cp in $checkpoints; do
        local name=$(basename "$cp" .json)
        local created=$(jq -r '.created_at' "$cp" | cut -d'T' -f1,2 | tr 'T' ' ')
        local phase=$(jq -r '.session.current_phase' "$cp")
        printf "%-40s %-25s %-15s\n" "$name" "$created" "$phase"
    done
}

# Main execution
case "$ACTION" in
    save)
        if [[ -z "$PROJECT" ]]; then
            log_error "Project name required"
            show_usage
        fi
        save_checkpoint "$PROJECT"
        ;;
    restore)
        if [[ -z "$PROJECT" ]]; then
            log_error "Project name required"
            show_usage
        fi
        restore_checkpoint "$PROJECT"
        ;;
    status)
        if [[ -z "$PROJECT" ]]; then
            log_error "Project name required"
            show_usage
        fi
        show_status "$PROJECT"
        ;;
    list)
        list_checkpoints
        ;;
    *)
        show_usage
        ;;
esac
