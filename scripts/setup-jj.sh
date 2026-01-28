#!/bin/bash
# AIDA jj (Jujutsu) Setup Script
# Purpose: Install and configure jj for environment isolation
# Usage: ./setup-jj.sh [--check-only]
#
# jj provides superior environment isolation:
# - Automatic conflict-free commits
# - Full undo capability
# - No stash required
# - Operation log for debugging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CHECK_ONLY="${1:-}"

# ============================================
# Check if jj is installed
# ============================================
check_jj() {
    if command -v jj &>/dev/null; then
        local version
        version=$(jj --version 2>/dev/null | head -1)
        echo "jj is installed: $version"
        return 0
    else
        echo "jj is not installed"
        return 1
    fi
}

# ============================================
# Install jj
# ============================================
install_jj() {
    echo "Installing jj (Jujutsu)..."

    # Try cargo first (recommended)
    if command -v cargo &>/dev/null; then
        echo "Installing via cargo..."
        cargo install jj-cli
        return $?
    fi

    # Try brew on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &>/dev/null; then
        echo "Installing via Homebrew..."
        brew install jj
        return $?
    fi

    # Try pacman on Arch
    if command -v pacman &>/dev/null; then
        echo "Installing via pacman..."
        sudo pacman -S jj
        return $?
    fi

    # Try nix
    if command -v nix-env &>/dev/null; then
        echo "Installing via nix..."
        nix-env -iA nixpkgs.jujutsu
        return $?
    fi

    # Manual download
    echo "Downloading pre-built binary..."
    local os arch url
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) echo "Unsupported architecture: $arch"; return 1 ;;
    esac

    case "$os" in
        linux)
            url="https://github.com/martinvonz/jj/releases/latest/download/jj-v0.23.0-x86_64-unknown-linux-musl.tar.gz"
            ;;
        darwin)
            url="https://github.com/martinvonz/jj/releases/latest/download/jj-v0.23.0-${arch}-apple-darwin.tar.gz"
            ;;
        *)
            echo "Unsupported OS: $os"
            return 1
            ;;
    esac

    local tmpdir
    tmpdir=$(mktemp -d)
    cd "$tmpdir"

    curl -sL "$url" | tar xz
    sudo mv jj /usr/local/bin/

    cd -
    rm -rf "$tmpdir"

    echo "jj installed to /usr/local/bin/jj"
}

# ============================================
# Configure jj for AIDA
# ============================================
configure_jj() {
    echo "Configuring jj for AIDA..."

    # Set up user config
    if [[ -z "$(jj config get user.name 2>/dev/null || true)" ]]; then
        local git_name git_email
        git_name=$(git config user.name 2>/dev/null || echo "AIDA")
        git_email=$(git config user.email 2>/dev/null || echo "aida@localhost")

        jj config set --user user.name "$git_name"
        jj config set --user user.email "$git_email"
        echo "Set jj user config from git"
    fi

    # Enable git compatibility
    jj config set --user ui.default-command "status"
    jj config set --user ui.pager "less -FRX"

    echo "jj configuration complete"
}

# ============================================
# Initialize jj in current repo
# ============================================
init_jj_repo() {
    local repo_path="${1:-.}"

    if [[ -d "$repo_path/.jj" ]]; then
        echo "jj already initialized in $repo_path"
        return 0
    fi

    if [[ -d "$repo_path/.git" ]]; then
        echo "Initializing jj with existing git repo..."
        cd "$repo_path"
        jj git init --colocate
        echo "jj initialized (colocated with git)"
    else
        echo "Initializing new jj repo..."
        cd "$repo_path"
        jj init
        echo "jj initialized"
    fi
}

# ============================================
# Print usage
# ============================================
print_usage() {
    cat << 'EOF'
AIDA jj (Jujutsu) Setup

Usage:
  ./setup-jj.sh              Install and configure jj
  ./setup-jj.sh --check-only Check if jj is installed
  ./setup-jj.sh --init       Initialize jj in current directory

jj Benefits for AIDA:
  - Automatic commits: No need to stash/commit before switching
  - Full undo: Every operation can be undone
  - Parallel work: Multiple working copies without conflict
  - Operation log: Debug what happened

Example workflow:
  jj new -m "Enhancement: Add feature X"
  # ... make changes ...
  jj describe -m "Completed feature X"
  jj squash  # Merge into parent

EOF
}

# ============================================
# Main
# ============================================
main() {
    case "$CHECK_ONLY" in
        --check-only|-c)
            if check_jj; then
                exit 0
            else
                exit 1
            fi
            ;;
        --init|-i)
            if ! check_jj; then
                echo "jj is not installed. Run ./setup-jj.sh first."
                exit 1
            fi
            init_jj_repo "."
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        "")
            if check_jj; then
                echo "jj is already installed."
                configure_jj
            else
                install_jj
                configure_jj
            fi
            ;;
        *)
            echo "Unknown option: $CHECK_ONLY"
            print_usage
            exit 1
            ;;
    esac
}

main
