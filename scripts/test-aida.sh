#!/bin/bash
# AIDA Self-Test Script
# Verifies that the AIDA framework is properly configured and functional
#
# Usage: ./scripts/test-aida.sh [--quick|--full]
#
# Options:
#   --quick    Run quick tests only (no container tests)
#   --full     Run all tests including container tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Test mode
MODE="${1:---quick}"

log_section "AIDA Self-Test"
echo "Mode: $MODE"
echo "Project Root: $PROJECT_ROOT"
echo "Timestamp: $(date -Iseconds)"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=()

# Test helper
run_test() {
    local test_name=$1
    local test_cmd=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
    log_info "Testing: $test_name"

    if eval "$test_cmd" > /tmp/aida_test.log 2>&1; then
        log_success "PASS: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "FAIL: $test_name"
        tail -10 /tmp/aida_test.log
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# ===========================================
# Test 1: Directory Structure
# ===========================================
run_test "Directory structure exists" \
    "[[ -d '$PROJECT_ROOT/agents' && -d '$PROJECT_ROOT/commands' && -d '$PROJECT_ROOT/scripts' ]]"

# ===========================================
# Test 2: Agent Files
# ===========================================
run_test "Agent files exist" \
    "[[ -f '$PROJECT_ROOT/agents/conductor.md' && -f '$PROJECT_ROOT/agents/leader-spec.md' && -f '$PROJECT_ROOT/agents/leader-impl.md' && -f '$PROJECT_ROOT/agents/player.md' ]]"

# ===========================================
# Test 3: Command Files
# ===========================================
run_test "Command files exist" \
    "[[ -f '$PROJECT_ROOT/commands/start.md' && -f '$PROJECT_ROOT/commands/work.md' && -f '$PROJECT_ROOT/commands/pipeline.md' ]]"

# ===========================================
# Test 4: Script Files
# ===========================================
run_test "Script files exist" \
    "[[ -f '$PROJECT_ROOT/scripts/quality-gates.sh' && -f '$PROJECT_ROOT/scripts/checkpoint.sh' && -f '$PROJECT_ROOT/scripts/lib/common.sh' ]]"

# ===========================================
# Test 5: Scripts are executable
# ===========================================
run_test "Scripts are executable" \
    "[[ -x '$PROJECT_ROOT/scripts/quality-gates.sh' && -x '$PROJECT_ROOT/scripts/checkpoint.sh' ]]"

# ===========================================
# Test 6: Common.sh loads without errors
# ===========================================
run_test "common.sh loads successfully" \
    "bash -c 'source $PROJECT_ROOT/scripts/lib/common.sh && echo OK'"

# ===========================================
# Test 7: Container runtime detection
# ===========================================
run_test "Container runtime detected" \
    "bash -c 'source $PROJECT_ROOT/scripts/lib/common.sh && [[ -n \"\$CONTAINER_RUNTIME\" && \"\$CONTAINER_RUNTIME\" != \"none\" ]]'"

# ===========================================
# Test 8: Output directories
# ===========================================
run_test "Output directories exist" \
    "[[ -d '$PROJECT_ROOT/.aida' ]]"

# Create output dirs if missing
for subdir in state specs results checkpoints errors artifacts; do
    ensure_dir "$PROJECT_ROOT/.aida/$subdir"
done

# ===========================================
# Test 9: Agent file minimum size
# ===========================================
run_test "Agent files have content (>100 lines)" \
    "[[ \$(wc -l < '$PROJECT_ROOT/agents/leader-impl.md') -gt 100 ]]"

# ===========================================
# Test 10: Plugin manifest
# ===========================================
run_test "Plugin manifest exists" \
    "[[ -f '$PROJECT_ROOT/.claude-plugin/plugin.json' || -f '$PROJECT_ROOT/plugin.json' || -f '$PROJECT_ROOT/manifest.json' ]]"

# ===========================================
# Full mode: Container tests
# ===========================================
if [[ "$MODE" == "--full" ]]; then
    echo ""
    log_section "Container Tests (Full Mode)"

    # Test: Compose command works
    run_test "Compose command available" \
        "bash -c 'source $PROJECT_ROOT/scripts/lib/common.sh && compose_cmd version'"

    # Test: Can pull test image
    run_test "Can pull alpine image" \
        "bash -c 'source $PROJECT_ROOT/scripts/lib/common.sh && docker pull alpine:latest'"
fi

# ===========================================
# Summary
# ===========================================
echo ""
log_section "Test Summary"
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}${#FAILED_TESTS[@]}${NC}"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    log_error "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    log_error "AIDA SELF-TEST FAILED"
    exit 1
else
    echo ""
    log_success "ALL AIDA SELF-TESTS PASSED"
    echo ""
    echo "AIDA is ready for use."
    echo ""
    echo "Quick start:"
    echo "  /aida:start \"Create a todo app with user authentication\""
    exit 0
fi
