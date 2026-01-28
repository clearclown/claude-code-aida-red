#!/bin/bash
# Meta-tests for test-framework.sh
# Verifies the test framework assertions work correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test-framework.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)

echo "========================================"
echo "Testing: test-framework.sh"
echo "========================================"
echo ""

# ============================================
# Test: assert_file_not_exists
# ============================================
test_start "assert_file_not_exists works for missing file"
if assert_file_not_exists "$TEMP_DIR/nonexistent_file.txt" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_regex_matches
# ============================================
test_start "assert_regex_matches works for matching pattern"
if assert_regex_matches "^[0-9]+$" "12345" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_regex_matches with date pattern
# ============================================
test_start "assert_regex_matches works for date pattern"
if assert_regex_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}" "2024-01-15" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_symlink
# ============================================
test_start "assert_symlink works for symlinks"
ln -sf "$TEMP_DIR" "$TEMP_DIR/test_link"
if assert_symlink "$TEMP_DIR/test_link" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_file_mode
# ============================================
test_start "assert_file_mode checks permissions correctly"
echo "test" > "$TEMP_DIR/mode_test.txt"
chmod 644 "$TEMP_DIR/mode_test.txt"
if assert_file_mode "$TEMP_DIR/mode_test.txt" "644" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_file_mode for executable
# ============================================
test_start "assert_file_mode works for executable files"
echo "#!/bin/bash" > "$TEMP_DIR/exec_test.sh"
chmod 755 "$TEMP_DIR/exec_test.sh"
if assert_file_mode "$TEMP_DIR/exec_test.sh" "755" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: All basic assertions exist
# ============================================
test_start "All basic assertions are defined"
if type assert_equals &>/dev/null && \
   type assert_not_equals &>/dev/null && \
   type assert_contains &>/dev/null && \
   type assert_file_exists &>/dev/null && \
   type assert_json_valid &>/dev/null; then
    test_pass
fi

# ============================================
# Test: New assertions are defined
# ============================================
test_start "New assertions are defined"
if type assert_file_not_exists &>/dev/null && \
   type assert_regex_matches &>/dev/null && \
   type assert_symlink &>/dev/null && \
   type assert_file_mode &>/dev/null; then
    test_pass
fi

# ============================================
# Test: create_temp_dir creates directory
# ============================================
test_start "create_temp_dir creates a directory"
if [[ -d "$TEMP_DIR" ]]; then
    test_pass
fi

# ============================================
# Test: test_start increments counter
# ============================================
test_start "test_start increments counter"
if [[ $TESTS_RUN -gt 0 ]]; then
    test_pass
fi

# ============================================
# Test: assert_greater_than
# ============================================
test_start "assert_greater_than works correctly"
if assert_greater_than 5 10 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_less_than
# ============================================
test_start "assert_less_than works correctly"
if assert_less_than 10 5 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_not_empty
# ============================================
test_start "assert_not_empty works correctly"
if assert_not_empty "some value" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: assert_empty
# ============================================
test_start "assert_empty works correctly"
if assert_empty "" 2>/dev/null; then
    test_pass
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
