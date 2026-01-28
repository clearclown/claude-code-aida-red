#!/bin/bash
# AIDA-RED Assault Script - Main Entry Point
# Usage: ./assault.sh --target <path> [--intensity <level>] [--focus <area>] [--villain <name>]
#
# This script is the main entry point for AIDA-RED attacks.
# It initializes the attack environment, gathers intelligence from AIDA specs,
# and coordinates the deployment of Villain agents.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
TARGET=""
INTENSITY="standard"
FOCUS=""
VILLAIN=""
CAMPAIGN_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
START_TIME=$(date -Iseconds)

# AIDA-RED directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDA_RED_ROOT="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="${AIDA_RED_ROOT}/reports"
OPERATIONS_DIR="${AIDA_RED_ROOT}/operations"

# Banner
print_banner() {
    echo -e "${RED}"
    echo '    _    ___ ____    _        ____  _____ ____  '
    echo '   / \  |_ _|  _ \  / \      |  _ \| ____|  _ \ '
    echo '  / _ \  | || | | |/ _ \ ____| |_) |  _| | | | |'
    echo ' / ___ \ | || |_| / ___ \____|  _ <| |___| |_| |'
    echo '/_/   \_\___|____/_/   \_\   |_| \_\_____|____/ '
    echo -e "${NC}"
    echo -e "${PURPLE}The Nemesis of AIDA - Automated Destruction Framework${NC}"
    echo ""
}

# Help message
print_help() {
    print_banner
    echo "Usage: $0 --target <path> [options]"
    echo ""
    echo "Options:"
    echo "  --target <path>     Path to the AIDA project to attack (required)"
    echo "  --intensity <level> Attack intensity: minimum, standard, maximum (default: standard)"
    echo "  --focus <area>      Focus area: backend, frontend, api, auth, docker"
    echo "  --villain <name>    Run specific villain: joker, shadow, chaos"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --target ../my-project"
    echo "  $0 --target ../my-project --intensity maximum"
    echo "  $0 --target ../my-project --villain shadow --focus auth"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET="$2"
                shift 2
                ;;
            --intensity)
                INTENSITY="$2"
                shift 2
                ;;
            --focus)
                FOCUS="$2"
                shift 2
                ;;
            --villain)
                VILLAIN="$2"
                shift 2
                ;;
            --help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done

    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}Error: --target is required${NC}"
        print_help
        exit 1
    fi

    # Resolve target path
    TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

    if [[ ! -d "$TARGET" ]]; then
        echo -e "${RED}Error: Target directory does not exist: $TARGET${NC}"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    echo -e "${CYAN}[*] Checking prerequisites...${NC}"

    # Check for AIDA structure
    if [[ ! -d "$TARGET/.aida" ]]; then
        echo -e "${YELLOW}Warning: No .aida directory found. This may not be an AIDA project.${NC}"
    fi

    # Check for specs
    if [[ ! -d "$TARGET/.aida/specs" ]]; then
        echo -e "${YELLOW}Warning: No specs found at $TARGET/.aida/specs${NC}"
    fi

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Warning: Docker not found. Some attacks may not work.${NC}"
    fi

    # Check for required tools
    local tools=("curl" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${YELLOW}Warning: $tool not found${NC}"
        fi
    done

    echo -e "${GREEN}[+] Prerequisites check complete${NC}"
}

# Initialize campaign
init_campaign() {
    echo -e "${CYAN}[*] Initializing attack campaign...${NC}"

    # Create campaign directory
    mkdir -p "${OPERATIONS_DIR}"
    mkdir -p "${REPORTS_DIR}/joker"
    mkdir -p "${REPORTS_DIR}/shadow"
    mkdir -p "${REPORTS_DIR}/chaos"

    # Initialize targets.json
    cat > "${OPERATIONS_DIR}/targets.json" << EOF
{
  "campaign_id": "${CAMPAIGN_ID}",
  "started_at": "${START_TIME}",
  "target": "${TARGET}",
  "intensity": "${INTENSITY}",
  "focus": "${FOCUS}",
  "villain": "${VILLAIN}",
  "status": "ACTIVE",
  "phase": "RECONNAISSANCE",
  "findings": []
}
EOF

    echo -e "${GREEN}[+] Campaign initialized: ${CAMPAIGN_ID}${NC}"
}

# Gather intelligence from AIDA specs
gather_intelligence() {
    echo -e "${CYAN}[*] Gathering intelligence from AIDA specs...${NC}"

    local specs_dir="$TARGET/.aida/specs"
    local intelligence_file="${OPERATIONS_DIR}/intelligence.json"

    # Initialize intelligence
    cat > "$intelligence_file" << EOF
{
  "campaign_id": "${CAMPAIGN_ID}",
  "target": "${TARGET}",
  "gathered_at": "$(date -Iseconds)",
  "specs_found": [],
  "endpoints": [],
  "auth_mechanisms": [],
  "tech_stack": [],
  "attack_vectors": []
}
EOF

    if [[ -d "$specs_dir" ]]; then
        # Find all spec files
        local specs
        specs=$(find "$specs_dir" -name "*.md" -type f 2>/dev/null || true)

        for spec in $specs; do
            echo -e "  ${PURPLE}Reading: $(basename "$spec")${NC}"

            # Extract endpoints (simple grep for API patterns)
            local endpoints
            endpoints=$(grep -oE '(GET|POST|PUT|DELETE|PATCH)\s+/[a-zA-Z0-9/_-]+' "$spec" 2>/dev/null || true)

            # Add to intelligence
            if [[ -n "$endpoints" ]]; then
                echo "  Found endpoints in $spec"
            fi
        done

        echo -e "${GREEN}[+] Intelligence gathered${NC}"
    else
        echo -e "${YELLOW}Warning: No specs directory found${NC}"
    fi
}

# Check if target is ready for attack
check_target_ready() {
    echo -e "${CYAN}[*] Checking if target is ready for attack...${NC}"

    local session_file="$TARGET/.aida/state/session.json"

    if [[ -f "$session_file" ]]; then
        local phase
        phase=$(jq -r '.current_phase // "UNKNOWN"' "$session_file" 2>/dev/null || echo "UNKNOWN")
        local gates_passed
        gates_passed=$(jq -r '.quality_gates_passed // false' "$session_file" 2>/dev/null || echo "false")

        echo -e "  AIDA Phase: ${CYAN}$phase${NC}"
        echo -e "  Quality Gates: ${CYAN}$gates_passed${NC}"

        if [[ "$phase" == "COMPLETED" && "$gates_passed" == "true" ]]; then
            echo -e "${GREEN}[+] Target is ready for attack!${NC}"
            return 0
        else
            echo -e "${YELLOW}Warning: Target may not be fully built. Proceeding anyway...${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}Warning: No session.json found. Target may not be an AIDA project.${NC}"
        return 0
    fi
}

# Deploy villain agent
deploy_villain() {
    local villain_name=$1
    echo -e "${RED}[!] Deploying ${villain_name^^}...${NC}"

    # Update campaign status
    jq --arg v "$villain_name" '.villains_deployed += [$v]' \
        "${OPERATIONS_DIR}/targets.json" > "${OPERATIONS_DIR}/targets.json.tmp" \
        && mv "${OPERATIONS_DIR}/targets.json.tmp" "${OPERATIONS_DIR}/targets.json"

    # Generate villain deployment prompt
    local agent_file="${AIDA_RED_ROOT}/agents/${villain_name}.md"

    if [[ ! -f "$agent_file" ]]; then
        echo -e "${RED}Error: Agent file not found: $agent_file${NC}"
        return 1
    fi

    echo -e "${PURPLE}  Agent: ${agent_file}${NC}"
    echo -e "${PURPLE}  Target: ${TARGET}${NC}"
    echo -e "${PURPLE}  Focus: ${FOCUS:-all}${NC}"
    echo -e "${PURPLE}  Intensity: ${INTENSITY}${NC}"

    # Output deployment info for Claude Code to pick up
    cat << EOF

=== VILLAIN DEPLOYMENT: ${villain_name^^} ===

To deploy this villain, use the Task tool with:
- subagent_type: "general-purpose"
- model: "haiku"
- prompt: See ${agent_file}

Target: ${TARGET}
Focus: ${FOCUS:-all}
Specs: ${TARGET}/.aida/specs/
Output: ${REPORTS_DIR}/${villain_name}/

EOF

    echo -e "${GREEN}[+] ${villain_name^^} deployment prepared${NC}"
}

# Main assault sequence
run_assault() {
    echo -e "${RED}[!] BEGINNING ASSAULT SEQUENCE${NC}"
    echo ""

    # Update campaign phase
    jq '.phase = "ASSAULT"' "${OPERATIONS_DIR}/targets.json" > "${OPERATIONS_DIR}/targets.json.tmp" \
        && mv "${OPERATIONS_DIR}/targets.json.tmp" "${OPERATIONS_DIR}/targets.json"

    if [[ -n "$VILLAIN" ]]; then
        # Single villain mode
        deploy_villain "$VILLAIN"
    else
        # Full assault - deploy all villains
        case $INTENSITY in
            minimum)
                echo -e "${YELLOW}Minimum intensity: Deploying Joker only${NC}"
                deploy_villain "joker"
                ;;
            standard)
                echo -e "${YELLOW}Standard intensity: Deploying Joker and Shadow${NC}"
                deploy_villain "joker"
                deploy_villain "shadow"
                ;;
            maximum)
                echo -e "${RED}MAXIMUM intensity: Deploying ALL villains${NC}"
                deploy_villain "joker"
                deploy_villain "shadow"
                deploy_villain "chaos"
                ;;
        esac
    fi
}

# Generate final report
generate_report() {
    echo -e "${CYAN}[*] Generating attack report...${NC}"

    local report_file="${REPORTS_DIR}/campaign-${CAMPAIGN_ID}.json"
    local end_time
    end_time=$(date -Iseconds)

    # Count findings
    local joker_count shadow_count chaos_count
    joker_count=$(find "${REPORTS_DIR}/joker" -name "*.spec.ts" 2>/dev/null | wc -l || echo 0)
    shadow_count=$(find "${REPORTS_DIR}/shadow" -name "*.spec.ts" 2>/dev/null | wc -l || echo 0)
    chaos_count=$(find "${REPORTS_DIR}/chaos" -name "*.spec.ts" 2>/dev/null | wc -l || echo 0)

    cat > "$report_file" << EOF
{
  "campaign_id": "${CAMPAIGN_ID}",
  "target": "${TARGET}",
  "started_at": "${START_TIME}",
  "ended_at": "${end_time}",
  "intensity": "${INTENSITY}",
  "focus": "${FOCUS}",
  "summary": {
    "joker_findings": ${joker_count},
    "shadow_findings": ${shadow_count},
    "chaos_findings": ${chaos_count},
    "total": $((joker_count + shadow_count + chaos_count))
  },
  "status": "COMPLETED"
}
EOF

    echo -e "${GREEN}[+] Report generated: ${report_file}${NC}"
}

# Main execution
main() {
    print_banner
    parse_args "$@"
    check_prerequisites
    init_campaign
    gather_intelligence
    check_target_ready
    run_assault
    generate_report

    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  AIDA-RED ASSAULT SEQUENCE COMPLETE${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "Campaign ID: ${CYAN}${CAMPAIGN_ID}${NC}"
    echo -e "Target: ${CYAN}${TARGET}${NC}"
    echo -e "Reports: ${CYAN}${REPORTS_DIR}${NC}"
    echo ""
    echo -e "${YELLOW}To check status: /red:status${NC}"
    echo -e "${YELLOW}To view report: /red:report${NC}"
}

main "$@"
