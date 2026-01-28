#!/bin/bash
# Tests for setup-jj.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/setup-jj.sh"

echo "========================================"
echo "Testing: setup-jj.sh"
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
# Test: Help command works
# ============================================
test_start "Help command works"
output=$(run_script "$SCRIPT" --help 2>&1) || true
if assert_contains "$output" "Usage" || \
   assert_contains "$output" "jj"; then
    test_pass
fi

# ============================================
# Test: Check-only option works
# ============================================
test_start "Check-only option exists"
if grep -q '\-\-check-only' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support --check-only option"
fi

# ============================================
# Test: Supports multiple install methods
# ============================================
test_start "Supports multiple install methods (cargo, brew, pacman, nix)"
if grep -q 'cargo install' "$SCRIPT" && \
   grep -q 'brew install' "$SCRIPT" && \
   grep -q 'pacman' "$SCRIPT" && \
   grep -q 'nix-env' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support multiple install methods"
fi

# ============================================
# Test: Configures jj for AIDA
# ============================================
test_start "Configures jj for AIDA"
if grep -q 'configure_jj()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should configure jj for AIDA"
fi

# ============================================
# Test: Uses git user config
# ============================================
test_start "Uses git user config for jj"
if grep -q 'git config user.name' "$SCRIPT" && \
   grep -q 'git config user.email' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use git user config"
fi

# ============================================
# Test: Supports colocated git repos
# ============================================
test_start "Supports colocated git repos"
if grep -q 'git init --colocate' "$SCRIPT"; then
    test_pass
else
    test_fail "Should support colocated git repos"
fi

# ============================================
# Test: Has init command
# ============================================
test_start "Has init command"
if grep -q '\-\-init' "$SCRIPT" && \
   grep -q 'init_jj_repo()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have init command"
fi

# ============================================
# Test: Downloads binary for unsupported package managers
# ============================================
test_start "Downloads binary fallback"
if grep -q 'martinvonz/jj/releases' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have binary download fallback"
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
# Test: Has status/version check
# ============================================
test_start "Has status/version check"
if grep -qE 'jj --version|jj version|check_jj_version' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have status/version check"
fi

# ============================================
# Test: Has configure_jj function
# ============================================
test_start "Has configure_jj function"
if grep -q 'configure_jj()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have configure_jj function"
fi

# ============================================
# Test: Has check_jj function
# ============================================
test_start "Has check_jj function"
if grep -q 'check_jj()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have check_jj function"
fi

print_summary
