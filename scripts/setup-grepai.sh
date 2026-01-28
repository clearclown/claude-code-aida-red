#!/bin/bash
# AIDA Grepai Setup
# Purpose: Install and configure grepai for semantic search
# Usage: ./setup-grepai.sh [--check|--install]
#
# Grepai provides AI-powered semantic code search, reducing
# token consumption by 80% compared to full file reads.
#
# Issue #216: Token consumption optimization

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# ============================================
# Usage
# ============================================
usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Install and configure grepai for AIDA semantic search.

Options:
    --check     Check if grepai is installed and working
    --install   Install grepai (requires Go)
    --help      Show this help message

Requirements:
    - Go 1.21+ (for installation)
    - OpenAI API key or Anthropic API key (for usage)

Examples:
    $(basename "$0") --check
    $(basename "$0") --install

Environment Variables:
    OPENAI_API_KEY      - OpenAI API key for grepai
    ANTHROPIC_API_KEY   - Anthropic API key (alternative)
EOF
}

# ============================================
# Check installation
# ============================================
check_grepai() {
    echo -e "${BLUE}Checking grepai installation...${NC}"
    echo ""

    # Check if grepai exists
    if command -v grepai &>/dev/null; then
        local version
        version=$(grepai --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ grepai installed${NC}"
        echo "  Version: $version"
        echo "  Path: $(which grepai)"
    else
        echo -e "${RED}✗ grepai not found${NC}"
        echo ""
        echo "Install with: ./setup-grepai.sh --install"
        return 1
    fi

    echo ""

    # Check for API keys
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        echo -e "${GREEN}✓ OPENAI_API_KEY set${NC}"
    elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        echo -e "${GREEN}✓ ANTHROPIC_API_KEY set${NC}"
    else
        echo -e "${YELLOW}⚠ No API key found${NC}"
        echo "  Set OPENAI_API_KEY or ANTHROPIC_API_KEY"
        return 1
    fi

    echo ""

    # Test grepai
    echo "Testing grepai..."
    if echo "test" | grepai "test" . --limit 1 &>/dev/null; then
        echo -e "${GREEN}✓ grepai working${NC}"
    else
        echo -e "${YELLOW}⚠ grepai test failed (may need API key)${NC}"
    fi

    echo ""
    echo -e "${GREEN}Grepai is ready for AIDA!${NC}"
    return 0
}

# ============================================
# Install grepai
# ============================================
install_grepai() {
    echo -e "${BLUE}Installing grepai...${NC}"
    echo ""

    # Check for Go
    if ! command -v go &>/dev/null; then
        echo -e "${RED}Error: Go is required to install grepai${NC}"
        echo ""
        echo "Install Go from: https://go.dev/dl/"
        echo ""
        echo "Or use package manager:"
        echo "  Ubuntu/Debian: sudo apt install golang-go"
        echo "  macOS: brew install go"
        echo "  Arch: sudo pacman -S go"
        return 1
    fi

    local go_version
    go_version=$(go version | grep -oP 'go\d+\.\d+' || echo "unknown")
    echo "Go version: $go_version"

    # Install grepai
    echo ""
    echo "Installing grepai..."
    if go install github.com/yoanbernabeu/grepai@latest; then
        echo ""
        echo -e "${GREEN}✓ grepai installed successfully${NC}"

        # Check if GOPATH/bin is in PATH
        local gobin="${GOPATH:-$HOME/go}/bin"
        if [[ ":$PATH:" != *":$gobin:"* ]]; then
            echo ""
            echo -e "${YELLOW}Add to your PATH:${NC}"
            echo "  export PATH=\"\$PATH:$gobin\""
            echo ""
            echo "Add this to your ~/.bashrc or ~/.zshrc"
        fi

        # Verify installation
        if command -v grepai &>/dev/null; then
            echo ""
            check_grepai
        fi
    else
        echo -e "${RED}Failed to install grepai${NC}"
        return 1
    fi
}

# ============================================
# Main
# ============================================
case "${1:-}" in
    --check)
        check_grepai
        ;;
    --install)
        install_grepai
        ;;
    --help|-h)
        usage
        ;;
    "")
        # Default: check, then offer to install
        if ! check_grepai 2>/dev/null; then
            echo ""
            echo "Would you like to install grepai? (y/n)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                install_grepai
            fi
        fi
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        usage
        exit 1
        ;;
esac
