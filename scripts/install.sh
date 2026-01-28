#!/bin/bash
# AIDA - One-Click Installation
# Fix for Issue #178: Use file copy instead of symlinks
set -e

REPO_URL="https://github.com/clearclown/claude-code-aida.git"
BRANCH="${1:-main}"
INSTALL_DIR="${HOME}/.claude-code-aida"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "🚀 AIDA Installation"
echo "===================="
echo ""

# Check if claude is available
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found"
    echo "   Please install Claude Code first: https://docs.anthropic.com/claude-code"
    exit 1
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo "📦 Updating existing installation..."
    cd "$INSTALL_DIR"
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    echo "📦 Cloning repository..."
    git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# Create commands directory if it doesn't exist
mkdir -p "$COMMANDS_DIR"

# Helper function to copy file (not symlink) for Claude Code compatibility
install_command() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ -f "$src" ]; then
        # Remove old symlink if exists
        [ -L "$dest" ] && rm -f "$dest"
        # Copy file (not symlink) to ensure Claude Code can read it
        cp -f "$src" "$dest"
        echo "   ✓ $name"
        return 0
    fi
    return 1
}

echo ""
echo "📋 Installing commands (using file copy for compatibility)..."

# Main aida command
install_command "$INSTALL_DIR/skills/aida/SKILL.md" "$COMMANDS_DIR/aida.md" "/aida"

# Create aida subdirectory for subcommands
mkdir -p "$COMMANDS_DIR/aida"

# Core subcommands from commands/ directory
for cmd in init start status work pipeline; do
    install_command "$INSTALL_DIR/commands/${cmd}.md" "$COMMANDS_DIR/aida/${cmd}.md" "/aida:${cmd}"
done

# Additional subcommands from skills/aida/
for cmd in enhance analyze maintain import; do
    install_command "$INSTALL_DIR/skills/aida/${cmd}.md" "$COMMANDS_DIR/aida/${cmd}.md" "/aida:${cmd}"
done

# Resume command
install_command "$INSTALL_DIR/skills/resume/SKILL.md" "$COMMANDS_DIR/aida/resume.md" "/aida:resume"

# Fix command
install_command "$INSTALL_DIR/skills/fix/SKILL.md" "$COMMANDS_DIR/aida/fix.md" "/aida:fix"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📍 Installed to: $INSTALL_DIR"
echo "📍 Commands in:  $COMMANDS_DIR"
echo ""
echo "Available commands:"
echo "  /aida <description>  - Full pipeline (init + start + quality gates)"
echo "  /aida:init           - Initialize workspace"
echo "  /aida:start          - Start spec phase"
echo "  /aida:status         - Check current status"
echo "  /aida:work           - Execute current phase"
echo "  /aida:pipeline       - Full automation"
echo "  /aida:enhance        - Enhance existing project"
echo "  /aida:analyze        - Analyze project structure"
echo "  /aida:maintain       - Maintenance tasks"
echo "  /aida:import         - Import external project"
echo "  /aida:resume         - Resume from last session"
echo "  /aida:fix            - Fix project to pass quality gates"
echo ""
echo "To get started, run:"
echo "  claude"
echo "  /aida \"Create a Twitter clone\""
