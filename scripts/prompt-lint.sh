#!/bin/bash
# AIDA Prompt Linter
# Purpose: Lint and validate prompt files (agents, skills, commands) (#80)
# Usage: ./prompt-lint.sh [command] [files...]
#
# Commands:
#   lint       - Lint specified files or all prompts
#   test       - Run prompt tests
#   version    - Show/update prompt versions
#   eval       - Evaluate prompt quality
#   report     - Generate lint report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# Source common library
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    log_info() { echo "[INFO] $*" >&2; }
    log_success() { echo "[SUCCESS] $*" >&2; }
    log_warning() { echo "[WARNING] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

COMMAND="${1:-lint}"
shift || true

# State
AIDA_DIR="$PROJECT_ROOT/.aida"
LINT_DIR="$AIDA_DIR/lint-results"
ensure_dir "$LINT_DIR"

# ============================================
# Prompt Discovery
# ============================================

find_prompts() {
    local search_paths=(
        "$PROJECT_ROOT/agents"
        "$PROJECT_ROOT/skills"
        "$PROJECT_ROOT/commands"
    )

    for dir in "${search_paths[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -name "*.md" -type f 2>/dev/null
        fi
    done
}

# ============================================
# Lint Rules
# ============================================

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a INFO=()

add_error() { ERRORS+=("$1"); }
add_warning() { WARNINGS+=("$1"); }
add_info() { INFO+=("$1"); }

reset_issues() {
    ERRORS=()
    WARNINGS=()
    INFO=()
}

# Rule: Check for required sections in agent files
check_required_sections() {
    local file="$1"
    local filename=$(basename "$file")
    local dir=$(basename "$(dirname "$file")")

    if [[ "$dir" == "agents" ]]; then
        # Agents should have certain sections
        if ! grep -q "^#" "$file"; then
            add_error "Missing header in agent file: $filename"
        fi

        if ! grep -qi "purpose\|overview\|role" "$file"; then
            add_warning "Missing purpose/overview section: $filename"
        fi

        if ! grep -qi "instruction\|protocol\|workflow" "$file"; then
            add_warning "Missing instructions section: $filename"
        fi
    fi
}

# Rule: Check for YAML frontmatter
check_frontmatter() {
    local file="$1"
    local filename=$(basename "$file")

    if head -1 "$file" | grep -q "^---$"; then
        # Has frontmatter, validate it
        local fm=$(sed -n '/^---$/,/^---$/p' "$file" | head -n -1 | tail -n +2)

        if [[ -z "$fm" ]]; then
            add_warning "Empty frontmatter: $filename"
        fi

        # Check for version if it's a versioned prompt
        if echo "$fm" | grep -qi "version"; then
            local version=$(echo "$fm" | grep -i "version" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"')
            # Accept both semver (X.Y.Z) and protocol version (X.Y)
            if [[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                add_info "Version: $version - $filename"
            else
                add_warning "Invalid version format (should be X.Y or X.Y.Z): $filename - got: $version"
            fi
        fi
    else
        add_info "No frontmatter: $filename (consider adding metadata)"
    fi
}

# Rule: Check for forbidden patterns
check_forbidden_patterns() {
    local file="$1"
    local filename=$(basename "$file")

    # Patterns that suggest low-quality prompts
    local forbidden_patterns=(
        "TODO:"
        "FIXME:"
        "XXX:"
        "HACK:"
        "you must always"
        "never ever"
        "under any circumstances"
    )

    for pattern in "${forbidden_patterns[@]}"; do
        if grep -qi "$pattern" "$file"; then
            add_warning "Contains '$pattern': $filename"
        fi
    done

    # Check for extremely long lines (over 200 chars)
    local long_lines=$(awk 'length > 200 {print NR}' "$file" | head -5)
    if [[ -n "$long_lines" ]]; then
        add_warning "Long lines (>200 chars) at lines $long_lines: $filename"
    fi
}

# Rule: Check for balanced markdown
check_markdown_structure() {
    local file="$1"
    local filename=$(basename "$file")

    # Check for unclosed code blocks
    local backticks=$(grep -c '```' "$file" || true)
    if [[ $((backticks % 2)) -ne 0 ]]; then
        add_error "Unclosed code block: $filename"
    fi

    # Check for empty headers
    if grep -E "^#+[[:space:]]*$" "$file"; then
        add_warning "Empty header: $filename"
    fi

    # Check for consecutive blank lines (more than 2)
    if awk '/^$/{blank++; if(blank>2) exit 1} /^./{blank=0}' "$file"; then
        : # OK
    else
        add_info "Multiple consecutive blank lines: $filename"
    fi
}

# Rule: Check for TDD-related content in player files
check_tdd_compliance() {
    local file="$1"
    local filename=$(basename "$file")

    if [[ "$filename" == *"player"* ]]; then
        if ! grep -qi "TDD\|test.*first\|red.*green\|test-driven" "$file"; then
            add_warning "Player file missing TDD reference: $filename"
        fi
    fi
}

# Rule: Check prompt complexity
check_complexity() {
    local file="$1"
    local filename=$(basename "$file")

    local word_count=$(wc -w < "$file")
    local line_count=$(wc -l < "$file")

    if [[ $word_count -gt 5000 ]]; then
        add_warning "Very long prompt ($word_count words): $filename - consider splitting"
    elif [[ $word_count -lt 50 ]]; then
        add_info "Very short prompt ($word_count words): $filename"
    fi

    if [[ $line_count -gt 500 ]]; then
        add_warning "Very long prompt ($line_count lines): $filename"
    fi
}

# ============================================
# Lint Single File
# ============================================

lint_file() {
    local file="$1"
    local filename=$(basename "$file")

    reset_issues

    if [[ ! -f "$file" ]]; then
        add_error "File not found: $file"
        return 1
    fi

    # Run all checks
    check_required_sections "$file"
    check_frontmatter "$file"
    check_forbidden_patterns "$file"
    check_markdown_structure "$file"
    check_tdd_compliance "$file"
    check_complexity "$file"

    # Output results
    local has_issues=false

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        has_issues=true
        for err in "${ERRORS[@]}"; do
            echo "[ERROR] $err"
        done
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        has_issues=true
        for warn in "${WARNINGS[@]}"; do
            echo "[WARN]  $warn"
        done
    fi

    if [[ "${VERBOSE:-}" == "true" ]] && [[ ${#INFO[@]} -gt 0 ]]; then
        for info in "${INFO[@]}"; do
            echo "[INFO]  $info"
        done
    fi

    if [[ "$has_issues" != "true" ]]; then
        echo "[OK]    $filename"
    fi

    [[ ${#ERRORS[@]} -eq 0 ]]
}

# ============================================
# Lint All or Specified Files
# ============================================

lint_all() {
    local files=("$@")
    local total=0
    local passed=0
    local failed=0
    local total_errors=0
    local total_warnings=0

    if [[ ${#files[@]} -eq 0 ]]; then
        # Lint all prompts
        while IFS= read -r file; do
            files+=("$file")
        done < <(find_prompts)
    fi

    echo "=== AIDA Prompt Linter ==="
    echo ""

    for file in "${files[@]}"; do
        total=$((total + 1))

        if lint_file "$file"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi

        total_errors=$((total_errors + ${#ERRORS[@]}))
        total_warnings=$((total_warnings + ${#WARNINGS[@]}))
    done

    echo ""
    echo "=== Summary ==="
    echo "Files:    $total"
    echo "Passed:   $passed"
    echo "Failed:   $failed"
    echo "Errors:   $total_errors"
    echo "Warnings: $total_warnings"

    # Save report
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cat << EOF > "$LINT_DIR/lint-$timestamp.json"
{
  "timestamp": "$(date -Iseconds)",
  "files_checked": $total,
  "passed": $passed,
  "failed": $failed,
  "total_errors": $total_errors,
  "total_warnings": $total_warnings
}
EOF

    [[ $failed -eq 0 ]]
}

# ============================================
# Prompt Testing
# ============================================

test_prompts() {
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        while IFS= read -r file; do
            files+=("$file")
        done < <(find_prompts)
    fi

    echo "=== AIDA Prompt Tests ==="
    echo ""

    local passed=0
    local failed=0

    for file in "${files[@]}"; do
        local filename=$(basename "$file")

        # Test 1: File is readable
        if [[ -r "$file" ]]; then
            echo "[PASS] Readable: $filename"
            passed=$((passed + 1))
        else
            echo "[FAIL] Not readable: $filename"
            failed=$((failed + 1))
            continue
        fi

        # Test 2: File is not empty
        if [[ -s "$file" ]]; then
            echo "[PASS] Not empty: $filename"
            passed=$((passed + 1))
        else
            echo "[FAIL] Empty file: $filename"
            failed=$((failed + 1))
        fi

        # Test 3: Valid UTF-8
        if file "$file" | grep -qi "utf-8\|ascii\|text"; then
            echo "[PASS] Valid encoding: $filename"
            passed=$((passed + 1))
        else
            echo "[FAIL] Invalid encoding: $filename"
            failed=$((failed + 1))
        fi

        # Test 4: No binary content
        if ! grep -Pq '[^\x00-\x7F\xC0-\xFF]' "$file" 2>/dev/null; then
            echo "[PASS] No binary: $filename"
            passed=$((passed + 1))
        fi

        echo ""
    done

    echo "=== Test Summary ==="
    echo "Passed: $passed"
    echo "Failed: $failed"

    [[ $failed -eq 0 ]]
}

# ============================================
# Version Management
# ============================================

show_versions() {
    echo "=== Prompt Versions ==="
    echo ""

    while IFS= read -r file; do
        local filename=$(basename "$file")
        local dir=$(basename "$(dirname "$file")")

        if head -1 "$file" | grep -q "^---$"; then
            local version=$(sed -n '/^---$/,/^---$/p' "$file" | grep -i "version" | head -1 | sed 's/.*:[[:space:]]*//')
            if [[ -n "$version" ]]; then
                printf "%-30s v%s  (%s)\n" "$filename" "$version" "$dir"
            else
                printf "%-30s (no version)  (%s)\n" "$filename" "$dir"
            fi
        else
            printf "%-30s (no frontmatter)  (%s)\n" "$filename" "$dir"
        fi
    done < <(find_prompts)
}

# ============================================
# Quality Evaluation
# ============================================

evaluate_quality() {
    local file="${1:-}"

    if [[ -z "$file" ]]; then
        echo "Usage: ./prompt-lint.sh eval <file>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    local filename=$(basename "$file")
    local word_count=$(wc -w < "$file")
    local line_count=$(wc -l < "$file")
    local char_count=$(wc -c < "$file")

    # Calculate scores
    local structure_score=100
    local clarity_score=100
    local completeness_score=100

    # Structure: frontmatter, headers
    if ! head -1 "$file" | grep -q "^---$"; then
        structure_score=$((structure_score - 20))
    fi
    if ! grep -q "^#" "$file"; then
        structure_score=$((structure_score - 30))
    fi

    # Clarity: no forbidden patterns, reasonable length
    if grep -qi "TODO\|FIXME" "$file"; then
        clarity_score=$((clarity_score - 10))
    fi
    if [[ $word_count -gt 5000 ]]; then
        clarity_score=$((clarity_score - 20))
    fi

    # Completeness: has purpose, instructions
    if ! grep -qi "purpose\|overview\|goal" "$file"; then
        completeness_score=$((completeness_score - 25))
    fi
    if ! grep -qi "instruction\|step\|protocol" "$file"; then
        completeness_score=$((completeness_score - 25))
    fi

    local overall_score=$(( (structure_score + clarity_score + completeness_score) / 3 ))

    cat << EOF
=== Prompt Quality Evaluation ===

File: $filename

Metrics:
  Words:      $word_count
  Lines:      $line_count
  Characters: $char_count

Scores:
  Structure:    $structure_score/100
  Clarity:      $clarity_score/100
  Completeness: $completeness_score/100
  ---
  Overall:      $overall_score/100

Grade: $(
    if [[ $overall_score -ge 90 ]]; then echo "A (Excellent)"
    elif [[ $overall_score -ge 80 ]]; then echo "B (Good)"
    elif [[ $overall_score -ge 70 ]]; then echo "C (Fair)"
    elif [[ $overall_score -ge 60 ]]; then echo "D (Needs Work)"
    else echo "F (Poor)"
    fi
)
EOF
}

# ============================================
# Generate Report
# ============================================

generate_report() {
    local timestamp=$(date -Iseconds)
    local report_file="$LINT_DIR/report-$(date +%Y%m%d-%H%M%S).json"

    echo "Generating comprehensive lint report..."

    local prompts=()
    while IFS= read -r file; do
        prompts+=("$file")
    done < <(find_prompts)

    local results=()
    for file in "${prompts[@]}"; do
        reset_issues
        lint_file "$file" >/dev/null 2>&1 || true

        local filename=$(basename "$file")
        results+=("{\"file\": \"$filename\", \"errors\": ${#ERRORS[@]}, \"warnings\": ${#WARNINGS[@]}}")
    done

    cat << EOF > "$report_file"
{
  "generated_at": "$timestamp",
  "total_files": ${#prompts[@]},
  "results": [
    $(IFS=,; echo "${results[*]}")
  ]
}
EOF

    echo "Report saved: $report_file"
    cat "$report_file" | jq '.'
}

# ============================================
# Main
# ============================================

case "$COMMAND" in
    lint)
        lint_all "$@"
        ;;
    test)
        test_prompts "$@"
        ;;
    version|versions)
        show_versions
        ;;
    eval)
        evaluate_quality "$@"
        ;;
    report)
        generate_report
        ;;
    help|--help|-h)
        cat << 'EOF'
AIDA Prompt Linter - Prompt as Code Quality Tool

Usage:
  ./prompt-lint.sh [command] [files...]

Commands:
  lint [files]   Lint specified files or all prompts (default)
  test [files]   Run prompt tests (encoding, structure)
  version        Show prompt versions
  eval <file>    Evaluate prompt quality score
  report         Generate comprehensive JSON report
  help           Show this help

Lint Rules:
  - Required sections (agents need purpose, instructions)
  - Valid frontmatter with semver version
  - No forbidden patterns (TODO, FIXME, "never ever")
  - Balanced markdown (code blocks, headers)
  - TDD compliance for player files
  - Complexity checks (word count, line count)

Examples:
  ./prompt-lint.sh lint
  ./prompt-lint.sh lint agents/player.md
  ./prompt-lint.sh test
  ./prompt-lint.sh eval agents/conductor.md
  ./prompt-lint.sh version
  VERBOSE=true ./prompt-lint.sh lint

Reports:
  Saved to: .aida/lint-results/

EOF
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run './prompt-lint.sh help' for usage" >&2
        exit 1
        ;;
esac
