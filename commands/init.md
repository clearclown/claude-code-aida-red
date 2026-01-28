---
description: Initialize AIDA directory structure. Setup new workspace
---

# AIDA Init

Initialize the AIDA directory structure and configuration files for a new workspace.

## Usage

```
/aida:init [project-dir]
```

- `project-dir`: Optional. Directory where project code will be generated (default: current directory)

## Execution Steps

### Step 1: Create Directory Structure

```bash
# AIDA management directories (always in .aida/)
mkdir -p .aida/state
mkdir -p .aida/checkpoints
mkdir -p .aida/artifacts
mkdir -p .aida/sessions
mkdir -p .aida/tasks
mkdir -p .aida/results
mkdir -p .aida/specs
```

### Step 2: Initialize session.json

Create `.aida/state/session.json`:

```json
{
  "session_id": null,
  "started_at": null,
  "phase": "idle",
  "status": "initialized",
  "user_request": null,
  "project_dir": ".",
  "agents": {
    "conductor": {"status": "waiting"},
    "leaders": [],
    "players": []
  },
  "phases": {
    "1": {"status": "pending"},
    "2": {"status": "pending"},
    "3": {"status": "pending"},
    "4": {"status": "pending"},
    "5": {"status": "pending"}
  },
  "tasks": [],
  "metrics": {
    "tasks_completed": 0,
    "tasks_failed": 0
  }
}
```

### Step 3: Initialize kanban.md

Create `.aida/kanban.md`:

```markdown
# AIDA Kanban Board

## Meta
**Session**: (not started)
**Phase**: idle
**Updated**: <TIMESTAMP>

## Backlog
(no tasks)

## In Progress
(none)

## Done
(none)
```

### Step 4: Output Confirmation

## Output Format

### Success

```
AIDA Workspace Initialized

Created:
.aida/
  state/
    session.json
  checkpoints/
  artifacts/
  sessions/
  tasks/
  results/
  specs/
  kanban.md

Project code will be generated in: ./

Next step:
/aida:start "project description" to begin pipeline
```

### Already Initialized

```
AIDA workspace already initialized

Current state:
- Session: <session_id or "none">
- Phase: <phase>
- Project dir: <project_dir>

Options:
1. Continue current session: /aida:work
2. Check status: /aida:status
3. Start new pipeline: /aida:start "description"
```

## Directory Structure

After initialization:

```
.aida/                          # AIDA management (specs, state, artifacts)
  state/
    session.json                # Current session state
  checkpoints/                  # Phase completion snapshots
  artifacts/                    # Generated artifacts
    requirements/               # Requirements extraction
  sessions/                     # Past session history
  tasks/                        # Task assignments
  results/                      # Completion reports
  specs/                        # Project specifications
    requirements.md
    design.md
    tasks.md
  kanban.md                     # Task board

./                              # Project code (or specified directory)
  backend/                      # Backend code
  frontend/                     # Frontend code
  docker-compose.yml            # Container config
  ...
```
