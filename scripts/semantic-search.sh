#!/bin/bash
# AIDA Semantic Search (grepai wrapper)
# Purpose: AI-powered semantic search for codebase exploration
# Usage: ./semantic-search.sh <query> [options]
#
# This script uses grepai to perform semantic searches,
# dramatically reducing token usage (up to 80% reduction).
#
# IMPORTANT: grepai is REQUIRED for AIDA. Install with:
#   go install github.com/yoanbernabeu/grepai@latest

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Use CLAUDE_PROJECT_DIR if available
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
fi

# ============================================
# Check grepai installation (using require_command from common.sh)
# ============================================
check_grepai() {
    if ! require_command grepai "go install github.com/yoanbernabeu/grepai@latest (or cargo install grepai)"; then
        log_error "grepai is REQUIRED for AIDA semantic search"
        log_error "Without it, codebase exploration is inefficient (80% token overhead)"
        exit 1
    fi
}

# ============================================
# Setup cache directory (using ensure_dir from common.sh)
# ============================================
CACHE_DIR="$PROJECT_ROOT/.aida/search-cache"
ensure_dir "$CACHE_DIR"

# ============================================
# Parse arguments
# ============================================
QUERY="${1:-}"
SEARCH_PATH="${2:-$PROJECT_ROOT}"
MAX_RESULTS="${3:-10}"

if [[ -z "$QUERY" ]]; then
    cat << 'EOF'
AIDA Semantic Search

Usage:
  ./semantic-search.sh <query> [path] [max_results]

Arguments:
  query        Search query (natural language)
  path         Path to search (default: project root)
  max_results  Maximum results (default: 10)

Examples:
  ./semantic-search.sh "authentication logic"
  ./semantic-search.sh "error handling" ./src 5
  ./semantic-search.sh "database connection pooling"

Features:
  - Semantic understanding of code
  - 80% token reduction vs naive search
  - Results cached for repeated queries
  - Supports natural language queries

EOF
    exit 0
fi

check_grepai

# ============================================
# Check cache
# ============================================
CACHE_KEY=$(echo "$QUERY$SEARCH_PATH$MAX_RESULTS" | md5sum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY.json"

if [[ -f "$CACHE_FILE" ]]; then
    # Check if cache is less than 1 hour old
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [[ $CACHE_AGE -lt 3600 ]]; then
        echo "=== Cached Result ($(($CACHE_AGE / 60))m old) ===" >&2
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ============================================
# Run semantic search
# ============================================
echo "=== Semantic Search ===" >&2
echo "Query: $QUERY" >&2
echo "Path: $SEARCH_PATH" >&2
echo "" >&2

# Run grepai
RESULT=$(grepai "$QUERY" "$SEARCH_PATH" --limit "$MAX_RESULTS" 2>&1) || {
    echo "grepai search failed" >&2
    exit 1
}

# Cache result
echo "$RESULT" > "$CACHE_FILE"

# Output result
echo "$RESULT"

# ============================================
# Token efficiency report
# ============================================
RESULT_LINES=$(echo "$RESULT" | wc -l)
TOTAL_FILES=$(find "$SEARCH_PATH" -type f \( -name "*.go" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null | wc -l)

echo "" >&2
echo "=== Efficiency ===" >&2
echo "Files scanned semantically: $TOTAL_FILES" >&2
echo "Relevant results: $RESULT_LINES lines" >&2
echo "Estimated token savings: ~$((TOTAL_FILES * 100 - RESULT_LINES * 50)) tokens" >&2
