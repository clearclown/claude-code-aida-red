#!/bin/bash
# AIDA Reverse Specification Generator
# Extracts API endpoints, data models, and patterns from existing code
# Language-agnostic: auto-detects and parses appropriate files
#
# Usage: ./scripts/generate-reverse-specs.sh <project-path> [analysis-json]
#
# Output: .aida/specs/<project>-reverse-design.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

PROJECT_PATH="${1:-.}"
ANALYSIS_FILE="${2:-}"
PROJECT_NAME=$(basename "$(cd "$PROJECT_PATH" && pwd)")
OUTPUT_FILE=".aida/specs/${PROJECT_NAME}-reverse-design.md"

echo -e "${BLUE}AIDA Reverse Specification Generator${NC}"
echo "======================================"
echo ""

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

cd "$PROJECT_PATH"

# Create output directory using ensure_dir from common.sh
ensure_dir ".aida/specs"

# Detect language
detect_language() {
    if [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        echo "typescript"
    else
        echo "unknown"
    fi
}

# Extract Go API endpoints
extract_go_endpoints() {
    echo -e "${BLUE}Extracting Go API endpoints...${NC}"

    local endpoints=""

    # Find router files
    local router_files=$(find . -name "*.go" -exec grep -l "router\|Router\|gin\.\|echo\.\|fiber\.\|chi\.\|mux\." {} \; 2>/dev/null | head -20)

    for file in $router_files; do
        # Extract Gin/Echo routes (GET, POST, PUT, DELETE, PATCH patterns)
        local routes=""
        routes+=$(grep -E '\.(GET|POST|PUT|DELETE|PATCH)' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        # Extract Gorilla mux routes
        routes+=$(grep 'HandleFunc' "$file" 2>/dev/null | grep -oE '"[^"]*"' | head -1 | tr -d '"' || true)
        [[ -n "$routes" ]] && endpoints+="$routes"$'\n'
    done

    echo "$endpoints" | sort -u | grep -v "^$"
}

# Extract Go data models
extract_go_models() {
    echo -e "${BLUE}Extracting Go data models...${NC}"

    local models=""

    # Find struct definitions
    local struct_files=$(find . -name "*.go" -exec grep -l "type.*struct" {} \; 2>/dev/null | head -30)

    for file in $struct_files; do
        # Extract struct names with JSON tags (likely API models)
        local structs=$(grep -E 'type [A-Za-z_][A-Za-z0-9_]* struct' "$file" 2>/dev/null | sed 's/type //;s/ struct.*//' || true)
        [[ -n "$structs" ]] && models+="$structs"$'\n'
    done

    echo "$models" | sort -u | grep -v "^$"
}

# Extract TypeScript API endpoints
extract_ts_endpoints() {
    echo -e "${BLUE}Extracting TypeScript/JavaScript API endpoints...${NC}"

    local endpoints=""

    # Find route files
    local route_files=$(find . -name "*.ts" -o -name "*.js" | xargs grep -l "app\.\|router\.\|route\(" 2>/dev/null | head -20)

    for file in $route_files; do
        # Express/Fastify routes
        local routes=$(grep -E '(app|router)\.(get|post|put|delete|patch)' "$file" 2>/dev/null | grep -oE "['\"][^'\"]*['\"]" | head -1 | tr -d "'\""  || true)
        [[ -n "$routes" ]] && endpoints+="$routes"$'\n'
    done

    # Next.js API routes (file-based)
    if [[ -d "app/api" ]] || [[ -d "pages/api" ]]; then
        local api_files=$(find . -path "*/api/*" -name "*.ts" -o -path "*/api/*" -name "*.js" 2>/dev/null)
        for file in $api_files; do
            local route=$(echo "$file" | sed 's|.*api/||;s|/route\.\(ts\|js\)||;s|\.\(ts\|js\)||')
            endpoints+="/api/$route"$'\n'
        done
    fi

    echo "$endpoints" | sort -u | grep -v "^$"
}

# Extract TypeScript interfaces/types
extract_ts_models() {
    echo -e "${BLUE}Extracting TypeScript interfaces/types...${NC}"

    local models=""

    # Find type definition files
    local type_files=$(find . -name "*.ts" -exec grep -l "interface\|type.*=" {} \; 2>/dev/null | head -30)

    for file in $type_files; do
        # Extract interface names
        local interfaces=""
        interfaces+=$(grep -E '^export interface [A-Za-z_]' "$file" 2>/dev/null | sed 's/export interface //;s/ .*//' || true)
        interfaces+=$'\n'
        interfaces+=$(grep -E '^interface [A-Za-z_]' "$file" 2>/dev/null | sed 's/interface //;s/ .*//' || true)
        interfaces+=$'\n'
        interfaces+=$(grep -E '^export type [A-Za-z_]' "$file" 2>/dev/null | sed 's/export type //;s/ .*//' || true)
        interfaces+=$'\n'
        interfaces+=$(grep -E '^type [A-Za-z_]' "$file" 2>/dev/null | sed 's/type //;s/ .*//' || true)
        [[ -n "$interfaces" ]] && models+="$interfaces"$'\n'
    done

    echo "$models" | sort -u | grep -v "^$"
}

# Extract Python API endpoints
extract_python_endpoints() {
    echo -e "${BLUE}Extracting Python API endpoints...${NC}"

    local endpoints=""

    # Find route files
    local route_files=$(find . -name "*.py" -exec grep -l "@app\.\|@router\.\|@api\." {} \; 2>/dev/null | head -20)

    for file in $route_files; do
        # FastAPI/Flask decorators
        local routes=$(grep -E '@(app|router)\.(get|post|put|delete|patch)' "$file" 2>/dev/null | grep -oE "[\"'][^\"']*[\"']" | head -1 | tr -d "\"'" || true)
        [[ -n "$routes" ]] && endpoints+="$routes"$'\n'
    done

    echo "$endpoints" | sort -u | grep -v "^$"
}

# Extract Python data models
extract_python_models() {
    echo -e "${BLUE}Extracting Python data models...${NC}"

    local models=""

    # Find model files
    local model_files=$(find . -name "*.py" -exec grep -l "BaseModel\|dataclass\|class.*Model" {} \; 2>/dev/null | head -30)

    for file in $model_files; do
        # Pydantic/dataclass models
        local classes=$(grep -E '^class [A-Za-z_][A-Za-z0-9_]*' "$file" 2>/dev/null | sed 's/class //;s/[:(].*//' || true)
        [[ -n "$classes" ]] && models+="$classes"$'\n'
    done

    echo "$models" | sort -u | grep -v "^$"
}

# Extract Rust API endpoints
extract_rust_endpoints() {
    echo -e "${BLUE}Extracting Rust API endpoints...${NC}"

    local endpoints=""

    # Find route files
    local route_files=$(find . -name "*.rs" -exec grep -l "#\[get\|#\[post\|web::" {} \; 2>/dev/null | head -20)

    for file in $route_files; do
        # Actix-web / Axum macros - search for route attributes
        local routes=""
        routes+=$(grep '#\[get' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        routes+=$(grep '#\[post' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        routes+=$(grep '#\[put' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        routes+=$(grep '#\[delete' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        routes+=$(grep '#\[patch' "$file" 2>/dev/null | grep -oE '"[^"]*"' | tr -d '"' || true)
        [[ -n "$routes" ]] && endpoints+="$routes"$'\n'
    done

    echo "$endpoints" | sort -u | grep -v "^$"
}

# Extract Rust structs
extract_rust_models() {
    echo -e "${BLUE}Extracting Rust structs...${NC}"

    local models=""

    # Find struct files
    local struct_files=$(find . -name "*.rs" -exec grep -l "struct\|enum" {} \; 2>/dev/null | head -30)

    for file in $struct_files; do
        local structs=""
        structs+=$(grep -E '^pub struct [A-Za-z_][A-Za-z0-9_]*' "$file" 2>/dev/null | sed 's/pub struct //;s/ .*//' || true)
        structs+=$'\n'
        structs+=$(grep -E '^struct [A-Za-z_][A-Za-z0-9_]*' "$file" 2>/dev/null | sed 's/struct //;s/ .*//' || true)
        structs+=$'\n'
        structs+=$(grep -E '^pub enum [A-Za-z_][A-Za-z0-9_]*' "$file" 2>/dev/null | sed 's/pub enum //;s/ .*//' || true)
        structs+=$'\n'
        structs+=$(grep -E '^enum [A-Za-z_][A-Za-z0-9_]*' "$file" 2>/dev/null | sed 's/enum //;s/ .*//' || true)
        [[ -n "$structs" ]] && models+="$structs"$'\n'
    done

    echo "$models" | sort -u | grep -v "^$"
}

# Detect coding patterns
detect_patterns() {
    local lang="$1"

    echo -e "${BLUE}Detecting coding patterns...${NC}"

    local patterns=""

    # Error handling pattern
    if find . -name "*.go" -exec grep -l "errors.New\|fmt.Errorf\|custom.*error" {} \; 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Error Handling**: Custom error types in internal/errors/"$'\n'
    elif find . -name "*.ts" -exec grep -l "class.*Error\|throw new" {} \; 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Error Handling**: Custom Error classes"$'\n'
    fi

    # Authentication pattern
    if find . -name "*.go" -o -name "*.ts" -o -name "*.py" | xargs grep -l "jwt\|JWT\|bearer\|Bearer\|auth" 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Authentication**: JWT-based authentication"$'\n'
    fi

    # Middleware pattern
    if find . -name "*.go" -exec grep -l "middleware\|Middleware" {} \; 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Middleware**: Custom middleware chain"$'\n'
    fi

    # Repository pattern
    if find . -name "*repository*" -o -name "*Repository*" 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Data Access**: Repository pattern"$'\n'
    fi

    # Service pattern
    if find . -name "*service*" -o -name "*Service*" 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Business Logic**: Service layer pattern"$'\n'
    fi

    # Testing pattern
    if find . -name "*_test.go" 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Testing**: Table-driven tests (Go)"$'\n'
    elif find . -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | head -1 | grep -q .; then
        patterns+="- **Testing**: Component/unit tests (TypeScript)"$'\n'
    fi

    echo "$patterns"
}

# Detect directory structure
detect_structure() {
    echo -e "${BLUE}Detecting directory structure...${NC}"

    local structure=""

    # Common directories
    [[ -d "cmd" ]] && structure+="- cmd/ - Entry points"$'\n'
    [[ -d "internal" ]] && structure+="- internal/ - Private packages"$'\n'
    [[ -d "pkg" ]] && structure+="- pkg/ - Public packages"$'\n'
    [[ -d "api" ]] && structure+="- api/ - API definitions"$'\n'
    [[ -d "src" ]] && structure+="- src/ - Source code"$'\n'
    [[ -d "components" ]] && structure+="- components/ - UI components"$'\n'
    [[ -d "pages" ]] && structure+="- pages/ - Page components"$'\n'
    [[ -d "hooks" ]] && structure+="- hooks/ - Custom hooks"$'\n'
    [[ -d "utils" ]] && structure+="- utils/ - Utility functions"$'\n'
    [[ -d "lib" ]] && structure+="- lib/ - Library code"$'\n'
    [[ -d "tests" ]] && structure+="- tests/ - Test files"$'\n'

    echo "$structure"
}

# Main execution
main() {
    local lang=$(detect_language)
    echo -e "${YELLOW}Detected language: $lang${NC}"
    echo ""

    local endpoints=""
    local models=""

    # Extract based on language
    case "$lang" in
        go)
            endpoints=$(extract_go_endpoints)
            models=$(extract_go_models)
            ;;
        typescript|javascript)
            endpoints=$(extract_ts_endpoints)
            models=$(extract_ts_models)
            ;;
        python)
            endpoints=$(extract_python_endpoints)
            models=$(extract_python_models)
            ;;
        rust)
            endpoints=$(extract_rust_endpoints)
            models=$(extract_rust_models)
            ;;
    esac

    local patterns=$(detect_patterns "$lang")
    local structure=$(detect_structure)

    # Count results
    local endpoint_count=$(echo "$endpoints" | grep -c . || echo "0")
    local model_count=$(echo "$models" | grep -c . || echo "0")

    echo ""
    echo -e "${YELLOW}Found: $endpoint_count endpoints, $model_count models${NC}"

    # Generate markdown
    cat > "$OUTPUT_FILE" <<EOF
# Reverse-Engineered Design: $PROJECT_NAME

Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Language: $lang

## Overview

This document describes the existing codebase structure, patterns, and conventions.
**Any enhancement MUST follow these existing patterns.**

---

## Directory Structure

$structure

---

## API Endpoints

Total: $endpoint_count endpoints

\`\`\`
$(echo "$endpoints" | head -50)
\`\`\`

$([ "$endpoint_count" -gt 50 ] && echo "_Note: Showing first 50 endpoints. Total: $endpoint_count_")

---

## Data Models

Total: $model_count models

\`\`\`
$(echo "$models" | head -50)
\`\`\`

$([ "$model_count" -gt 50 ] && echo "_Note: Showing first 50 models. Total: $model_count_")

---

## Coding Patterns

$patterns

---

## Pattern Guidelines for Enhancement

When adding new code, follow these conventions:

### Naming Conventions
- **Files**: $(ls -1 *.go 2>/dev/null | head -1 | sed "s/.go//" || echo "snake_case or camelCase")
- **Functions**: Check existing functions for naming style
- **Variables**: Check existing code for naming style

### Error Handling
- Follow existing error handling patterns
- Use same error types/classes

### Testing
- Follow existing test file naming (*_test.go, *.test.ts, etc.)
- Follow existing test structure (describe/it, t.Run, etc.)
- Maintain or exceed current test coverage

### Code Organization
- Place new handlers in existing handler directories
- Place new models in existing model directories
- Place new services in existing service directories

---

## Critical Files

These files are central to the project architecture:

$(find . -name "main.go" -o -name "app.ts" -o -name "index.ts" -o -name "main.py" -o -name "main.rs" 2>/dev/null | head -5 | sed 's/^/- /')
$(find . -name "router*.go" -o -name "routes*.ts" -o -name "router*.py" 2>/dev/null | head -5 | sed 's/^/- /')

---

## Enhancement Checklist

Before implementing any enhancement:

- [ ] Read 2-3 existing handler files to understand patterns
- [ ] Read 2-3 existing test files to understand test structure
- [ ] Identify where new code will integrate (router, services, etc.)
- [ ] Plan minimal changes to existing files
- [ ] All new code follows existing naming conventions
- [ ] All new code has tests following existing patterns
EOF

    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Reverse Specification Generated${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "Output: ${BLUE}$OUTPUT_FILE${NC}"
    echo ""
    echo "Contents:"
    echo "- $endpoint_count API endpoints"
    echo "- $model_count data models"
    echo "- Coding patterns detected"
    echo "- Directory structure mapped"
}

main
