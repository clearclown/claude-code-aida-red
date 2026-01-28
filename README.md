# AIDA Plugin for Claude Code

**AIDA** (Agent Integration & Development Architecture) - Multi-agent orchestration framework for Claude Code.

<p align="center">
  <img src="docs/pics/architecture.svg" alt="AIDA Architecture" width="600">
</p>

English | [日本語](docs/readmeLang/README_ja.md) | [简体中文](docs/readmeLang/README_zh-CN.md) | [繁體中文](docs/readmeLang/README_zh-TW.md) | [Русский](docs/readmeLang/README_ru.md) | [فارسی](docs/readmeLang/README_fa.md) | [العربية](docs/readmeLang/README_ar.md)

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Update](#update)
- [Uninstall](#uninstall)
- [Usage Guide](#usage-guide)
- [Command Reference](#command-reference)
- [Quality Gates](#quality-gates)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

AIDA enables multi-agent orchestration for software development projects using Claude Code's Task tool to spawn subagents. It automates the entire development lifecycle from requirements to implementation with TDD (Test-Driven Development) enforcement.

### Key Features

- **Multi-Agent Orchestration**: Automatically spawns and coordinates multiple Claude agents
- **5-Phase Workflow**: Structured development from requirements to implementation
- **19 Quality Gates**: Automated validation of code quality, tests, and coverage
- **TDD Enforcement**: Red-Green-Refactor cycle with evidence tracking
- **Stack Support**: Go + React + Docker (default), with extensibility for other stacks

---

## Requirements

### Required

| Tool | Version | Purpose |
|------|---------|---------|
| **Claude Code** | Latest | Core CLI |
| **bash** | 4.0+ | Script execution |
| **git** | 2.0+ | Version control |
| **jq** | 1.6+ | JSON processing |

### Recommended

| Tool | Version | Purpose |
|------|---------|---------|
| **grepai** | Latest | Semantic search (80% token reduction) |
| **fzf** | Latest | Interactive file selection |
| **jj** (Jujutsu) | Latest | Environment isolation |
| **go** | 1.21+ | Backend development |
| **node** | 18+ | Frontend development |
| **docker** | 24+ | Container builds |

### Install Dependencies

```bash
# Ubuntu/Debian
sudo apt install jq fzf git

# macOS
brew install jq fzf git

# Install grepai (recommended for semantic search)
go install github.com/yoanbernabeu/grepai@latest

# Install jj (optional - for environment isolation)
cargo install jj-cli
```

---

## Installation

### Method 1: One-Line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

### Method 2: Manual Clone

```bash
# Clone repository
git clone https://github.com/clearclown/claude-code-aida.git ~/.claude-code-aida

# Run install script
cd ~/.claude-code-aida
./scripts/install.sh
```

### Method 3: Install to Custom Location

```bash
# Clone to custom location
git clone https://github.com/clearclown/claude-code-aida.git /path/to/aida

# Install from that location
cd /path/to/aida
./scripts/install.sh
```

### Verify Installation

```bash
# Check installation
./scripts/verify-installation.sh

# Restart Claude Code
claude

# Test command availability
/aida:status
```

If `/aida` shows "Unknown skill", restart Claude Code and try again.

### What Gets Installed

```
~/.claude-code-aida/         # AIDA source files
~/.claude/commands/
  aida.md                    # Main /aida command
  aida/
    init.md                  # /aida:init
    start.md                 # /aida:start
    status.md                # /aida:status
    work.md                  # /aida:work
    pipeline.md              # /aida:pipeline
    enhance.md               # /aida:enhance
    analyze.md               # /aida:analyze
    maintain.md              # /aida:maintain
    import.md                # /aida:import
    resume.md                # /aida:resume
    fix.md                   # /aida:fix
```

---

## Update

### Automatic Update

```bash
# Navigate to AIDA directory
cd ~/.claude-code-aida

# Pull latest changes and reinstall
git pull origin main
./scripts/install.sh
```

### Update Script

```bash
# One-line update
cd ~/.claude-code-aida && git pull origin main && ./scripts/install.sh
```

### Update to Specific Version

```bash
cd ~/.claude-code-aida
git fetch --tags
git checkout v1.2.0  # Replace with desired version
./scripts/install.sh
```

### Update from Specific Branch

```bash
cd ~/.claude-code-aida
git fetch origin
git checkout develop  # or feature/new-feature
git pull
./scripts/install.sh
```

### Verify Update

```bash
# Check version/status
./scripts/verify-installation.sh

# Restart Claude Code after update
# Then test:
/aida:status
```

---

## Uninstall

### Complete Uninstall

```bash
# Remove command files
rm -f ~/.claude/commands/aida.md
rm -rf ~/.claude/commands/aida/

# Remove AIDA source directory
rm -rf ~/.claude-code-aida

# Optional: Remove project data (only do this if you don't need the data)
# rm -rf ~/.aida  # Global AIDA data
```

### Partial Uninstall (Keep Source)

```bash
# Only remove command files (keeps source for reinstall)
rm -f ~/.claude/commands/aida.md
rm -rf ~/.claude/commands/aida/
```

### Clean Project Data

```bash
# Remove AIDA data from a specific project
cd /path/to/project
rm -rf .aida/
```

### Verify Uninstall

```bash
# Check commands are removed
ls ~/.claude/commands/aida* 2>/dev/null || echo "Commands removed"

# Check source directory
ls ~/.claude-code-aida 2>/dev/null || echo "Source removed"
```

---

## Usage Guide

### Basic Workflow

#### 1. Create a New Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Start Claude Code
claude

# Generate project with full pipeline
/aida "Create a blog platform with user authentication"
```

#### 2. Step-by-Step Execution

```bash
# Initialize workspace
/aida:init

# Start specification phase
/aida:start "Create a Twitter clone"

# Check current status
/aida:status

# Continue work
/aida:work
```

#### 3. Enhance Existing Project

```bash
# Navigate to existing project
cd /path/to/existing-project
claude

# Analyze and enhance
/aida:enhance . "Add user profile feature"
```

#### 4. Import External Project

```bash
# Import from GitHub
/aida:import https://github.com/user/repo

# Import from local path
/aida:import /path/to/project
```

### Advanced Usage

#### Resume Interrupted Session

```bash
/aida:resume
```

#### Fix Failing Quality Gates

```bash
/aida:fix
```

#### Run Quality Gates Manually

```bash
# Run all gates
./scripts/quality-gates.sh my-project

# Skip Docker gates
./scripts/quality-gates.sh my-project --skip-docker

# Skip frontend gates
./scripts/quality-gates.sh my-project --skip-frontend

# Verbose output
./scripts/quality-gates.sh my-project --verbose
```

#### Analyze Project Structure

```bash
/aida:analyze /path/to/project
```

#### Maintenance Tasks

```bash
# Update dependencies
/aida:maintain /path/to/project --update-deps

# Security audit
/aida:maintain /path/to/project --security-audit
```

---

## Command Reference

### Core Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/aida "<description>"` | Full pipeline execution | `/aida "Create a todo app"` |
| `/aida:init` | Initialize `.aida/` directory | `/aida:init` |
| `/aida:start "<desc>"` | Start specification phase | `/aida:start "Blog platform"` |
| `/aida:work` | Continue current phase | `/aida:work` |
| `/aida:status` | Show session status | `/aida:status` |
| `/aida:pipeline` | Alias for `/aida` | `/aida:pipeline "Chat app"` |

### Extended Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/aida:enhance` | Enhance existing project | `/aida:enhance . "Add feature"` |
| `/aida:analyze` | Analyze project structure | `/aida:analyze /path/to/project` |
| `/aida:maintain` | Maintenance tasks | `/aida:maintain . --update-deps` |
| `/aida:import` | Import external project | `/aida:import https://github.com/...` |
| `/aida:resume` | Resume last session | `/aida:resume` |
| `/aida:fix` | Fix quality gate failures | `/aida:fix` |

### Utility Scripts

```bash
# Verify installation
./scripts/verify-installation.sh

# Run quality gates
./scripts/quality-gates.sh <project>

# Analyze project
./scripts/analyze-project.sh /path/to/project

# Parse requirements document
./scripts/parse-requirements.sh docs/requirements.md

# Setup jj for environment isolation
./scripts/setup-jj.sh

# Semantic search (requires grepai)
./scripts/semantic-search.sh "authentication logic"

# Interactive file picker (requires fzf)
./scripts/file-picker.sh code ./src
```

---

## Quality Gates

AIDA enforces quality through 19 automated gates:

### Basic Gates (1-7)

| Gate | Check | Command |
|------|-------|---------|
| 1 | Backend Build | `go build ./...` |
| 2 | Backend Tests | `go test ./...` |
| 3 | Frontend Build | `npm run build` |
| 4 | Frontend Tests | `npm test -- --run` |
| 5 | Docker Build | `docker compose build` |
| 6 | Docker Run | `docker compose up -d` |
| 7 | Health Check | `curl localhost:8080/health` |

### Extended Gates (8-19)

| Gate | Check | Threshold |
|------|-------|-----------|
| 8 | API Coverage | 3+ handlers |
| 9 | Frontend Coverage | 3+ pages |
| 10 | Integration | CORS, Docker links |
| 11 | Backend Test Count | 80+ tests |
| 12 | Frontend Test Count | 100+ tests |
| 13 | Empty Array Pattern | Go nil checks |
| 14 | Backend Coverage | 75%+ |
| 15 | E2E Config | Playwright setup |
| 16 | Design Quality | shadcn/ui |
| 17 | Frontend Coverage | 70%+ |
| 18 | E2E Test Count | 20+ tests |
| 19 | E2E Execution | Playwright pass |

### TDD Gate (20)

| Gate | Check | Requirement |
|------|-------|-------------|
| 20 | TDD Evidence | 10+ TDD cycles recorded |

---

## Configuration

### Project Structure

```
.aida/                    # AIDA management directory
  state/
    session.json          # Session state
    coordinator.json      # Agent coordination
  specs/                  # Generated specifications
  artifacts/              # Intermediate work
  tdd-evidence/           # TDD cycle records
  fix-plans/              # Generated fix plans
  search-cache/           # Semantic search cache
  results/                # Completion reports

./                        # Generated project
  backend/                # Go backend
  frontend/               # React frontend
  docker-compose.yml      # Container config
```

### Environment Variables

```bash
# Project directory override
export CLAUDE_PROJECT_DIR=/path/to/project

# Agent scaling configuration
export MAX_AGENTS=4
export MIN_AGENTS=1

# Token limit configuration
export AIDA_TOKEN_LIMIT=100000
```

### Customization

#### Modify Quality Thresholds

Edit `scripts/quality-gates.sh`:

```bash
# Change test count requirements
MIN_BACKEND_TESTS=50   # Default: 80
MIN_FRONTEND_TESTS=70  # Default: 100

# Change coverage requirements
MIN_BACKEND_COVERAGE=60  # Default: 75
MIN_FRONTEND_COVERAGE=60 # Default: 70
```

#### Skip Specific Gates

```bash
# Skip Docker gates (no Docker installed)
./scripts/quality-gates.sh project --skip-docker

# Skip frontend gates (backend-only project)
./scripts/quality-gates.sh project --skip-frontend
```

---

## Troubleshooting

### Common Issues

#### "Unknown skill: aida"

Commands not installed:

```bash
cd ~/.claude-code-aida
./scripts/install.sh
# Restart Claude Code
```

#### Quality Gates Fail

```bash
# Check which gate failed
./scripts/quality-gates.sh project --verbose

# Skip Docker if unavailable
./scripts/quality-gates.sh project --skip-docker

# Generate fix plan
./scripts/generate-fix-plan.sh project
```

#### Session Stuck

```bash
# Check session state
cat .aida/state/session.json | jq .

# Reset session
rm .aida/state/session.json
/aida:init
```

#### grepai Not Found

```bash
# Install grepai
go install github.com/yoanbernabeu/grepai@latest

# Add to PATH
export PATH=$PATH:$(go env GOPATH)/bin
```

#### fzf Not Working

```bash
# Install fzf
sudo apt install fzf  # Ubuntu/Debian
brew install fzf      # macOS
```

### Debug Information

```bash
# Full installation verification
./scripts/verify-installation.sh

# Check AIDA logs
ls -la .aida/logs/

# Check agent status
./scripts/agent-coordinator.sh status

# Check resource usage
./scripts/resource-monitor.sh status
```

---

## Contributing

Contributions welcome! Areas of focus:

- [ ] Python/FastAPI stack support
- [ ] Node.js/Express stack support
- [ ] Rust/Axum stack support
- [ ] Configurable quality thresholds
- [ ] Better session recovery
- [ ] Improved project analysis
- [ ] More test coverage

### Development Setup

```bash
# Clone for development
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# Run tests
./tests/run-all-tests.sh

# Lint prompts
./scripts/prompt-lint.sh agents/

# Check installation
./scripts/verify-installation.sh
```

### Test Coverage

Currently tested scripts (20 test suites):

- `test-agent-coordinator.sh`
- `test-agent-scaler.sh`
- `test-analyze-project.sh`
- `test-common.sh`
- `test-enhancement-queue.sh`
- `test-file-picker.sh`
- `test-generate-fix-plan.sh`
- `test-install.sh`
- `test-jj-worktree.sh`
- `test-parse-requirements.sh`
- `test-prompt-lint.sh`
- `test-quality-gates.sh`
- `test-ralph-gate.sh`
- `test-resource-monitor.sh`
- `test-semantic-search.sh`
- `test-setup-jj.sh`
- `test-task-seeker.sh`
- `test-tdd-logger.sh`
- `test-validate-completion.sh`
- `test-verify-installation.sh`

---

## License

MIT

---

## Credits & Acknowledgments

### Core Technologies

| Project | Author | Role |
|---------|--------|------|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | Requirements Generation |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | Specification-Driven Development |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | TDD Framework |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | Multi-Agent Orchestration |

### Infrastructure

| Project | License |
|---------|---------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Podman](https://podman.io/) | Apache 2.0 |

---

## Links

- [GitHub Repository](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)
- [Discussions](https://github.com/clearclown/claude-code-aida/discussions)
