#!/bin/bash
# AIDA Test Runner
# Purpose: Run all AIDA tests
# Usage: ./run-all-tests.sh [pattern]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo " AIDA Test Suite"
echo -e "========================================${NC}"
echo ""

PATTERN="${1:-test-*.sh}"
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

for test_file in "$SCRIPT_DIR"/$PATTERN; do
    [[ -f "$test_file" ]] || continue
    [[ "$(basename "$test_file")" == "test-framework.sh" ]] && continue
    [[ "$(basename "$test_file")" == "run-all-tests.sh" ]] && continue

    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    test_name=$(basename "$test_file" .sh)

    echo -e "${BLUE}Running: $test_name${NC}"
    echo "----------------------------------------"

    if bash "$test_file"; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi

    echo ""
done

echo -e "${BLUE}========================================"
echo " Final Summary"
echo -e "========================================${NC}"
echo ""
echo "Test Suites: $TOTAL_SUITES"
echo -e "Passed:      ${GREEN}$PASSED_SUITES${NC}"
echo -e "Failed:      ${RED}$FAILED_SUITES${NC}"
echo ""

if [[ $FAILED_SUITES -eq 0 ]]; then
    echo -e "${GREEN}✓ All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some test suites failed.${NC}"
    exit 1
fi
