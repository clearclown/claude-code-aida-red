#!/bin/bash
# Tests for lib/common.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Create temp directory for tests
TEMP_DIR=$(create_temp_dir)
export CLAUDE_PROJECT_DIR="$TEMP_DIR"

echo "========================================"
echo "Testing: lib/common.sh"
echo "========================================"
echo ""

# ============================================
# Test: Logging functions exist
# ============================================
test_start "Logging functions exist"
if type log_info &>/dev/null && \
   type log_success &>/dev/null && \
   type log_warning &>/dev/null && \
   type log_error &>/dev/null; then
    test_pass
fi

# ============================================
# Test: log_info outputs correctly
# ============================================
test_start "log_info outputs correctly"
output=$(log_info "test message" 2>&1)
if assert_contains "$output" "INFO" && \
   assert_contains "$output" "test message"; then
    test_pass
fi

# ============================================
# Test: log_section outputs correctly
# ============================================
test_start "log_section outputs correctly"
output=$(log_section "Test Section" 2>&1)
if assert_contains "$output" "Test Section"; then
    test_pass
fi

# ============================================
# Test: get_aida_root returns correct path
# ============================================
test_start "get_aida_root returns correct path"
root=$(get_aida_root)
if assert_equals "$TEMP_DIR" "$root"; then
    test_pass
fi

# ============================================
# Test: init_aida_dirs creates directories
# ============================================
test_start "init_aida_dirs creates directories"
init_aida_dirs
if assert_dir_exists "$TEMP_DIR/.aida/state" && \
   assert_dir_exists "$TEMP_DIR/.aida/logs" && \
   assert_dir_exists "$TEMP_DIR/.aida/tdd-evidence"; then
    test_pass
fi

# ============================================
# Test: output_approve generates valid JSON
# ============================================
test_start "output_approve generates valid JSON"
output=$(output_approve "Test reason")
if assert_json_valid "$output" && \
   assert_json_field "$output" '.decision' "null"; then
    test_pass
fi

# ============================================
# Test: output_block generates valid JSON
# ============================================
test_start "output_block generates valid JSON"
output=$(output_block "Test block reason")
if assert_json_valid "$output" && \
   assert_json_field "$output" '.decision' "block"; then
    test_pass
fi

# ============================================
# Test: output_allow with systemMessage
# ============================================
test_start "output_allow includes systemMessage when provided"
output=$(output_allow "Allow reason" "Allow system message")
if assert_json_valid "$output" && \
   assert_json_field "$output" '.systemMessage' "Allow system message"; then
    test_pass
fi

# ============================================
# Test: output_block with systemMessage
# ============================================
test_start "output_block includes systemMessage when provided"
output=$(output_block "Block reason" "System message here")
if assert_json_valid "$output" && \
   assert_json_field "$output" '.systemMessage' "System message here"; then
    test_pass
fi

# ============================================
# Test: iso_timestamp returns ISO format
# ============================================
test_start "iso_timestamp returns ISO format"
ts=$(iso_timestamp)
if [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
    test_pass
else
    test_fail "Expected ISO format, got: $ts"
fi

# ============================================
# Test: unix_timestamp returns number
# ============================================
test_start "unix_timestamp returns number"
ts=$(unix_timestamp)
if [[ "$ts" =~ ^[0-9]+$ ]]; then
    test_pass
else
    test_fail "Expected number, got: $ts"
fi

# ============================================
# Test: validate_project_name accepts valid names
# ============================================
test_start "validate_project_name accepts valid names"
if validate_project_name "myproject" 2>/dev/null && \
   validate_project_name "my-project" 2>/dev/null && \
   validate_project_name "my_project123" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: validate_project_name rejects invalid names
# ============================================
test_start "validate_project_name rejects invalid names"
if ! validate_project_name "" 2>/dev/null && \
   ! validate_project_name "123start" 2>/dev/null && \
   ! validate_project_name "has spaces" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: check_file_exists works correctly
# ============================================
test_start "check_file_exists works correctly"
echo "test content" > "$TEMP_DIR/test_file.txt"
if check_file_exists "$TEMP_DIR/test_file.txt" 2>/dev/null && \
   ! check_file_exists "$TEMP_DIR/nonexistent.txt" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: check_dir_exists works correctly
# ============================================
test_start "check_dir_exists works correctly"
echo "file" > "$TEMP_DIR/.aida/state/test.txt"
if check_dir_exists "$TEMP_DIR/.aida/state" 2>/dev/null && \
   ! check_dir_exists "$TEMP_DIR/nonexistent_dir" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: Session management functions
# ============================================
test_start "Session management functions work"
# Create a session file
mkdir -p "$TEMP_DIR/.aida/state"
cat << 'EOF' > "$TEMP_DIR/.aida/state/session.json"
{
  "project_name": "test-project",
  "current_phase": "IMPL_PHASE",
  "iteration": 1
}
EOF

if is_session_active && \
   [[ "$(get_session_value 'project_name')" == "test-project" ]] && \
   [[ "$(get_session_value 'current_phase')" == "IMPL_PHASE" ]]; then
    test_pass
fi

# ============================================
# Test: log_debug only outputs when DEBUG=true
# ============================================
test_start "log_debug only outputs when DEBUG=true"
output=$(DEBUG=false log_debug "should not appear" 2>&1)
output_with_debug=$(DEBUG=true log_debug "should appear" 2>&1)
if [[ -z "$output" ]] && assert_contains "$output_with_debug" "DEBUG"; then
    test_pass
fi

# ============================================
# Test: require_command finds existing commands
# ============================================
test_start "require_command finds existing commands"
if require_command "bash" 2>/dev/null && \
   require_command "jq" 2>/dev/null; then
    test_pass
fi

# ============================================
# Test: require_command fails for missing commands
# ============================================
test_start "require_command fails for missing commands"
if ! require_command "nonexistent_command_xyz" 2>/dev/null; then
    test_pass
else
    test_fail "Should fail for nonexistent command"
fi

# ============================================
# Test: ensure_json_file creates file
# ============================================
test_start "ensure_json_file creates file with default content"
JSON_FILE="$TEMP_DIR/test_ensure.json"
rm -f "$JSON_FILE"
ensure_json_file "$JSON_FILE" '{"test": true}'
if [[ -f "$JSON_FILE" ]] && jq -e '.test' "$JSON_FILE" >/dev/null 2>&1; then
    test_pass
else
    test_fail "File not created or invalid JSON"
fi

# ============================================
# Test: safe_jq_update modifies file atomically
# ============================================
test_start "safe_jq_update modifies file atomically"
echo '{"count": 1}' > "$TEMP_DIR/update_test.json"
if safe_jq_update "$TEMP_DIR/update_test.json" '.count = 2'; then
    new_count=$(jq -r '.count' "$TEMP_DIR/update_test.json")
    if [[ "$new_count" == "2" ]]; then
        test_pass
    else
        test_fail "Expected count=2, got $new_count"
    fi
else
    test_fail "safe_jq_update failed"
fi

# ============================================
# Test: ensure_dir creates directory
# ============================================
test_start "ensure_dir creates directory"
NEW_DIR="$TEMP_DIR/new_test_dir/nested"
rm -rf "$TEMP_DIR/new_test_dir"
ensure_dir "$NEW_DIR"
if [[ -d "$NEW_DIR" ]]; then
    test_pass
else
    test_fail "Directory not created"
fi

# ============================================
# Test: backup_file creates backup
# ============================================
test_start "backup_file creates backup"
BACKUP_DIR="$TEMP_DIR/backups"
echo "original content" > "$TEMP_DIR/to_backup.txt"
backup_file "$TEMP_DIR/to_backup.txt" "$BACKUP_DIR"
backup_count=$(ls "$BACKUP_DIR" 2>/dev/null | wc -l)
if [[ $backup_count -gt 0 ]]; then
    test_pass
else
    test_fail "No backup created"
fi

# ============================================
# Test: count_go_tests counts Go test functions
# ============================================
test_start "count_go_tests counts Go test functions"
mkdir -p "$TEMP_DIR/go_test"
cat << 'GOEOF' > "$TEMP_DIR/go_test/example_test.go"
package example

func TestExample1(t *testing.T) {}
func TestExample2(t *testing.T) {}
func TestExample3(t *testing.T) {}
GOEOF
count=$(count_go_tests "$TEMP_DIR/go_test")
if [[ "$count" -eq 3 ]]; then
    test_pass
else
    test_fail "Expected 3, got $count"
fi

# ============================================
# Test: count_js_tests counts JS test cases
# ============================================
test_start "count_js_tests counts JS test cases"
mkdir -p "$TEMP_DIR/js_test"
cat << 'JSEOF' > "$TEMP_DIR/js_test/example.test.ts"
describe('Example', () => {
  it('should work', () => {});
  test('should also work', () => {});
  it('another test', () => {});
});
JSEOF
count=$(count_js_tests "$TEMP_DIR/js_test")
if [[ "$count" -eq 3 ]]; then
    test_pass
else
    test_fail "Expected 3, got $count"
fi

# ============================================
# Test: count_files counts matching files
# ============================================
test_start "count_files counts matching files"
mkdir -p "$TEMP_DIR/count_test"
touch "$TEMP_DIR/count_test/file1.txt"
touch "$TEMP_DIR/count_test/file2.txt"
touch "$TEMP_DIR/count_test/file3.json"
count=$(count_files "$TEMP_DIR/count_test" "*.txt")
if [[ "$count" -eq 2 ]]; then
    test_pass
else
    test_fail "Expected 2, got $count"
fi

# ============================================
# Test: check_min_files validates minimum
# ============================================
test_start "check_min_files validates minimum count"
# Should pass with 2 txt files, min 2
if check_min_files "$TEMP_DIR/count_test" "*.txt" 2 "txt files" 2>/dev/null; then
    test_pass
else
    test_fail "Should pass with min 2"
fi

# ============================================
# Test: check_min_files fails below minimum
# ============================================
test_start "check_min_files fails below minimum"
# Should fail with 2 txt files, min 5
if ! check_min_files "$TEMP_DIR/count_test" "*.txt" 5 "txt files" 2>/dev/null; then
    test_pass
else
    test_fail "Should fail with min 5"
fi

# ============================================
# Test: get_session_value returns default
# ============================================
test_start "get_session_value returns default for missing key"
val=$(get_session_value 'nonexistent_key' 'default_value')
if [[ "$val" == "default_value" ]]; then
    test_pass
else
    test_fail "Expected 'default_value', got '$val'"
fi

# ============================================
# Test: log_warn alias works
# ============================================
test_start "log_warn alias works"
output=$(log_warn "test warning" 2>&1)
if assert_contains "$output" "WARN"; then
    test_pass
fi

# ============================================
# Test: run_gate executes commands
# ============================================
test_start "run_gate executes commands"
if run_gate 1 "Test Gate" "true" 2>/dev/null; then
    test_pass
else
    test_fail "run_gate should succeed for true command"
fi

# Cleanup
cleanup_temp "$TEMP_DIR"

print_summary
