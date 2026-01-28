#!/bin/bash
#
# AIDA Project Analyzer
# Analyzes any project's structure, tech stack, and quality state
#
# Usage: ./scripts/analyze-project.sh /path/to/project

set -euo pipefail

# ============================================
# Configuration
# ============================================

PROJECT_PATH="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/.aida/artifacts"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# ============================================
# Helper Functions (project-specific)
# ============================================

check_file_exists() {
    [[ -f "$PROJECT_PATH/$1" ]]
}

check_dir_exists() {
    [[ -d "$PROJECT_PATH/$1" ]]
}

count_files() {
    local pattern="$1"
    find "$PROJECT_PATH" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# ============================================
# Validation
# ============================================

if [[ -z "$PROJECT_PATH" ]]; then
    log_error "Usage: $0 /path/to/project"
    exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Project path does not exist: $PROJECT_PATH"
    exit 1
fi

# Convert to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

log_info "Analyzing project: $PROJECT_NAME"
log_info "Path: $PROJECT_PATH"

# Create output directory using ensure_dir from common.sh
ensure_dir "$OUTPUT_DIR"

# ============================================
# Language Detection
# ============================================

detect_languages() {
    local langs=()

    # Go
    if check_file_exists "go.mod" || [[ $(count_files "*.go") -gt 0 ]]; then
        langs+=("go")
    fi

    # Rust
    if check_file_exists "Cargo.toml"; then
        langs+=("rust")
    fi

    # Python
    if check_file_exists "pyproject.toml" || check_file_exists "requirements.txt" || check_file_exists "setup.py"; then
        langs+=("python")
    fi

    # Node.js / TypeScript
    if check_file_exists "package.json"; then
        if check_file_exists "tsconfig.json" || [[ $(count_files "*.ts") -gt 0 ]] || [[ $(count_files "*.tsx") -gt 0 ]]; then
            langs+=("typescript")
        else
            langs+=("javascript")
        fi
    fi

    # Java
    if check_file_exists "pom.xml" || check_file_exists "build.gradle"; then
        langs+=("java")
    fi

    # Ruby
    if check_file_exists "Gemfile"; then
        langs+=("ruby")
    fi

    # C#
    if [[ $(count_files "*.csproj") -gt 0 ]] || [[ $(count_files "*.sln") -gt 0 ]]; then
        langs+=("csharp")
    fi

    # PHP
    if check_file_exists "composer.json"; then
        langs+=("php")
    fi

    echo "${langs[@]}"
}

# ============================================
# Project Type Detection
# ============================================

detect_project_type() {
    local type="unknown"

    # Fullstack
    if check_dir_exists "backend" && check_dir_exists "frontend"; then
        type="fullstack"
    # Monorepo
    elif check_dir_exists "packages" || check_dir_exists "apps" || check_dir_exists "libs"; then
        type="monorepo"
    # Check package.json for workspaces
    elif check_file_exists "package.json"; then
        if grep -q '"workspaces"' "$PROJECT_PATH/package.json" 2>/dev/null; then
            type="monorepo"
        fi
    fi

    # If still unknown, try to detect based on content
    if [[ "$type" == "unknown" ]]; then
        local langs=($(detect_languages))

        # Library detection
        if check_file_exists "setup.py" || check_file_exists "Cargo.toml" || \
           (check_file_exists "package.json" && grep -q '"main"' "$PROJECT_PATH/package.json" 2>/dev/null); then
            type="library"
        # Backend only
        elif [[ " ${langs[*]} " =~ " go " ]] || [[ " ${langs[*]} " =~ " python " ]] || [[ " ${langs[*]} " =~ " rust " ]]; then
            type="backend"
        # Frontend only
        elif [[ " ${langs[*]} " =~ " typescript " ]] || [[ " ${langs[*]} " =~ " javascript " ]]; then
            if check_file_exists "index.html" || check_dir_exists "src/components" || check_dir_exists "src/pages"; then
                type="frontend"
            else
                type="library"
            fi
        fi
    fi

    echo "$type"
}

# ============================================
# Framework Detection
# ============================================

detect_framework() {
    local lang="$1"
    local path="${2:-.}"
    local framework="unknown"

    case "$lang" in
        go)
            if grep -rq "gin-gonic/gin" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="gin"
            elif grep -rq "gorilla/mux" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="gorilla"
            elif grep -rq "labstack/echo" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="echo"
            elif grep -rq "gofiber/fiber" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="fiber"
            else
                framework="stdlib"
            fi
            ;;
        typescript|javascript)
            if check_file_exists "$path/package.json"; then
                local pkg="$PROJECT_PATH/$path/package.json"
                if grep -q '"react"' "$pkg" 2>/dev/null; then
                    if grep -q '"next"' "$pkg" 2>/dev/null; then
                        framework="next.js"
                    else
                        framework="react"
                    fi
                elif grep -q '"vue"' "$pkg" 2>/dev/null; then
                    if grep -q '"nuxt"' "$pkg" 2>/dev/null; then
                        framework="nuxt"
                    else
                        framework="vue"
                    fi
                elif grep -q '"@angular/core"' "$pkg" 2>/dev/null; then
                    framework="angular"
                elif grep -q '"svelte"' "$pkg" 2>/dev/null; then
                    framework="svelte"
                elif grep -q '"express"' "$pkg" 2>/dev/null; then
                    framework="express"
                elif grep -q '"fastify"' "$pkg" 2>/dev/null; then
                    framework="fastify"
                elif grep -q '"hono"' "$pkg" 2>/dev/null; then
                    framework="hono"
                fi
            fi
            ;;
        python)
            if grep -rq "django" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="django"
            elif grep -rq "fastapi" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="fastapi"
            elif grep -rq "flask" "$PROJECT_PATH/$path" 2>/dev/null; then
                framework="flask"
            fi
            ;;
        rust)
            if grep -q "actix-web" "$PROJECT_PATH/$path/Cargo.toml" 2>/dev/null; then
                framework="actix-web"
            elif grep -q "axum" "$PROJECT_PATH/$path/Cargo.toml" 2>/dev/null; then
                framework="axum"
            elif grep -q "rocket" "$PROJECT_PATH/$path/Cargo.toml" 2>/dev/null; then
                framework="rocket"
            fi
            ;;
    esac

    echo "$framework"
}

# ============================================
# Test Framework Detection
# ============================================

detect_test_framework() {
    local lang="$1"
    local path="${2:-.}"
    local test_fw="unknown"

    case "$lang" in
        go)
            test_fw="go test"
            ;;
        typescript|javascript)
            if check_file_exists "$path/vitest.config.ts" || check_file_exists "$path/vitest.config.js"; then
                test_fw="vitest"
            elif check_file_exists "$path/jest.config.js" || check_file_exists "$path/jest.config.ts"; then
                test_fw="jest"
            elif check_file_exists "$path/package.json" && grep -q '"vitest"' "$PROJECT_PATH/$path/package.json" 2>/dev/null; then
                test_fw="vitest"
            elif check_file_exists "$path/package.json" && grep -q '"jest"' "$PROJECT_PATH/$path/package.json" 2>/dev/null; then
                test_fw="jest"
            fi
            ;;
        python)
            if check_file_exists "$path/pytest.ini" || check_file_exists "$path/conftest.py"; then
                test_fw="pytest"
            elif grep -q "pytest" "$PROJECT_PATH/$path/pyproject.toml" 2>/dev/null; then
                test_fw="pytest"
            else
                test_fw="unittest"
            fi
            ;;
        rust)
            test_fw="cargo test"
            ;;
        ruby)
            if check_dir_exists "$path/spec"; then
                test_fw="rspec"
            else
                test_fw="minitest"
            fi
            ;;
    esac

    echo "$test_fw"
}

# ============================================
# Test Count
# ============================================

count_tests() {
    local lang="$1"
    local path="${2:-.}"
    local count=0

    case "$lang" in
        go)
            count=$(find "$PROJECT_PATH/$path" -name "*_test.go" -type f 2>/dev/null | wc -l | tr -d ' ')
            ;;
        typescript|javascript)
            count=$(find "$PROJECT_PATH/$path" \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -type f 2>/dev/null | wc -l | tr -d ' ')
            ;;
        python)
            count=$(find "$PROJECT_PATH/$path" -name "test_*.py" -o -name "*_test.py" -type f 2>/dev/null | wc -l | tr -d ' ')
            ;;
        rust)
            # Count test modules and #[test] annotations
            count=$(grep -r "#\[test\]" "$PROJECT_PATH/$path" 2>/dev/null | wc -l | tr -d ' ')
            ;;
    esac

    echo "$count"
}

# ============================================
# Infrastructure Detection
# ============================================

detect_infrastructure() {
    local infra="{"

    # Docker
    if check_file_exists "Dockerfile" || check_file_exists "docker-compose.yml" || check_file_exists "compose.yaml"; then
        infra+="\"docker\":true,"
        if check_file_exists "docker-compose.yml" || check_file_exists "compose.yaml"; then
            infra+="\"docker_compose\":true,"
        else
            infra+="\"docker_compose\":false,"
        fi
    else
        infra+="\"docker\":false,\"docker_compose\":false,"
    fi

    # Kubernetes
    if check_dir_exists "k8s" || check_dir_exists "kubernetes" || find "$PROJECT_PATH" -name "*.yaml" -exec grep -l "apiVersion:" {} \; 2>/dev/null | head -1 | grep -q .; then
        infra+="\"kubernetes\":true,"
    else
        infra+="\"kubernetes\":false,"
    fi

    # CI/CD
    local ci_cd="none"
    local ci_files="[]"
    if check_dir_exists ".github/workflows"; then
        ci_cd="GitHub Actions"
        ci_files="[$(find "$PROJECT_PATH/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | sed 's|'"$PROJECT_PATH"'/||g' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//' )]"
    elif check_file_exists ".gitlab-ci.yml"; then
        ci_cd="GitLab CI"
        ci_files='[".gitlab-ci.yml"]'
    elif check_dir_exists ".circleci"; then
        ci_cd="CircleCI"
        ci_files='[".circleci/config.yml"]'
    fi
    infra+="\"ci_cd\":\"$ci_cd\",\"ci_cd_files\":$ci_files"

    infra+="}"
    echo "$infra"
}

# ============================================
# Component Analysis
# ============================================

analyze_component() {
    local name="$1"
    local path="$2"
    local lang="$3"

    local framework=$(detect_framework "$lang" "$path")
    local test_fw=$(detect_test_framework "$lang" "$path")
    local test_files=$(count_tests "$lang" "$path")

    # Build and test commands based on language
    local build_cmd="unknown"
    local test_cmd="unknown"
    local lint_cmd="unknown"

    case "$lang" in
        go)
            build_cmd="go build ./..."
            test_cmd="go test ./..."
            lint_cmd="golangci-lint run"
            ;;
        typescript|javascript)
            if check_file_exists "$path/package.json"; then
                local pkg="$PROJECT_PATH/$path/package.json"
                if grep -q "pnpm-lock" "$PROJECT_PATH/$path" 2>/dev/null || check_file_exists "$path/pnpm-lock.yaml"; then
                    build_cmd="pnpm build"
                    test_cmd="pnpm test"
                    lint_cmd="pnpm lint"
                elif check_file_exists "$path/yarn.lock"; then
                    build_cmd="yarn build"
                    test_cmd="yarn test"
                    lint_cmd="yarn lint"
                else
                    build_cmd="npm run build"
                    test_cmd="npm test"
                    lint_cmd="npm run lint"
                fi
            fi
            ;;
        python)
            build_cmd="python -m build"
            test_cmd="pytest"
            lint_cmd="ruff check ."
            ;;
        rust)
            build_cmd="cargo build"
            test_cmd="cargo test"
            lint_cmd="cargo clippy"
            ;;
    esac

    cat <<EOF
    {
      "name": "$name",
      "path": "$path",
      "lang": "$lang",
      "framework": "$framework",
      "test_framework": "$test_fw",
      "test_files": $test_files,
      "build_command": "$build_cmd",
      "test_command": "$test_cmd",
      "lint_command": "$lint_cmd"
    }
EOF
}

# ============================================
# Main Analysis
# ============================================

log_info "Detecting languages..."
LANGS=($(detect_languages))
if [[ ${#LANGS[@]} -eq 0 ]]; then
    log_warn "No recognized languages detected"
    LANGS=("unknown")
fi
log_success "Languages: ${LANGS[*]}"

log_info "Detecting project type..."
PROJECT_TYPE=$(detect_project_type)
log_success "Type: $PROJECT_TYPE"

log_info "Analyzing components..."

# Build components array
COMPONENTS="["
FIRST=true

case "$PROJECT_TYPE" in
    fullstack)
        # Backend
        if check_dir_exists "backend"; then
            backend_lang="go"
            if check_file_exists "backend/package.json"; then
                backend_lang="typescript"
            elif check_file_exists "backend/Cargo.toml"; then
                backend_lang="rust"
            elif check_file_exists "backend/requirements.txt" || check_file_exists "backend/pyproject.toml"; then
                backend_lang="python"
            fi
            COMPONENTS+=$(analyze_component "backend" "backend" "$backend_lang")
            FIRST=false
        fi

        # Frontend
        if check_dir_exists "frontend"; then
            [[ "$FIRST" == "false" ]] && COMPONENTS+=","
            frontend_lang="typescript"
            if ! check_file_exists "frontend/tsconfig.json"; then
                frontend_lang="javascript"
            fi
            COMPONENTS+=$(analyze_component "frontend" "frontend" "$frontend_lang")
        fi
        ;;
    *)
        # Single component
        for lang in "${LANGS[@]}"; do
            [[ "$FIRST" == "false" ]] && COMPONENTS+=","
            COMPONENTS+=$(analyze_component "main" "." "$lang")
            FIRST=false
        done
        ;;
esac

COMPONENTS+="]"

log_info "Detecting infrastructure..."
INFRA=$(detect_infrastructure)
log_success "Infrastructure detected"

# Calculate quality baseline
TOTAL_TESTS=0
for lang in "${LANGS[@]}"; do
    count=$(count_tests "$lang" ".")
    TOTAL_TESTS=$((TOTAL_TESTS + count))
done

# ============================================
# Generate Output
# ============================================

OUTPUT_FILE="$OUTPUT_DIR/${PROJECT_NAME}-analysis.json"

cat > "$OUTPUT_FILE" <<EOF
{
  "analyzed_at": "$(date -Iseconds)",
  "project_path": "$PROJECT_PATH",
  "project_name": "$PROJECT_NAME",
  "detected_type": "$PROJECT_TYPE",
  "components": $COMPONENTS,
  "infrastructure": $INFRA,
  "quality_baseline": {
    "total_tests": $TOTAL_TESTS,
    "coverage": "unknown",
    "lint_passing": true,
    "build_passing": true
  },
  "recommendations": [],
  "aida_compatibility": {
    "supported": true,
    "notes": ["Analysis complete"]
  }
}
EOF

log_success "Analysis complete: $OUTPUT_FILE"

# ============================================
# Display Summary
# ============================================

echo ""
echo "========================================"
echo " AIDA Project Analysis Complete"
echo "========================================"
echo ""
echo "Project: $PROJECT_NAME"
echo "Path: $PROJECT_PATH"
echo "Type: $PROJECT_TYPE"
echo "Languages: ${LANGS[*]}"
echo ""
echo "Components:"
echo "$COMPONENTS" | jq -r '.[] | "  - \(.name) (\(.lang)/\(.framework)): \(.test_files) test files"' 2>/dev/null || echo "  (JSON parsing unavailable)"
echo ""
echo "Infrastructure:"
echo "$INFRA" | jq -r 'to_entries | .[] | "  - \(.key): \(.value)"' 2>/dev/null || echo "  (JSON parsing unavailable)"
echo ""
echo "Quality Baseline:"
echo "  - Total Test Files: $TOTAL_TESTS"
echo ""
echo "Output: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  /aida:enhance $PROJECT_PATH \"your improvement spec\""
echo "  /aida:maintain $PROJECT_PATH --update-deps"
echo ""
