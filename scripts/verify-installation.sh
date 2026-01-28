#!/bin/bash
# AIDA Installation Verification
# Purpose: Verify all AIDA components are correctly installed and working
# Usage: ./verify-installation.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common library
source "$SCRIPT_DIR/lib/common.sh"

log_section "AIDA Installation Verification"

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Helper function
check() {
    local name="$1"
    local cmd="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if eval "$cmd" > /dev/null 2>&1; then
        log_success "$name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_error "$name"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_optional() {
    local name="$1"
    local cmd="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if eval "$cmd" > /dev/null 2>&1; then
        log_success "$name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_warning "$name (optional)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))  # Don't fail for optional
        return 0
    fi
}

# ============================================
# Core Dependencies
# ============================================
log_section "Core Dependencies"

check "bash available" "command -v bash"
check "jq available" "command -v jq"
check "git available" "command -v git"
check "curl available" "command -v curl"

check_optional "go available" "command -v go"
check_optional "node available" "command -v node"
check_optional "npm available" "command -v npm"
check_optional "python3 available" "command -v python3"

# ============================================
# Optional Tools
# ============================================
log_section "Optional Tools (Enhanced Features)"

check_optional "jj (Jujutsu) available" "command -v jj"
check_optional "grepai available" "command -v grepai"
check_optional "fzf available" "command -v fzf"
check_optional "docker/podman available" "command -v docker || command -v podman"

# ============================================
# Core Scripts
# ============================================
log_section "Core Scripts"

check "quality-gates.sh exists" "[[ -x '$SCRIPT_DIR/quality-gates.sh' ]]"
check "install.sh exists" "[[ -x '$SCRIPT_DIR/install.sh' ]]"
check "lib/common.sh exists" "[[ -f '$SCRIPT_DIR/lib/common.sh' ]]"

# ============================================
# Enhancement Scripts
# ============================================
log_section "Enhancement Scripts"

check "tdd-logger.sh exists" "[[ -x '$SCRIPT_DIR/tdd-logger.sh' ]]"
check "generate-fix-plan.sh exists" "[[ -x '$SCRIPT_DIR/generate-fix-plan.sh' ]]"
check "enhancement-queue.sh exists" "[[ -x '$SCRIPT_DIR/enhancement-queue.sh' ]]"
check "semantic-search.sh exists" "[[ -x '$SCRIPT_DIR/semantic-search.sh' ]]"
check "file-picker.sh exists" "[[ -x '$SCRIPT_DIR/file-picker.sh' ]]"
check "validate-frontend-deps.sh exists" "[[ -x '$SCRIPT_DIR/validate-frontend-deps.sh' ]]"
check "validate-go-module.sh exists" "[[ -x '$SCRIPT_DIR/validate-go-module.sh' ]]"
check "validate-completion.sh exists" "[[ -x '$SCRIPT_DIR/validate-completion.sh' ]]"
check "parse-requirements.sh exists" "[[ -x '$SCRIPT_DIR/parse-requirements.sh' ]]"

# ============================================
# Environment Isolation Scripts
# ============================================
log_section "Environment Isolation"

check "setup-jj.sh exists" "[[ -x '$SCRIPT_DIR/setup-jj.sh' ]]"
check "jj-worktree.sh exists" "[[ -x '$SCRIPT_DIR/jj-worktree.sh' ]]"

# ============================================
# Stop Hooks
# ============================================
log_section "Stop Hooks"

HOOKS_DIR="$PROJECT_ROOT/hooks"
check "hooks.json exists" "[[ -f '$HOOKS_DIR/hooks.json' ]]"
check "ralph-gate.sh exists" "[[ -x '$HOOKS_DIR/stop/ralph-gate.sh' ]]"
check "quality-gate-enforcer.sh exists" "[[ -x '$HOOKS_DIR/stop/quality-gate-enforcer.sh' ]]"
check "subagent-validator.sh exists" "[[ -x '$HOOKS_DIR/stop/subagent-validator.sh' ]]"
check "enhance-gate.sh exists" "[[ -x '$HOOKS_DIR/stop/enhance-gate.sh' ]]"
check "completion-validator.sh exists" "[[ -x '$HOOKS_DIR/subagent-stop/completion-validator.sh' ]]"
check "load-context.sh exists" "[[ -x '$HOOKS_DIR/session-start/load-context.sh' ]]"

# ============================================
# Commands
# ============================================
log_section "Commands"

COMMANDS_DIR="$PROJECT_ROOT/commands"
check "worktree.md exists" "[[ -f '$COMMANDS_DIR/worktree.md' ]]"
check "queue.md exists" "[[ -f '$COMMANDS_DIR/queue.md' ]]"

# ============================================
# Skills
# ============================================
log_section "Skills"

SKILLS_DIR="$PROJECT_ROOT/skills"
check "aida/SKILL.md exists" "[[ -f '$SKILLS_DIR/aida/SKILL.md' ]]"

# ============================================
# Functional Tests
# ============================================
log_section "Functional Tests"

# Test common library loads
check "common.sh loads correctly" "source '$SCRIPT_DIR/lib/common.sh'"

# Test tdd-logger help
check "tdd-logger.sh --help works" "'$SCRIPT_DIR/tdd-logger.sh' help"

# Test enhancement-queue help
check "enhancement-queue.sh help works" "'$SCRIPT_DIR/enhancement-queue.sh' help"

# Test jj-worktree help
check "jj-worktree.sh help works" "'$SCRIPT_DIR/jj-worktree.sh' help"

# Test file-picker help
check "file-picker.sh --help works" "'$SCRIPT_DIR/file-picker.sh' help"

# ============================================
# Summary
# ============================================
log_section "Verification Summary"

echo ""
echo "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo ""

if [[ $FAILED_CHECKS -eq 0 ]]; then
    log_success "All verifications passed!"
    echo ""
    echo "AIDA is ready to use."
    echo ""
    echo "Quick start:"
    echo "  claude"
    echo "  /aida \"Create a web application\""
    exit 0
else
    log_error "$FAILED_CHECKS verification(s) failed"
    echo ""
    echo "Please fix the issues above before using AIDA."
    exit 1
fi
