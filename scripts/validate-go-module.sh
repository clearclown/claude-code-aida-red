#!/bin/bash
# AIDA Go Module Validator
# Purpose: Validate Go projects have proper go.mod initialization (#182)
# Usage: ./validate-go-module.sh <go_project_dir>
#
# This script addresses Issue #182:
# - Checks go.mod exists
# - Validates module name
# - Ensures go.sum is generated
# - Verifies dependencies are downloaded

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

GO_DIR="${1:-}"

if [[ -z "$GO_DIR" ]]; then
    echo "Usage: $0 <go_project_directory>" >&2
    exit 1
fi

if [[ ! -d "$GO_DIR" ]]; then
    echo "Error: Directory not found: $GO_DIR" >&2
    exit 1
fi

echo "=== Go Module Validation ==="
echo "Directory: $GO_DIR"
echo ""

ERRORS=0
WARNINGS=0

# ============================================
# Check go.mod exists
# ============================================
GO_MOD="$GO_DIR/go.mod"
if [[ ! -f "$GO_MOD" ]]; then
    echo "✗ go.mod not found" >&2
    echo ""
    echo "To initialize Go module, run:" >&2
    echo "  cd $GO_DIR" >&2
    echo "  go mod init <module-name>" >&2
    ERRORS=$((ERRORS + 1))
else
    echo "✓ go.mod found"

    # Check module name
    MODULE_NAME=$(grep "^module " "$GO_MOD" | awk '{print $2}')
    if [[ -n "$MODULE_NAME" ]]; then
        echo "  Module: $MODULE_NAME"
    else
        echo "  ⚠ Module name not found in go.mod"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check Go version
    GO_VERSION=$(grep "^go " "$GO_MOD" | awk '{print $2}')
    if [[ -n "$GO_VERSION" ]]; then
        echo "  Go version: $GO_VERSION"
    else
        echo "  ⚠ Go version not specified in go.mod"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ============================================
# Check go.sum exists (if there are dependencies)
# ============================================
echo ""
echo "Checking dependencies..."

GO_SUM="$GO_DIR/go.sum"
DEP_COUNT=$(grep "^require" "$GO_MOD" -A 100 2>/dev/null | grep -E "^\t" | wc -l || echo "0")

if [[ $DEP_COUNT -gt 0 ]]; then
    echo "  Dependencies declared: $DEP_COUNT"

    if [[ ! -f "$GO_SUM" ]]; then
        echo "  ✗ go.sum not found (but dependencies exist)"
        echo ""
        echo "  To download dependencies, run:" >&2
        echo "    cd $GO_DIR && go mod tidy" >&2
        ERRORS=$((ERRORS + 1))
    else
        echo "  ✓ go.sum found"
    fi
else
    echo "  No external dependencies declared"
fi

# ============================================
# Check for common Go project structure
# ============================================
echo ""
echo "Checking project structure..."

# cmd/ directory
if [[ -d "$GO_DIR/cmd" ]]; then
    CMD_COUNT=$(find "$GO_DIR/cmd" -name "main.go" 2>/dev/null | wc -l)
    echo "  ✓ cmd/ directory ($CMD_COUNT entry points)"
else
    echo "  ⚠ cmd/ directory not found (optional)"
fi

# internal/ directory
if [[ -d "$GO_DIR/internal" ]]; then
    INTERNAL_COUNT=$(find "$GO_DIR/internal" -name "*.go" ! -name "*_test.go" 2>/dev/null | wc -l)
    echo "  ✓ internal/ directory ($INTERNAL_COUNT files)"
else
    echo "  ⚠ internal/ directory not found (optional)"
fi

# pkg/ directory
if [[ -d "$GO_DIR/pkg" ]]; then
    PKG_COUNT=$(find "$GO_DIR/pkg" -name "*.go" ! -name "*_test.go" 2>/dev/null | wc -l)
    echo "  ✓ pkg/ directory ($PKG_COUNT files)"
fi

# ============================================
# Check Go files compile
# ============================================
echo ""
echo "Checking compilation..."

if command -v go &>/dev/null; then
    cd "$GO_DIR"
    if go build ./... 2>/dev/null; then
        echo "  ✓ All packages compile successfully"
    else
        echo "  ✗ Compilation errors detected"
        echo ""
        echo "  Run 'go build ./...' to see errors"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ⚠ Go not installed, skipping compilation check"
    WARNINGS=$((WARNINGS + 1))
fi

# ============================================
# Check for test files
# ============================================
echo ""
echo "Checking tests..."

TEST_FILES=$(find "$GO_DIR" -name "*_test.go" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

if [[ $TEST_FILES -eq 0 ]]; then
    echo "  ⚠ No test files found"
    WARNINGS=$((WARNINGS + 1))
fi

# ============================================
# Summary
# ============================================
echo ""
echo "=== Validation Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    if [[ $WARNINGS -gt 0 ]]; then
        echo "✓ Validation passed with $WARNINGS warning(s)"
    else
        echo "✓ All validations passed"
    fi
    exit 0
else
    echo "✗ $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
fi
