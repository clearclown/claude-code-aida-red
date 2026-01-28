#!/bin/bash
# Tests for capture-baseline.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/capture-baseline.sh"

echo "========================================"
echo "Testing: capture-baseline.sh"
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
# Test: Detects multiple languages
# ============================================
test_start "Detects multiple languages"
if grep -q 'detect_language()' "$SCRIPT" && \
   grep -qE 'go.mod|Cargo.toml|package.json|requirements.txt' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect multiple languages"
fi

# ============================================
# Test: Detects test frameworks
# ============================================
test_start "Detects test frameworks"
if grep -q 'detect_test_framework()' "$SCRIPT" && \
   grep -qE 'vitest|jest|pytest|cargo' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect test frameworks"
fi

# ============================================
# Test: Captures Go baseline
# ============================================
test_start "Captures Go baseline"
if grep -q 'capture_go_baseline()' "$SCRIPT" && \
   grep -q 'go test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should capture Go baseline"
fi

# ============================================
# Test: Captures TypeScript baseline
# ============================================
test_start "Captures TypeScript/JS baseline"
if grep -q 'capture_ts_baseline()' "$SCRIPT" && \
   grep -qE 'npm|pnpm|yarn' "$SCRIPT"; then
    test_pass
else
    test_fail "Should capture TS/JS baseline"
fi

# ============================================
# Test: Captures Python baseline
# ============================================
test_start "Captures Python baseline"
if grep -q 'capture_python_baseline()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should capture Python baseline"
fi

# ============================================
# Test: Captures Rust baseline
# ============================================
test_start "Captures Rust baseline"
if grep -q 'capture_rust_baseline()' "$SCRIPT" && \
   grep -q 'cargo test' "$SCRIPT"; then
    test_pass
else
    test_fail "Should capture Rust baseline"
fi

# ============================================
# Test: Detects project components
# ============================================
test_start "Detects project components"
if grep -q 'detect_components()' "$SCRIPT" && \
   grep -qE 'backend|frontend|packages' "$SCRIPT"; then
    test_pass
else
    test_fail "Should detect components"
fi

# ============================================
# Test: Generates JSON output
# ============================================
test_start "Generates JSON output"
if grep -q 'enhance-baseline.json' "$SCRIPT" && \
   grep -qE 'captured_at|components|summary' "$SCRIPT"; then
    test_pass
else
    test_fail "Should generate JSON output"
fi

# ============================================
# Test: Tracks coverage
# ============================================
test_start "Tracks test coverage"
if grep -q 'coverage' "$SCRIPT"; then
    test_pass
else
    test_fail "Should track coverage"
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
# Test: Has main function
# ============================================
test_start "Has main function"
if grep -qE 'main\(\)|capture_baseline\(\)' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have main function"
fi

# ============================================
# Test: Shows usage in comments
# ============================================
test_start "Shows usage in comments"
if grep -qE 'Usage:' "$SCRIPT"; then
    test_pass
else
    test_fail "Should show usage in comments"
fi

print_summary
