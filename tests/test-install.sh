#!/bin/bash
# Tests for install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"

SCRIPT="$PROJECT_ROOT/scripts/install.sh"

echo "========================================"
echo "Testing: install.sh"
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
# Test: Uses cp instead of ln -s (Issue #178 fix)
# ============================================
test_start "Uses file copy instead of symlinks (Issue #178)"
# Check that script uses cp command for installation
if grep -q 'cp -f' "$SCRIPT"; then
    test_pass
else
    test_fail "Should use 'cp -f' instead of symlinks"
fi

# ============================================
# Test: Removes old symlinks before copy
# ============================================
test_start "Removes old symlinks before copy"
if grep -q '\-L.*rm -f' "$SCRIPT"; then
    test_pass
else
    test_fail "Should remove old symlinks before copying"
fi

# ============================================
# Test: Creates commands directory
# ============================================
test_start "Creates commands directory"
if grep -q 'mkdir -p.*COMMANDS_DIR' "$SCRIPT"; then
    test_pass
else
    test_fail "Should create commands directory"
fi

# ============================================
# Test: Installs main aida command
# ============================================
test_start "Installs main aida command"
if grep -q 'aida.md' "$SCRIPT"; then
    test_pass
else
    test_fail "Should install main aida command"
fi

# ============================================
# Test: Installs core subcommands
# ============================================
test_start "Installs core subcommands (init, start, status, work, pipeline)"
if grep -qE 'init.*start.*status.*work.*pipeline' "$SCRIPT"; then
    test_pass
else
    test_fail "Should install core subcommands"
fi

# ============================================
# Test: Installs enhance command
# ============================================
test_start "Installs enhance command"
if grep -q 'enhance' "$SCRIPT"; then
    test_pass
else
    test_fail "Should install enhance command"
fi

# ============================================
# Test: Checks for claude command
# ============================================
test_start "Checks for claude command availability"
if grep -q 'command -v claude' "$SCRIPT"; then
    test_pass
else
    test_fail "Should check for claude command"
fi

# ============================================
# Test: Handles existing installation
# ============================================
test_start "Handles existing installation (update)"
if grep -q 'if.*-d.*INSTALL_DIR' "$SCRIPT" && \
   grep -q 'git pull' "$SCRIPT"; then
    test_pass
else
    test_fail "Should handle existing installation updates"
fi

# ============================================
# Test: Has install_command helper function
# ============================================
test_start "Has install_command helper function"
if grep -q 'install_command()' "$SCRIPT"; then
    test_pass
else
    test_fail "Should have install_command helper function"
fi

# ============================================
# Test: Installs resume command
# ============================================
test_start "Installs resume command"
if grep -q 'resume' "$SCRIPT"; then
    test_pass
else
    test_fail "Should install resume command"
fi

# ============================================
# Test: Installs fix command
# ============================================
test_start "Installs fix command"
if grep -q 'fix' "$SCRIPT"; then
    test_pass
else
    test_fail "Should install fix command"
fi

# ============================================
# Test: Shows available commands in output
# ============================================
test_start "Shows available commands in output"
if grep -qE "Available commands|/aida" "$SCRIPT"; then
    test_pass
else
    test_fail "Should show available commands"
fi

print_summary
