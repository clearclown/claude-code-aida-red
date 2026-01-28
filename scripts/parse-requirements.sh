#!/bin/bash
# AIDA Requirements Parser
# Purpose: Parse requirement documents into AIDA tasks (#22)
# Usage: ./parse-requirements.sh <requirements_file> [options]
#
# Supported formats:
# - Markdown (.md)
# - YAML (.yaml, .yml)
# - Plain text (.txt)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

REQUIREMENTS_FILE="${1:-}"
OUTPUT_DIR="$PROJECT_ROOT/.aida/parsed-requirements"
OUTPUT_FORMAT="${2:-json}"

if [[ -z "$REQUIREMENTS_FILE" ]]; then
    cat << 'EOF'
AIDA Requirements Parser

Usage:
  ./parse-requirements.sh <requirements_file> [output_format]

Arguments:
  requirements_file  Path to requirements document (md, yaml, txt)
  output_format      Output format: json (default), yaml, tasks

Supported Formats:
  - Markdown (.md)   : Headers become tasks, lists become subtasks
  - YAML (.yaml)     : Structured requirements with priorities
  - Plain text (.txt): Line-by-line requirements

Examples:
  ./parse-requirements.sh docs/requirements.md
  ./parse-requirements.sh docs/spec.yaml yaml
  ./parse-requirements.sh docs/features.txt tasks

Output:
  Parsed requirements are saved to .aida/parsed-requirements/

EOF
    exit 0
fi

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
    echo "Error: File not found: $REQUIREMENTS_FILE" >&2
    exit 1
fi

ensure_dir "$OUTPUT_DIR"

# ============================================
# Detect file type
# ============================================
detect_file_type() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        md|markdown) echo "markdown" ;;
        yaml|yml) echo "yaml" ;;
        txt|text) echo "text" ;;
        *) echo "unknown" ;;
    esac
}

# ============================================
# Parse Markdown requirements
# ============================================
parse_markdown() {
    local file="$1"
    local tasks=()
    local current_section=""
    local task_id=0

    echo "Parsing Markdown requirements..." >&2

    while IFS= read -r line; do
        # Headers become main tasks
        if [[ "$line" =~ ^#[[:space:]]+(.*) ]]; then
            current_section="${BASH_REMATCH[1]}"
            task_id=$((task_id + 1))
            tasks+=("{\"id\": $task_id, \"type\": \"epic\", \"title\": \"$current_section\", \"subtasks\": []}")
        elif [[ "$line" =~ ^##[[:space:]]+(.*) ]]; then
            current_section="${BASH_REMATCH[1]}"
            task_id=$((task_id + 1))
            tasks+=("{\"id\": $task_id, \"type\": \"feature\", \"title\": \"$current_section\", \"subtasks\": []}")
        elif [[ "$line" =~ ^###[[:space:]]+(.*) ]]; then
            task_id=$((task_id + 1))
            tasks+=("{\"id\": $task_id, \"type\": \"task\", \"title\": \"${BASH_REMATCH[1]}\", \"parent\": \"$current_section\"}")
        # List items become subtasks
        elif [[ "$line" =~ ^[[:space:]]*[-*][[:space:]]+(.*) ]]; then
            task_id=$((task_id + 1))
            local item="${BASH_REMATCH[1]:-}"
            # Check for checkbox
            if [[ "$item" =~ ^\[([[:space:]]|x|X)\][[:space:]]+(.*) ]]; then
                local done="false"
                local checkbox_mark="${BASH_REMATCH[1]:-}"
                local checkbox_text="${BASH_REMATCH[2]:-$item}"
                [[ "$checkbox_mark" =~ [xX] ]] && done="true"
                item="$checkbox_text"
                tasks+=("{\"id\": $task_id, \"type\": \"subtask\", \"title\": \"$item\", \"done\": $done}")
            else
                tasks+=("{\"id\": $task_id, \"type\": \"subtask\", \"title\": \"$item\"}")
            fi
        fi
    done < "$file"

    # Output as JSON array
    echo "["
    local first=true
    for task in "${tasks[@]}"; do
        [[ "$first" != "true" ]] && echo ","
        echo "  $task"
        first=false
    done
    echo "]"
}

# ============================================
# Parse YAML requirements
# ============================================
parse_yaml() {
    local file="$1"

    echo "Parsing YAML requirements..." >&2

    if ! command -v yq &>/dev/null; then
        # Fallback: use jq if yq not available
        if command -v python3 &>/dev/null; then
            python3 -c "
import yaml
import json
import sys

with open('$file', 'r') as f:
    data = yaml.safe_load(f)
    print(json.dumps(data, indent=2))
"
        else
            echo "Error: yq or python3 with PyYAML required for YAML parsing" >&2
            exit 1
        fi
    else
        yq -o=json '.' "$file"
    fi
}

# ============================================
# Parse plain text requirements
# ============================================
parse_text() {
    local file="$1"
    local tasks=()
    local task_id=0

    echo "Parsing text requirements..." >&2

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        task_id=$((task_id + 1))

        # Check for priority markers
        local priority="medium"
        if [[ "$line" =~ ^\[P1\]|^CRITICAL|^HIGH ]]; then
            priority="high"
        elif [[ "$line" =~ ^\[P3\]|^LOW ]]; then
            priority="low"
        fi

        # Remove priority markers
        line=$(echo "$line" | sed -E 's/^\[(P[0-9])\][[:space:]]*//' | sed -E 's/^(CRITICAL|HIGH|LOW)[[:space:]]*//')

        tasks+=("{\"id\": $task_id, \"title\": \"$line\", \"priority\": \"$priority\"}")
    done < "$file"

    echo "["
    local first=true
    for task in "${tasks[@]}"; do
        [[ "$first" != "true" ]] && echo ","
        echo "  $task"
        first=false
    done
    echo "]"
}

# ============================================
# Convert to AIDA task format
# ============================================
convert_to_aida_tasks() {
    local json_input="$1"

    echo "$json_input" | jq '
        [.[] | {
            task_id: .id,
            title: .title,
            type: (.type // "task"),
            priority: (.priority // "medium"),
            status: (if .done == true then "completed" else "pending" end),
            tdd_required: true,
            tests_first: true
        }]
    '
}

# ============================================
# Main
# ============================================
FILE_TYPE=$(detect_file_type "$REQUIREMENTS_FILE")
BASENAME=$(basename "$REQUIREMENTS_FILE" | sed 's/\.[^.]*$//')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}-${TIMESTAMP}.json"

echo "=== AIDA Requirements Parser ===" >&2
echo "Input: $REQUIREMENTS_FILE" >&2
echo "Type: $FILE_TYPE" >&2
echo "" >&2

case "$FILE_TYPE" in
    markdown)
        PARSED=$(parse_markdown "$REQUIREMENTS_FILE")
        ;;
    yaml)
        PARSED=$(parse_yaml "$REQUIREMENTS_FILE")
        ;;
    text)
        PARSED=$(parse_text "$REQUIREMENTS_FILE")
        ;;
    *)
        echo "Error: Unsupported file type: $FILE_TYPE" >&2
        exit 1
        ;;
esac

# Convert and save based on output format
case "$OUTPUT_FORMAT" in
    json)
        echo "$PARSED" | jq '.' > "$OUTPUT_FILE"
        ;;
    yaml)
        OUTPUT_FILE="${OUTPUT_FILE%.json}.yaml"
        echo "$PARSED" | yq -P '.' > "$OUTPUT_FILE" 2>/dev/null || \
            echo "$PARSED" > "$OUTPUT_FILE"
        ;;
    tasks)
        AIDA_TASKS=$(convert_to_aida_tasks "$PARSED")
        echo "$AIDA_TASKS" | jq '.' > "$OUTPUT_FILE"
        ;;
esac

echo "Output: $OUTPUT_FILE" >&2
echo "" >&2

# Summary
TASK_COUNT=$(echo "$PARSED" | jq 'length' 2>/dev/null || echo "0")
echo "Parsed $TASK_COUNT requirements/tasks" >&2

# Output the parsed content
cat "$OUTPUT_FILE"
