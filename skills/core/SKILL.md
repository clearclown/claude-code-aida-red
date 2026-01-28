---
name: core
description: |
  Core session management skill.
  Handles session initialization and state management.
tools: Read, Write, Bash, Glob
---

# Core Skills

Core AIDA system skills for session management and initialization.

## Overview

Provides foundation functionality for session initialization, state management, and memory management.

## Included Skills

| Skill | Description | Trigger |
|-------|-------------|---------|
| `session-init` | Session initialization | `/aida:init` |
| `session-memory` | Session state management | Phase transitions |

## session-init

Initialize a new AIDA session.

### Execution

1. Create `.aida/` directory structure
2. Initialize `session.json`
3. Initialize `kanban.md`
4. Generate session ID with UUID

### Generated Files

```
.aida/
  state/
    session.json
  checkpoints/
  artifacts/
  tasks/
  results/
```

### session.json Initial State

```json
{
  "session_id": null,
  "started_at": null,
  "phase": "idle",
  "status": "initialized",
  "user_request": null,
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

## session-memory

Persistence and loading of session state.

### Functions

- Save phase state
- Track task progress
- Create checkpoints

### Checkpoint Format

```json
{
  "checkpoint_id": "cp-{{PHASE}}-{{TIMESTAMP}}",
  "phase": 2,
  "state": { ... },
  "artifacts": [
    ".aida/artifacts/requirements/00_overview.md",
    ".aida/artifacts/requirements/01_functional.md"
  ],
  "created_at": "{{TIMESTAMP}}"
}
```

## Related Skills

- `orchestrator` - Pipeline orchestration
- `pipeline` - Complete pipeline execution
- `requirements-gen` - Requirements generation
