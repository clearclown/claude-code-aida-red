#!/bin/bash
# AIDA Baseline Capture
# Captures test results and coverage before enhancement
# Language-agnostic: auto-detects and runs appropriate commands
#
# Usage: ./scripts/capture-baseline.sh <project-path> [analysis-json]
#
# Output: .aida/state/enhance-baseline.json

set -euo pipefail

# Load common functions (colors are defined in common.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Note: Colors (RED, GREEN, YELLOW, BLUE, NC) are defined in common.sh

PROJECT_PATH="${1:-.}"
ANALYSIS_FILE="${2:-}"
OUTPUT_FILE=".aida/state/enhance-baseline.json"

echo -e "${BLUE}AIDA Baseline Capture${NC}"
echo "========================"
echo ""

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

cd "$PROJECT_PATH"

# Create output directory using ensure_dir from common.sh
ensure_dir ".aida/state"

# Auto-detect or load analysis
detect_language() {
    if [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        if [[ -f "tsconfig.json" ]]; then
            echo "typescript"
        else
            echo "javascript"
        fi
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
    elif [[ -f "Gemfile" ]]; then
        echo "ruby"
    elif [[ -f "composer.json" ]]; then
        echo "php"
    elif ls *.csproj 1>/dev/null 2>&1 || ls *.sln 1>/dev/null 2>&1; then
        echo "csharp"
    else
        echo "unknown"
    fi
}

detect_test_framework() {
    local lang="$1"
    case "$lang" in
        go)
            echo "go-test"
            ;;
        rust)
            echo "cargo-test"
            ;;
        python)
            if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
                echo "pytest"
            elif [[ -f "setup.cfg" ]] && grep -q "pytest" setup.cfg 2>/dev/null; then
                echo "pytest"
            else
                echo "unittest"
            fi
            ;;
        typescript|javascript)
            if [[ -f "vitest.config.ts" ]] || [[ -f "vitest.config.js" ]]; then
                echo "vitest"
            elif [[ -f "jest.config.js" ]] || [[ -f "jest.config.ts" ]] || grep -q '"jest"' package.json 2>/dev/null; then
                echo "jest"
            elif grep -q "mocha" package.json 2>/dev/null; then
                echo "mocha"
            else
                echo "vitest"
            fi
            ;;
        java)
            if [[ -f "pom.xml" ]]; then
                echo "maven"
            else
                echo "gradle"
            fi
            ;;
        ruby)
            echo "rspec"
            ;;
        php)
            echo "phpunit"
            ;;
        csharp)
            echo "dotnet-test"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Capture Go baseline
capture_go_baseline() {
    local component_path="${1:-.}"
    local result="{}"

    echo -e "${BLUE}Capturing Go baseline...${NC}"

    cd "$component_path" 2>/dev/null || cd .

    # Run tests and capture output
    local test_output
    local test_exit=0
    test_output=$(go test -v -json ./... 2>&1) || test_exit=$?

    # Parse test results
    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Count tests from JSON output
    total_tests=$(echo "$test_output" | grep -c '"Action":"pass"\|"Action":"fail"' 2>/dev/null || echo "0")
    passed_tests=$(echo "$test_output" | grep -c '"Action":"pass"' 2>/dev/null || echo "0")
    failed_tests=$(echo "$test_output" | grep -c '"Action":"fail"' 2>/dev/null || echo "0")

    # Get coverage
    local coverage="0%"
    local coverage_output
    coverage_output=$(go test -coverprofile=.aida/coverage.out ./... 2>&1) || true
    if [[ -f ".aida/coverage.out" ]]; then
        coverage=$(go tool cover -func=.aida/coverage.out 2>/dev/null | grep total | awk '{print $3}' || echo "0%")
    fi

    # Build check
    local build_status="pass"
    go build ./... 2>/dev/null || build_status="fail"

    cat <<EOF
{
  "name": "$(basename "$component_path")",
  "path": "$component_path",
  "lang": "go",
  "test_framework": "go-test",
  "test_result": {
    "status": "$([ $test_exit -eq 0 ] && echo 'pass' || echo 'fail')",
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests
  },
  "coverage": {
    "line": "$coverage"
  },
  "build_result": {
    "status": "$build_status"
  }
}
EOF
}

# Capture TypeScript/JavaScript baseline
capture_ts_baseline() {
    local component_path="${1:-.}"
    local framework="${2:-vitest}"

    echo -e "${BLUE}Capturing TypeScript/JavaScript baseline...${NC}"

    cd "$component_path" 2>/dev/null || cd .

    # Detect package manager
    local pm="npm"
    [[ -f "pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "yarn.lock" ]] && pm="yarn"

    # Install deps if needed
    [[ ! -d "node_modules" ]] && $pm install 2>/dev/null || true

    local test_output
    local test_exit=0
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local coverage="0%"

    case "$framework" in
        vitest)
            test_output=$($pm run test -- --run --reporter=json 2>&1) || test_exit=$?
            # Parse vitest JSON
            total_tests=$(echo "$test_output" | grep -o '"numTotalTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
            passed_tests=$(echo "$test_output" | grep -o '"numPassedTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
            failed_tests=$(echo "$test_output" | grep -o '"numFailedTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")

            # Get coverage
            $pm run test -- --run --coverage 2>/dev/null || true
            if [[ -f "coverage/coverage-summary.json" ]]; then
                coverage=$(cat coverage/coverage-summary.json | grep -o '"pct":[0-9.]*' | head -1 | grep -o '[0-9.]*' || echo "0")
                coverage="${coverage}%"
            fi
            ;;
        jest)
            test_output=$($pm test -- --json 2>&1) || test_exit=$?
            total_tests=$(echo "$test_output" | grep -o '"numTotalTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
            passed_tests=$(echo "$test_output" | grep -o '"numPassedTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
            failed_tests=$(echo "$test_output" | grep -o '"numFailedTests":[0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
            ;;
    esac

    # Build check
    local build_status="pass"
    $pm run build 2>/dev/null || build_status="fail"

    cat <<EOF
{
  "name": "$(basename "$component_path")",
  "path": "$component_path",
  "lang": "typescript",
  "test_framework": "$framework",
  "test_result": {
    "status": "$([ $test_exit -eq 0 ] && echo 'pass' || echo 'fail')",
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests
  },
  "coverage": {
    "line": "$coverage"
  },
  "build_result": {
    "status": "$build_status"
  }
}
EOF
}

# Capture Python baseline
capture_python_baseline() {
    local component_path="${1:-.}"
    local framework="${2:-pytest}"

    echo -e "${BLUE}Capturing Python baseline...${NC}"

    cd "$component_path" 2>/dev/null || cd .

    local test_output
    local test_exit=0
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local coverage="0%"

    case "$framework" in
        pytest)
            test_output=$(python -m pytest --tb=no -q 2>&1) || test_exit=$?
            # Parse pytest output: "5 passed, 2 failed"
            passed_tests=$(echo "$test_output" | grep -oP '\d+(?= passed)' | head -1 || echo "0")
            failed_tests=$(echo "$test_output" | grep -oP '\d+(?= failed)' | head -1 || echo "0")
            total_tests=$((passed_tests + failed_tests))

            # Get coverage
            python -m pytest --cov --cov-report=term 2>/dev/null | grep "TOTAL" | awk '{print $NF}' > .aida/coverage.txt || true
            [[ -f ".aida/coverage.txt" ]] && coverage=$(cat .aida/coverage.txt)
            ;;
        unittest)
            test_output=$(python -m unittest discover 2>&1) || test_exit=$?
            total_tests=$(echo "$test_output" | grep -oP 'Ran \K\d+' || echo "0")
            if echo "$test_output" | grep -q "OK"; then
                passed_tests=$total_tests
                failed_tests=0
            else
                failed_tests=$(echo "$test_output" | grep -oP 'failures=\K\d+' || echo "0")
                passed_tests=$((total_tests - failed_tests))
            fi
            ;;
    esac

    cat <<EOF
{
  "name": "$(basename "$component_path")",
  "path": "$component_path",
  "lang": "python",
  "test_framework": "$framework",
  "test_result": {
    "status": "$([ $test_exit -eq 0 ] && echo 'pass' || echo 'fail')",
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests
  },
  "coverage": {
    "line": "$coverage"
  },
  "build_result": {
    "status": "pass"
  }
}
EOF
}

# Capture Rust baseline
capture_rust_baseline() {
    local component_path="${1:-.}"

    echo -e "${BLUE}Capturing Rust baseline...${NC}"

    cd "$component_path" 2>/dev/null || cd .

    local test_output
    local test_exit=0
    test_output=$(cargo test 2>&1) || test_exit=$?

    # Parse: "test result: ok. 10 passed; 0 failed"
    local passed_tests=$(echo "$test_output" | grep -oP '\d+(?= passed)' | tail -1 || echo "0")
    local failed_tests=$(echo "$test_output" | grep -oP '\d+(?= failed)' | tail -1 || echo "0")
    local total_tests=$((passed_tests + failed_tests))

    # Build check
    local build_status="pass"
    cargo build 2>/dev/null || build_status="fail"

    cat <<EOF
{
  "name": "$(basename "$component_path")",
  "path": "$component_path",
  "lang": "rust",
  "test_framework": "cargo-test",
  "test_result": {
    "status": "$([ $test_exit -eq 0 ] && echo 'pass' || echo 'fail')",
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests
  },
  "coverage": {
    "line": "N/A"
  },
  "build_result": {
    "status": "$build_status"
  }
}
EOF
}

# Main capture function
capture_component() {
    local path="$1"
    local lang=$(detect_language)
    local framework=$(detect_test_framework "$lang")

    echo -e "${YELLOW}Detected: $lang ($framework)${NC}"

    case "$lang" in
        go)
            capture_go_baseline "$path"
            ;;
        typescript|javascript)
            capture_ts_baseline "$path" "$framework"
            ;;
        python)
            capture_python_baseline "$path" "$framework"
            ;;
        rust)
            capture_rust_baseline "$path"
            ;;
        *)
            echo -e "${YELLOW}Warning: Unknown language, using file-based counting${NC}"
            cat <<EOF
{
  "name": "$(basename "$path")",
  "path": "$path",
  "lang": "$lang",
  "test_framework": "unknown",
  "test_result": {
    "status": "unknown",
    "total": 0,
    "passed": 0,
    "failed": 0
  },
  "coverage": {
    "line": "N/A"
  },
  "build_result": {
    "status": "unknown"
  }
}
EOF
            ;;
    esac
}

# Detect project structure
detect_components() {
    local components=()

    # Check for common structures
    if [[ -d "backend" ]] && [[ -d "frontend" ]]; then
        # Fullstack project
        components+=("backend" "frontend")
    elif [[ -d "packages" ]] || [[ -d "apps" ]]; then
        # Monorepo
        for dir in packages/* apps/* libs/*; do
            [[ -d "$dir" ]] && components+=("$dir")
        done
    elif [[ -d "src" ]]; then
        # Single component
        components+=(".")
    else
        components+=(".")
    fi

    echo "${components[@]}"
}

# Main execution
main() {
    local captured_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local git_commit=""
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    echo -e "${BLUE}Project: $PROJECT_PATH${NC}"
    echo -e "${BLUE}Commit: $git_commit${NC}"
    echo ""

    # Detect components
    local components_str=$(detect_components)
    local -a components=($components_str)

    echo -e "${YELLOW}Detected ${#components[@]} component(s): ${components[*]}${NC}"
    echo ""

    # Capture each component
    local components_json="["
    local first=true
    local total_tests=0
    local total_passed=0
    local baseline_valid=true

    for comp in "${components[@]}"; do
        echo -e "${BLUE}--- Capturing: $comp ---${NC}"

        local comp_json
        comp_json=$(cd "$comp" 2>/dev/null && capture_component "$comp" || capture_component ".")

        # Extract test counts for summary
        local comp_total=$(echo "$comp_json" | grep -o '"total": [0-9]*' | grep -o '[0-9]*' || echo "0")
        local comp_passed=$(echo "$comp_json" | grep -o '"passed": [0-9]*' | grep -o '[0-9]*' || echo "0")
        local comp_status=$(echo "$comp_json" | grep -o '"status": "[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')

        total_tests=$((total_tests + comp_total))
        total_passed=$((total_passed + comp_passed))
        [[ "$comp_status" == "fail" ]] && baseline_valid=false

        if [[ "$first" == "true" ]]; then
            first=false
        else
            components_json+=","
        fi
        components_json+="$comp_json"

        echo ""
    done

    components_json+="]"

    # Generate final JSON
    cat > "$OUTPUT_FILE" <<EOF
{
  "captured_at": "$captured_at",
  "project_path": "$(pwd)",
  "project_name": "$(basename "$(pwd)")",
  "git_commit": "$git_commit",
  "components": $components_json,
  "summary": {
    "total_tests": $total_tests,
    "total_passed": $total_passed,
    "baseline_valid": $baseline_valid
  }
}
EOF

    echo -e "${GREEN}========================${NC}"
    echo -e "${GREEN}Baseline Captured${NC}"
    echo -e "${GREEN}========================${NC}"
    echo ""
    echo -e "Output: ${BLUE}$OUTPUT_FILE${NC}"
    echo -e "Total Tests: ${YELLOW}$total_tests${NC}"
    echo -e "Passed: ${GREEN}$total_passed${NC}"
    echo -e "Baseline Valid: $([ "$baseline_valid" == "true" ] && echo -e "${GREEN}Yes${NC}" || echo -e "${RED}No${NC}")"

    if [[ "$baseline_valid" == "false" ]]; then
        echo ""
        echo -e "${YELLOW}WARNING: Some tests are failing in baseline.${NC}"
        echo -e "${YELLOW}Enhancement will preserve this state (no regression).${NC}"
    fi
}

main
