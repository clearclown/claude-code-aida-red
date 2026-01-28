#!/bin/bash
# AIDA Failure Analyzer
# Purpose: Analyze quality gate failures and provide actionable insights
# Usage: ./analyze-failure.sh <project-name> [gate-number]
#
# This script analyzes failed quality gates and provides
# detailed diagnostics and fix suggestions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Note: CYAN color is already defined in common.sh

# ============================================
# Usage
# ============================================
usage() {
    cat << EOF
Usage: $(basename "$0") <project-name> [options]

Analyze quality gate failures and provide fix suggestions.

Options:
    --gate=N        Analyze specific gate number
    --all           Analyze all gates
    --verbose       Show detailed output
    --json          Output as JSON
    --help          Show this help message

Gates:
    1-2:   Backend (build, tests)
    3-4:   Frontend (build, tests)
    5-7:   Docker (build, run, health)
    8-19:  Coverage and quality gates
    20:    TDD evidence

Examples:
    $(basename "$0") my-project
    $(basename "$0") my-project --gate=14
    $(basename "$0") my-project --all --json
EOF
}

# ============================================
# Parse arguments
# ============================================
PROJECT=""
GATE=""
ALL=false
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gate=*)
            GATE="${1#*=}"
            shift
            ;;
        --all)
            ALL=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
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

PROJECT_DIR="$PROJECT_ROOT/$PROJECT"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}Error: Project directory not found: $PROJECT_DIR${NC}" >&2
    exit 1
fi

# ============================================
# Analysis functions
# ============================================
analyze_backend_build() {
    local result=0
    local issues=()

    echo -e "${BLUE}Analyzing Backend Build (Gate 1)...${NC}"

    if [[ -d "$PROJECT_DIR/backend" ]]; then
        cd "$PROJECT_DIR/backend"

        # Check go.mod
        if [[ ! -f "go.mod" ]]; then
            issues+=("Missing go.mod file")
            result=1
        fi

        # Try to build
        if ! go build ./... 2>/tmp/go-build-errors.txt; then
            result=1
            while IFS= read -r line; do
                issues+=("$line")
            done < /tmp/go-build-errors.txt
        fi

        cd - >/dev/null
    else
        issues+=("Backend directory not found")
        result=1
    fi

    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}✓ Backend build OK${NC}"
    else
        echo -e "${RED}✗ Backend build failed${NC}"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
    fi

    return $result
}

analyze_backend_tests() {
    local result=0
    local test_count=0
    local min_tests=80

    echo -e "${BLUE}Analyzing Backend Tests (Gate 2, 11)...${NC}"

    if [[ -d "$PROJECT_DIR/backend" ]]; then
        test_count=$(grep -r "func Test" "$PROJECT_DIR/backend" --include="*_test.go" 2>/dev/null | wc -l)

        echo "  Test functions: $test_count / $min_tests required"

        if [[ $test_count -lt $min_tests ]]; then
            result=1
            echo -e "${RED}✗ Insufficient tests${NC}"
            echo "  Add $((min_tests - test_count)) more test functions"

            # Suggest files needing tests
            echo ""
            echo "  Files without tests:"
            find "$PROJECT_DIR/backend" -name "*.go" ! -name "*_test.go" -exec basename {} \; | \
                while read -r file; do
                    local test_file="${file%.go}_test.go"
                    if ! find "$PROJECT_DIR/backend" -name "$test_file" | grep -q .; then
                        echo "    - $file"
                    fi
                done | head -10
        else
            echo -e "${GREEN}✓ Backend tests OK${NC}"
        fi
    fi

    return $result
}

analyze_frontend_tests() {
    local result=0
    local test_count=0
    local min_tests=100

    echo -e "${BLUE}Analyzing Frontend Tests (Gate 4, 12)...${NC}"

    if [[ -d "$PROJECT_DIR/frontend/src" ]]; then
        test_count=$(grep -rE "^\s*(it|test)\s*\(" "$PROJECT_DIR/frontend/src" \
            --include="*.test.tsx" --include="*.test.ts" 2>/dev/null | wc -l)

        echo "  Test cases: $test_count / $min_tests required"

        if [[ $test_count -lt $min_tests ]]; then
            result=1
            echo -e "${RED}✗ Insufficient tests${NC}"
            echo "  Add $((min_tests - test_count)) more test cases"

            # Suggest components needing tests
            echo ""
            echo "  Components without tests:"
            find "$PROJECT_DIR/frontend/src" -name "*.tsx" ! -name "*.test.tsx" -exec basename {} \; | \
                while read -r file; do
                    local test_file="${file%.tsx}.test.tsx"
                    if ! find "$PROJECT_DIR/frontend/src" -name "$test_file" | grep -q .; then
                        echo "    - $file"
                    fi
                done | head -10
        else
            echo -e "${GREEN}✓ Frontend tests OK${NC}"
        fi
    fi

    return $result
}

analyze_coverage() {
    echo -e "${BLUE}Analyzing Coverage (Gates 14, 17)...${NC}"

    # Backend coverage
    if [[ -d "$PROJECT_DIR/backend" ]]; then
        echo "  Backend:"
        cd "$PROJECT_DIR/backend"
        if go test -cover ./... 2>/dev/null | grep -oP 'coverage: \d+\.\d+%' | head -5; then
            :
        else
            echo "    Could not determine coverage"
        fi
        cd - >/dev/null
    fi

    # Frontend coverage
    if [[ -d "$PROJECT_DIR/frontend" && -f "$PROJECT_DIR/frontend/package.json" ]]; then
        echo "  Frontend:"
        if [[ -f "$PROJECT_DIR/frontend/coverage/coverage-summary.json" ]]; then
            jq '.total.lines.pct' "$PROJECT_DIR/frontend/coverage/coverage-summary.json" 2>/dev/null || \
                echo "    Run: npm test -- --coverage"
        else
            echo "    No coverage report found"
            echo "    Run: npm test -- --coverage"
        fi
    fi
}

analyze_tdd_evidence() {
    local result=0
    local min_evidence=10

    echo -e "${BLUE}Analyzing TDD Evidence (Gate 20)...${NC}"

    local tdd_dir="$PROJECT_ROOT/.aida/tdd-evidence"

    if [[ -d "$tdd_dir" ]]; then
        local count
        count=$(find "$tdd_dir" -name "*.json" -type f 2>/dev/null | wc -l)

        echo "  Evidence files: $count / $min_evidence required"

        if [[ $count -lt $min_evidence ]]; then
            result=1
            echo -e "${RED}✗ Insufficient TDD evidence${NC}"
            echo ""
            echo "  Record TDD cycles with:"
            echo "    ./scripts/tdd-logger.sh start <feature-name>"
            echo "    # Write failing test"
            echo "    ./scripts/tdd-logger.sh red"
            echo "    # Implement feature"
            echo "    ./scripts/tdd-logger.sh green"
            echo "    # Refactor"
            echo "    ./scripts/tdd-logger.sh refactor"
        else
            echo -e "${GREEN}✓ TDD evidence OK${NC}"
        fi
    else
        result=1
        echo -e "${RED}✗ No TDD evidence directory${NC}"
        echo "  Create: mkdir -p $tdd_dir"
    fi

    return $result
}

# ============================================
# Main analysis
# ============================================
echo -e "${CYAN}=== AIDA Failure Analyzer ===${NC}"
echo "Project: $PROJECT"
echo ""

failures=0

if [[ -n "$GATE" ]]; then
    # Analyze specific gate
    case $GATE in
        1) analyze_backend_build || ((failures++)) ;;
        2|11) analyze_backend_tests || ((failures++)) ;;
        4|12) analyze_frontend_tests || ((failures++)) ;;
        14|17) analyze_coverage ;;
        20) analyze_tdd_evidence || ((failures++)) ;;
        *) echo "Gate $GATE analysis not implemented" ;;
    esac
else
    # Analyze all
    analyze_backend_build || ((failures++))
    echo ""
    analyze_backend_tests || ((failures++))
    echo ""
    analyze_frontend_tests || ((failures++))
    echo ""
    analyze_coverage
    echo ""
    analyze_tdd_evidence || ((failures++))
fi

echo ""
echo "======================================"
if [[ $failures -eq 0 ]]; then
    echo -e "${GREEN}All analyzed gates passed!${NC}"
else
    echo -e "${RED}$failures gate(s) need attention${NC}"
    echo ""
    echo "Run quality gates:"
    echo "  ./scripts/quality-gates.sh $PROJECT"
fi
