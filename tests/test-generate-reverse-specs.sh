#!/bin/bash
# Tests for generate-reverse-specs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/generate-reverse-specs.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: generate-reverse-specs.sh"
echo "========================================"
echo ""

# ============================================
# Test: Script exists and is executable
# ============================================
test_start "Script exists and is executable"
if assert_file_exists "$SCRIPT" && assert_executable "$SCRIPT"; then
    test_pass
fi

# ============================================
# Test: Script has valid bash syntax
# ============================================
test_start "Script has valid bash syntax"
if bash -n "$SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "Bash syntax error in script"
fi

# ============================================
# Test: Handles missing directory
# ============================================
test_start "Handles missing directory"
output=$(run_script "$SCRIPT" "$TEMP_DIR/nonexistent" 2>&1) || true
if assert_contains "$output" "does not exist" || \
   assert_contains "$output" "Error"; then
    test_pass
fi

# ============================================
# Test: Detects language
# ============================================
test_start "Detects multiple languages"
if grep -q 'detect_language()' "$SCRIPT" && \
   grep -qE 'go.mod|Cargo.toml|package.json' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect languages"
fi

# ============================================
# Test: Extracts Go endpoints
# ============================================
test_start "Extracts Go API endpoints"
if grep -q 'extract_go_endpoints()' "$SCRIPT" && \
   grep -qE 'gin|router|mux' "$SCRIPT"; then
    test_pass
else
    test_fail "Should extract Go endpoints"
fi

# ============================================
# Test: Extracts Go models
# ============================================
test_start "Extracts Go data models"
if grep -q 'extract_go_models()' "$SCRIPT" && \
   grep -q 'struct' "$SCRIPT"; then
    test_pass
else
    test_fail "Should extract Go models"
fi

# ============================================
# Test: Extracts TypeScript endpoints
# ============================================
test_start "Extracts TypeScript endpoints"
if grep -q 'extract_ts_endpoints()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should extract TS endpoints"
fi

# ============================================
# Test: Extracts Python endpoints
# ============================================
test_start "Extracts Python endpoints"
if grep -q 'extract_python_endpoints()' "$SCRIPT" && \
   grep -qE 'FastAPI|Flask' "$SCRIPT"; then
    test_pass
else
    test_fail "Should extract Python endpoints"
fi

# ============================================
# Test: Extracts Rust endpoints
# ============================================
test_start "Extracts Rust endpoints"
if grep -q 'extract_rust_endpoints()' "$SCRIPT" && \
   grep -qE '#\[get|#\[post|web::' "$SCRIPT"; then
    test_pass
else
    test_fail "Should extract Rust endpoints"
fi

# ============================================
# Test: Detects coding patterns
# ============================================
test_start "Detects coding patterns"
if grep -q 'detect_patterns()' "$SCRIPT" && \
   grep -qE 'Repository|Service|Middleware' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect patterns"
fi

# ============================================
# Test: Detects directory structure
# ============================================
test_start "Detects directory structure"
if grep -q 'detect_structure()' "$SCRIPT" && \
   grep -qE 'cmd|internal|src|components' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect structure"
fi

# ============================================
# Test: Generates markdown output
# ============================================
test_start "Generates markdown output"
if grep -q 'reverse-design.md' "$SCRIPT" && \
   grep -q 'API Endpoints' "$SCRIPT" && \
   grep -q 'Data Models' "$SCRIPT"; then
    test_pass
else
    test_fail "Should generate markdown"
fi

# ============================================
# Test: Sources common library
# ============================================
test_start "Sources common library"
if grep -q 'lib/common.sh' "$SCRIPT"; then
    test_pass
else
    test_fail "Should source lib/common.sh"
fi

# ============================================
# Test: Shows header when run
# ============================================
test_start "Shows header when run"
output=$(run_script "$SCRIPT" 2>&1) || true
if assert_contains "$output" "Reverse Specification" || \
   assert_contains "$output" "AIDA"; then
    test_pass
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
