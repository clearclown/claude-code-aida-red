---
name: aida:import
description: |
  Import external projects into AIDA management.
  Supports local paths and GitHub/GitLab URLs.
  Auto-analyzes and generates reverse specifications.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
---

# AIDA Import

Import external projects into AIDA management structure.

## Usage

```
# Local project
/aida:import /path/to/project

# GitHub repository
/aida:import https://github.com/org/repo

# With branch specification
/aida:import https://github.com/org/repo --branch develop

# With target directory
/aida:import https://github.com/org/repo --target my-project-name
```

---

## MANDATORY EXECUTION PROTOCOL

### Step 1: Parse Arguments

```
PROJECT_SOURCE = $ARGUMENTS[0]  # Path or URL
BRANCH = $ARGUMENTS.branch || "main"
TARGET_NAME = $ARGUMENTS.target || derived from URL/path
```

### Step 2: Acquire Project

**For Local Path:**
```bash
# Validate path exists
if [[ ! -d "$PROJECT_SOURCE" ]]; then
  echo "Error: Path does not exist"
  exit 1
fi

# Copy to AIDA managed location (optional)
# Or use in-place if user prefers
PROJECT_PATH="$PROJECT_SOURCE"
```

**For Remote URL:**
```bash
# Create target directory
mkdir -p ./

# Clone repository
if [[ "$PROJECT_SOURCE" == *"github.com"* ]] || [[ "$PROJECT_SOURCE" == *"gitlab.com"* ]]; then
  git clone --branch "$BRANCH" "$PROJECT_SOURCE" ".//$TARGET_NAME"
  PROJECT_PATH=".//$TARGET_NAME"
else
  echo "Error: Unsupported URL format"
  exit 1
fi
```

### Step 3: Run Analysis

```bash
./scripts/analyze-project.sh "$PROJECT_PATH"
```

### Step 4: Generate Reverse Specifications

Based on analysis results, generate:
- `.aida/specs/<PROJECT>-reverse-requirements.md`
- `.aida/specs/<PROJECT>-reverse-design.md`

### Step 5: Initialize Session

Create `.aida/state/session.json` for AIDA management.

### Step 6: Report Results

Display import summary and next steps.

---

## Supported Sources

| Source Type | Example |
|-------------|---------|
| Local Path | `/home/user/projects/my-app` |
| GitHub HTTPS | `https://github.com/org/repo` |
| GitHub SSH | `git@github.com:org/repo.git` |
| GitLab HTTPS | `https://gitlab.com/org/repo` |
| GitLab SSH | `git@gitlab.com:org/repo.git` |
| Bitbucket | `https://bitbucket.org/org/repo` |

---

## Import Modes

### In-Place Mode (Local Projects)

For local projects, AIDA can manage in-place without copying:

```
/aida:import /path/to/project --in-place
```

- Uses project at original location
- Creates AIDA metadata in .aida/ directory
- No file duplication

### Copy Mode (Default for Remote)

For remote projects, clones to AIDA managed directory:

```
/aida:import https://github.com/org/repo
```

- Clones to `.//<repo-name>/`
- Full AIDA control over files
- Safe sandbox environment

---

## Reverse Specification Generation

AIDA generates specifications from existing code:

### `.aida/specs/<PROJECT>-reverse-requirements.md`

```markdown
# Reverse-Engineered Requirements: <PROJECT>

## Detected Features

### Feature 1: User Authentication
- Login/logout functionality
- JWT token management
- Password hashing

### Feature 2: Data Management
- CRUD operations for [entities]
- Database schema with [tables]

## API Endpoints (Detected)

| Method | Path | Handler |
|--------|------|---------|
| POST | /api/auth/login | AuthHandler.Login |
| GET | /api/users | UserHandler.List |

## Dependencies

- External services: PostgreSQL, Redis
- Major libraries: gin, gorm, jwt-go
```

### `.aida/specs/<PROJECT>-reverse-design.md`

```markdown
# Reverse-Engineered Design: <PROJECT>

## Architecture

[Detected architecture pattern]

## Directory Structure

```
<tree output>
```

## Component Diagram

```
[Component relationships]
```

## Data Models

### User
- id: UUID
- email: string
- password_hash: string
- created_at: timestamp

## Design Patterns Detected

- Repository pattern
- Dependency injection
- Clean architecture layers
```

---

## Session Initialization

Creates `.aida/state/session.json`:

```json
{
  "session_id": "<UUID>",
  "started_at": "<ISO8601>",
  "mode": "aida:import",
  "source": "<URL or Path>",
  "project_name": "<name>",
  "project_path": "<path>",
  "current_phase": "IMPORTED",
  "import_details": {
    "source_type": "github|local",
    "branch": "main",
    "commit": "<sha>",
    "imported_at": "<ISO8601>"
  },
  "analysis": "<path to analysis.json>",
  "reverse_specs": {
    "requirements": ".aida/specs/<PROJECT>-reverse-requirements.md",
    "design": ".aida/specs/<PROJECT>-reverse-design.md"
  },
  "quality_baseline": {
    "tests": 45,
    "coverage": "unknown",
    "captured_at": "<ISO8601>"
  }
}
```

---

## Output Report

After import completes:

```
AIDA Project Import Complete

Source: https://github.com/org/repo
Branch: main
Commit: abc1234

Imported To: .//repo/
Project Type: fullstack
Languages: Go, TypeScript

Analysis:
  - Backend: 15 test files, Go/Gin
  - Frontend: 24 test files, React/TypeScript

Reverse Specs Generated:
  - .aida/specs/repo-reverse-requirements.md
  - .aida/specs/repo-reverse-design.md

Quality Baseline:
  - Total Tests: 39 files
  - Coverage: Unknown (run tests to measure)

Session: <UUID>

Next Steps:
  1. Review reverse specifications
  2. Run tests to establish baseline:
     cd .//repo && make test
  3. Use /aida:enhance to extend:
     /aida:enhance .//repo "Add feature X"
  4. Use /aida:maintain for maintenance:
     /aida:maintain .//repo --update-deps
```

---

## Error Handling

### Clone Failed
```
Error: Failed to clone repository
Reason: Authentication required

Solutions:
1. Use HTTPS URL with token: https://token@github.com/...
2. Configure SSH keys
3. Check repository access permissions
```

### Unsupported Project
```
Warning: Could not detect project type

The project uses languages or frameworks not yet supported.
Manual configuration may be required.

Detected files:
- Some.swift
- Package.swift

Current support: Go, TypeScript, Python, Rust, JavaScript, Java, Ruby
```

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida:analyze` | Analyze without importing |
| `/aida:enhance` | Extend imported project |
| `/aida:maintain` | Maintain imported project |
| `/aida:status` | Check import/project status |
