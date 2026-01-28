#!/bin/bash
# AIDA-RED Trigger Hook
# This script monitors AIDA's session.json for completion and triggers AIDA-RED assault
#
# Integration: Add this to AIDA's hooks/stop/ or call manually
# Usage: ./aida-trigger.sh <project-path>

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_PATH="${1:-$(pwd)}"
AIDA_RED_ROOT="${AIDA_RED_ROOT:-$(dirname "$(dirname "$(realpath "$0")")")}"
ASSAULT_SCRIPT="${AIDA_RED_ROOT}/scripts/assault.sh"

# Check for AIDA completion
check_aida_completion() {
    local session_file="$PROJECT_PATH/.aida/state/session.json"

    if [[ ! -f "$session_file" ]]; then
        echo -e "${YELLOW}No AIDA session found at $session_file${NC}"
        return 1
    fi

    local phase
    phase=$(jq -r '.current_phase // "UNKNOWN"' "$session_file" 2>/dev/null)
    local gates_passed
    gates_passed=$(jq -r '.quality_gates_passed // false' "$session_file" 2>/dev/null)

    echo -e "${CYAN}AIDA Status:${NC}"
    echo -e "  Phase: $phase"
    echo -e "  Quality Gates: $gates_passed"

    if [[ "$phase" == "COMPLETED" && "$gates_passed" == "true" ]]; then
        echo -e "${GREEN}AIDA build complete - triggering AIDA-RED!${NC}"
        return 0
    else
        echo -e "${YELLOW}AIDA not yet complete (phase: $phase, gates: $gates_passed)${NC}"
        return 1
    fi
}

# Write findings back to AIDA's evidence directory
inject_findings() {
    local findings_dir="$AIDA_RED_ROOT/reports"
    local target_dir="$PROJECT_PATH/.aida/tdd-evidence/external-bugs"

    # Create target directory
    mkdir -p "$target_dir"

    # Copy all reproduction scripts
    local count=0
    for villain_dir in "$findings_dir"/*/; do
        if [[ -d "$villain_dir" ]]; then
            for spec in "$villain_dir"*.spec.ts; do
                if [[ -f "$spec" ]]; then
                    cp "$spec" "$target_dir/"
                    ((count++)) || true
                fi
            done
        fi
    done

    if [[ $count -gt 0 ]]; then
        echo -e "${RED}Injected $count vulnerability tests into AIDA evidence${NC}"
        echo -e "${RED}AIDA's quality gates will now FAIL until these are fixed!${NC}"
    else
        echo -e "${GREEN}No vulnerabilities to inject${NC}"
    fi
}

# Watch mode - continuously monitor AIDA
watch_mode() {
    echo -e "${CYAN}Entering watch mode...${NC}"
    echo -e "Monitoring: $PROJECT_PATH/.aida/state/session.json"
    echo -e "Press Ctrl+C to stop"
    echo ""

    local last_phase=""

    while true; do
        local session_file="$PROJECT_PATH/.aida/state/session.json"

        if [[ -f "$session_file" ]]; then
            local phase
            phase=$(jq -r '.current_phase // "UNKNOWN"' "$session_file" 2>/dev/null)

            if [[ "$phase" != "$last_phase" ]]; then
                echo -e "[$(date '+%H:%M:%S')] Phase changed: $last_phase -> $phase"
                last_phase="$phase"

                # Trigger on completion
                if [[ "$phase" == "COMPLETED" ]]; then
                    local gates_passed
                    gates_passed=$(jq -r '.quality_gates_passed // false' "$session_file" 2>/dev/null)

                    if [[ "$gates_passed" == "true" ]]; then
                        echo -e "${RED}[!] AIDA COMPLETE - TRIGGERING ASSAULT!${NC}"
                        trigger_assault
                    fi
                fi
            fi
        fi

        sleep 5
    done
}

# Trigger the assault
trigger_assault() {
    if [[ -x "$ASSAULT_SCRIPT" ]]; then
        echo -e "${RED}Launching AIDA-RED assault...${NC}"
        "$ASSAULT_SCRIPT" --target "$PROJECT_PATH" --intensity maximum
        inject_findings
    else
        echo -e "${YELLOW}Assault script not found or not executable: $ASSAULT_SCRIPT${NC}"
        echo -e "${YELLOW}Run: chmod +x $ASSAULT_SCRIPT${NC}"
    fi
}

# Main
main() {
    local mode="${2:-check}"

    case "$mode" in
        check)
            # One-time check
            if check_aida_completion; then
                trigger_assault
            fi
            ;;
        watch)
            # Continuous monitoring
            watch_mode
            ;;
        trigger)
            # Force trigger regardless of state
            echo -e "${RED}Force triggering assault...${NC}"
            trigger_assault
            ;;
        inject)
            # Just inject findings
            inject_findings
            ;;
        *)
            echo "Usage: $0 <project-path> [check|watch|trigger|inject]"
            echo ""
            echo "Modes:"
            echo "  check   - Check AIDA status and trigger if complete (default)"
            echo "  watch   - Continuously monitor AIDA and trigger on completion"
            echo "  trigger - Force trigger assault regardless of AIDA state"
            echo "  inject  - Just inject existing findings into AIDA evidence"
            exit 1
            ;;
    esac
}

main "$@"
