#!/bin/bash
# AIDA Test Framework
# Purpose: Minimal bash testing framework for AIDA scripts
# Usage: source this file, then use assert_* functions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""
TEST_FAILURES=()

# ============================================
# Test Lifecycle
# ============================================

test_start() {
    local name="$1"
    CURRENT_TEST="$name"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}[PASS]${NC} $CURRENT_TEST"
}

test_fail() {
    local reason="${1:-Assertion failed}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TEST_FAILURES+=("$CURRENT_TEST: $reason")
    echo -e "${RED}[FAIL]${NC} $CURRENT_TEST - $reason"
}

test_skip() {
    local reason="${1:-Skipped}"
    echo -e "${YELLOW}[SKIP]${NC} $CURRENT_TEST - $reason"
}

# ============================================
# Assertions
# ============================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Expected value to not equal '$unexpected'}"

    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected '$haystack' to contain '$needle'}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected '$haystack' to not contain '$needle'}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' to exist}"

    if [[ -f "$file" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Expected directory '$dir' to exist}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_executable() {
    local file="$1"
    local message="${2:-Expected '$file' to be executable}"

    if [[ -x "$file" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected exit code $expected but got $actual}"

    if [[ "$expected" -eq "$actual" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_json_valid() {
    local json="$1"
    local message="${2:-Expected valid JSON}"

    if echo "$json" | jq empty 2>/dev/null; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="${3:-}"
    local message="${4:-Expected JSON field '$field' to exist}"

    local actual
    actual=$(echo "$json" | jq -r "$field" 2>/dev/null) || actual=""

    # If no expected value, just check field exists
    if [[ -z "$expected" ]]; then
        if [[ -n "$actual" ]] && [[ "$actual" != "null" ]]; then
            return 0
        else
            test_fail "$message (field not found or null)"
            return 1
        fi
    fi

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        test_fail "$message (got: $actual)"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Expected condition to be true}"

    if eval "$condition"; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Expected condition to be false}"

    if ! eval "$condition"; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Expected command '$cmd' to exist}"

    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_output_matches() {
    local pattern="$1"
    local output="$2"
    local message="${3:-Expected output to match pattern '$pattern'}"

    if echo "$output" | grep -qE "$pattern"; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local needle="$2"
    local message="${3:-Expected file '$file' to contain '$needle'}"

    if [[ ! -f "$file" ]]; then
        test_fail "File '$file' does not exist"
        return 1
    fi

    if grep -q "$needle" "$file" 2>/dev/null; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_greater_than() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected $actual to be greater than $expected}"

    if [[ "$actual" -gt "$expected" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_less_than() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected $actual to be less than $expected}"

    if [[ "$actual" -lt "$expected" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Expected value to not be empty}"

    if [[ -n "$value" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local message="${2:-Expected value to be empty}"

    if [[ -z "$value" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' to not exist}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_regex_matches() {
    local pattern="$1"
    local value="$2"
    local message="${3:-Expected '$value' to match regex '$pattern'}"

    if [[ "$value" =~ $pattern ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_symlink() {
    local file="$1"
    local message="${2:-Expected '$file' to be a symlink}"

    if [[ -L "$file" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_file_mode() {
    local file="$1"
    local expected_mode="$2"
    local message="${3:-Expected '$file' to have mode '$expected_mode'}"

    if [[ ! -f "$file" ]]; then
        test_fail "File '$file' does not exist"
        return 1
    fi

    local actual_mode
    actual_mode=$(stat -c '%a' "$file" 2>/dev/null) || actual_mode=$(stat -f '%Lp' "$file" 2>/dev/null)

    if [[ "$actual_mode" == "$expected_mode" ]]; then
        return 0
    else
        test_fail "$message (got: $actual_mode)"
        return 1
    fi
}

# ============================================
# Test Utilities
# ============================================

run_script() {
    local script="$1"
    shift
    local output
    local exit_code

    output=$("$script" "$@" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    echo "$output"
    return $exit_code
}

create_temp_dir() {
    mktemp -d
}

cleanup_temp() {
    local dir="$1"
    [[ -d "$dir" ]] && rm -rf "$dir"
}

# ============================================
# Test Summary
# ============================================

print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Total:  $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ ${#TEST_FAILURES[@]} -gt 0 ]]; then
        echo "Failures:"
        for failure in "${TEST_FAILURES[@]}"; do
            echo -e "  ${RED}✗${NC} $failure"
        done
        echo ""
    fi

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Export functions
export -f test_start test_pass test_fail test_skip
export -f assert_equals assert_not_equals assert_contains assert_not_contains
export -f assert_file_exists assert_file_not_exists assert_dir_exists assert_executable
export -f assert_exit_code assert_json_valid assert_json_field
export -f assert_true assert_false assert_command_exists assert_output_matches
export -f assert_file_contains assert_greater_than assert_less_than
export -f assert_not_empty assert_empty assert_regex_matches
export -f assert_symlink assert_file_mode
export -f run_script create_temp_dir cleanup_temp print_summary
