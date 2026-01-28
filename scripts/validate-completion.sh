#!/bin/bash
# AIDA Completion Validator
# Purpose: Validate all required files exist before completion report (#117)
# Usage: ./validate-completion.sh <project_dir>
#
# This script addresses Issue #117:
# - Validates project structure is complete
# - Checks all required files exist
# - Verifies file contents are not empty
# - Ensures tests are present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-}"

if [[ -z "$PROJECT_DIR" ]]; then
    echo "Usage: $0 <project_directory>" >&2
    exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: Directory not found: $PROJECT_DIR" >&2
    exit 1
fi

# Source common library if available
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Fallback logging
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[PASS] $1"; }
    log_error() { echo "[FAIL] $1"; }
    log_warning() { echo "[WARN] $1"; }
fi

echo "=== AIDA Completion Validator ==="
echo "Project: $PROJECT_DIR"
echo ""

ERRORS=0
WARNINGS=0

# ============================================
# Helper functions
# ============================================
check_file() {
    local file="$1"
    local description="$2"
    local required="${3:-true}"
    local min_size="${4:-10}"

    if [[ -f "$file" ]]; then
        local size
        size=$(wc -c < "$file")
        if [[ $size -ge $min_size ]]; then
            log_success "$description ($size bytes)"
            return 0
        else
            log_warning "$description (too small: $size bytes)"
            WARNINGS=$((WARNINGS + 1))
            return 1
        fi
    else
        if [[ "$required" == "true" ]]; then
            log_error "$description (MISSING)"
            ERRORS=$((ERRORS + 1))
        else
            log_warning "$description (not found, optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

check_dir() {
    local dir="$1"
    local description="$2"
    local min_files="${3:-1}"

    if [[ -d "$dir" ]]; then
        local count
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        if [[ $count -ge $min_files ]]; then
            log_success "$description ($count files)"
            return 0
        else
            log_warning "$description (only $count files, expected $min_files+)"
            WARNINGS=$((WARNINGS + 1))
            return 1
        fi
    else
        log_error "$description (MISSING)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# ============================================
# Backend Validation
# ============================================
BACKEND_DIR="$PROJECT_DIR/backend"
if [[ -d "$BACKEND_DIR" ]]; then
    echo ""
    echo "=== Backend Validation ==="

    check_file "$BACKEND_DIR/go.mod" "go.mod"
    check_file "$BACKEND_DIR/main.go" "main.go" "false"
    check_dir "$BACKEND_DIR/cmd" "cmd/ directory" 1
    check_dir "$BACKEND_DIR/internal" "internal/ directory" 3

    # Check for handlers
    if [[ -d "$BACKEND_DIR/internal/handler" ]]; then
        HANDLER_COUNT=$(find "$BACKEND_DIR/internal/handler" -name "*.go" ! -name "*_test.go" 2>/dev/null | wc -l)
        if [[ $HANDLER_COUNT -ge 3 ]]; then
            log_success "Handlers ($HANDLER_COUNT files)"
        else
            log_warning "Handlers (only $HANDLER_COUNT, expected 3+)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for test files
    TEST_COUNT=$(find "$BACKEND_DIR" -name "*_test.go" 2>/dev/null | wc -l)
    if [[ $TEST_COUNT -ge 5 ]]; then
        log_success "Test files ($TEST_COUNT)"
    else
        log_error "Test files (only $TEST_COUNT, need 5+)"
        ERRORS=$((ERRORS + 1))
    fi

    # Check Dockerfile
    check_file "$BACKEND_DIR/Dockerfile" "Dockerfile"
fi

# ============================================
# Frontend Validation
# ============================================
FRONTEND_DIR="$PROJECT_DIR/frontend"
if [[ -d "$FRONTEND_DIR" ]]; then
    echo ""
    echo "=== Frontend Validation ==="

    check_file "$FRONTEND_DIR/package.json" "package.json"
    check_file "$FRONTEND_DIR/tsconfig.json" "tsconfig.json"
    check_file "$FRONTEND_DIR/vite.config.ts" "vite.config.ts" "false"
    check_dir "$FRONTEND_DIR/src" "src/ directory" 5

    # Check for components
    if [[ -d "$FRONTEND_DIR/src/components" ]]; then
        COMPONENT_COUNT=$(find "$FRONTEND_DIR/src/components" -name "*.tsx" ! -name "*.test.tsx" 2>/dev/null | wc -l)
        if [[ $COMPONENT_COUNT -ge 5 ]]; then
            log_success "Components ($COMPONENT_COUNT files)"
        else
            log_warning "Components (only $COMPONENT_COUNT, expected 5+)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for pages
    if [[ -d "$FRONTEND_DIR/src/pages" ]]; then
        PAGE_COUNT=$(find "$FRONTEND_DIR/src/pages" -name "*.tsx" ! -name "*.test.tsx" 2>/dev/null | wc -l)
        if [[ $PAGE_COUNT -ge 3 ]]; then
            log_success "Pages ($PAGE_COUNT files)"
        else
            log_warning "Pages (only $PAGE_COUNT, expected 3+)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for test files
    TEST_COUNT=$(find "$FRONTEND_DIR/src" -name "*.test.tsx" -o -name "*.test.ts" 2>/dev/null | wc -l)
    if [[ $TEST_COUNT -ge 5 ]]; then
        log_success "Test files ($TEST_COUNT)"
    else
        log_error "Test files (only $TEST_COUNT, need 5+)"
        ERRORS=$((ERRORS + 1))
    fi

    # Check Dockerfile
    check_file "$FRONTEND_DIR/Dockerfile" "Dockerfile"
fi

# ============================================
# Infrastructure Validation
# ============================================
echo ""
echo "=== Infrastructure Validation ==="

check_file "$PROJECT_DIR/docker-compose.yml" "docker-compose.yml" "false"
check_file "$PROJECT_DIR/docker-compose.yaml" "docker-compose.yaml" "false"
check_file "$PROJECT_DIR/README.md" "README.md"
check_file "$PROJECT_DIR/Makefile" "Makefile" "false"

# ============================================
# E2E Validation
# ============================================
E2E_DIR="$FRONTEND_DIR/e2e"
if [[ -d "$E2E_DIR" ]]; then
    echo ""
    echo "=== E2E Tests Validation ==="

    E2E_COUNT=$(find "$E2E_DIR" -name "*.spec.ts" -o -name "*.test.ts" 2>/dev/null | wc -l)
    if [[ $E2E_COUNT -ge 3 ]]; then
        log_success "E2E test files ($E2E_COUNT)"
    else
        log_warning "E2E test files (only $E2E_COUNT, expected 3+)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ============================================
# Summary
# ============================================
echo ""
echo "=== Validation Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    log_success "Project is ready for completion report"
    exit 0
else
    log_error "Project has $ERRORS critical issue(s) - fix before completing"
    exit 1
fi
