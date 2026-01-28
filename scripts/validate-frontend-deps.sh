#!/bin/bash
# AIDA Frontend Dependencies Validator
# Purpose: Validate frontend package.json has all required dependencies (#196)
# Usage: ./validate-frontend-deps.sh <frontend_dir>
#
# This script addresses Issue #196:
# - Checks Tailwind CSS is properly configured
# - Validates shadcn-ui components are installed
# - Ensures all peer dependencies are present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

FRONTEND_DIR="${1:-}"

if [[ -z "$FRONTEND_DIR" ]]; then
    echo "Usage: $0 <frontend_directory>" >&2
    exit 1
fi

if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo "Error: Directory not found: $FRONTEND_DIR" >&2
    exit 1
fi

PACKAGE_JSON="$FRONTEND_DIR/package.json"

if [[ ! -f "$PACKAGE_JSON" ]]; then
    echo "Error: package.json not found in $FRONTEND_DIR" >&2
    exit 1
fi

echo "=== Frontend Dependencies Validation ==="
echo "Directory: $FRONTEND_DIR"
echo ""

ERRORS=0

# ============================================
# Required dependencies for Tailwind CSS
# ============================================
TAILWIND_DEPS=(
    "tailwindcss"
    "postcss"
    "autoprefixer"
)

echo "Checking Tailwind CSS dependencies..."
for dep in "${TAILWIND_DEPS[@]}"; do
    if jq -e ".dependencies[\"$dep\"] // .devDependencies[\"$dep\"]" "$PACKAGE_JSON" > /dev/null 2>&1; then
        echo "  ✓ $dep"
    else
        echo "  ✗ $dep (MISSING)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ============================================
# Check tailwind.config.js
# ============================================
echo ""
echo "Checking Tailwind configuration..."
if [[ -f "$FRONTEND_DIR/tailwind.config.js" ]] || [[ -f "$FRONTEND_DIR/tailwind.config.ts" ]]; then
    echo "  ✓ tailwind.config found"
else
    echo "  ✗ tailwind.config.js/ts (MISSING)"
    ERRORS=$((ERRORS + 1))
fi

# ============================================
# Required dependencies for shadcn-ui
# ============================================
SHADCN_DEPS=(
    "@radix-ui/react-slot"
    "class-variance-authority"
    "clsx"
    "tailwind-merge"
)

echo ""
echo "Checking shadcn-ui dependencies..."
for dep in "${SHADCN_DEPS[@]}"; do
    if jq -e ".dependencies[\"$dep\"] // .devDependencies[\"$dep\"]" "$PACKAGE_JSON" > /dev/null 2>&1; then
        echo "  ✓ $dep"
    else
        echo "  ✗ $dep (MISSING)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ============================================
# Check components directory
# ============================================
echo ""
echo "Checking shadcn-ui components..."
COMPONENTS_DIR="$FRONTEND_DIR/src/components/ui"
if [[ -d "$COMPONENTS_DIR" ]]; then
    COMPONENT_COUNT=$(find "$COMPONENTS_DIR" -name "*.tsx" 2>/dev/null | wc -l)
    if [[ $COMPONENT_COUNT -gt 0 ]]; then
        echo "  ✓ UI components found: $COMPONENT_COUNT"
    else
        echo "  ✗ No UI components in $COMPONENTS_DIR"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ✗ Components directory not found: $COMPONENTS_DIR"
    ERRORS=$((ERRORS + 1))
fi

# ============================================
# Check utils.ts (required by shadcn-ui)
# ============================================
echo ""
echo "Checking shadcn-ui utilities..."
UTILS_FILE="$FRONTEND_DIR/src/lib/utils.ts"
if [[ -f "$UTILS_FILE" ]]; then
    if grep -q "clsx" "$UTILS_FILE" && grep -q "twMerge" "$UTILS_FILE"; then
        echo "  ✓ utils.ts with cn() function"
    else
        echo "  ⚠ utils.ts exists but may be incomplete"
    fi
else
    echo "  ✗ utils.ts (MISSING - required for shadcn-ui)"
    ERRORS=$((ERRORS + 1))
fi

# ============================================
# Check React dependencies
# ============================================
REACT_DEPS=(
    "react"
    "react-dom"
)

echo ""
echo "Checking React dependencies..."
for dep in "${REACT_DEPS[@]}"; do
    if jq -e ".dependencies[\"$dep\"]" "$PACKAGE_JSON" > /dev/null 2>&1; then
        VERSION=$(jq -r ".dependencies[\"$dep\"]" "$PACKAGE_JSON")
        echo "  ✓ $dep: $VERSION"
    else
        echo "  ✗ $dep (MISSING)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ============================================
# Summary
# ============================================
echo ""
echo "=== Validation Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    echo "✓ All dependencies validated successfully"
    exit 0
else
    echo "✗ $ERRORS missing dependencies/configurations"
    echo ""
    echo "To fix missing dependencies, run:"
    echo "  cd $FRONTEND_DIR"
    echo "  npm install tailwindcss postcss autoprefixer -D"
    echo "  npm install @radix-ui/react-slot class-variance-authority clsx tailwind-merge"
    echo ""
    echo "For shadcn-ui setup:"
    echo "  npx shadcn-ui@latest init"
    exit 1
fi
