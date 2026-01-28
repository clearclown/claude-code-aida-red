---
description: Show current AIDA session status and pipeline progress
---

# AIDA Status

Display the current state of the AIDA pipeline session.

## Usage

```
/aida:status
```

## Execution Steps

### Step 1: Read State Files

1. Read `.aida/state/session.json`
2. If not exists, report "No active session"

### Step 2: Read Kanban

1. Read `.aida/kanban.md` if exists
2. Extract task progress

### Step 3: Output Status Report

```markdown
## AIDA Session Status

### Basic Info
- **Session ID**: <session_id>
- **Phase**: <phase> (<phase_name>)
- **Started**: <started_at>
- **Updated**: <updated_at>
- **Project Directory**: <project_dir>

### Phase Progress

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Extraction & Architecture | <status> |
| 2 | Structure | <status> |
| 3 | Alignment | <status> |
| 4 | Verification | <status> |
| 5 | Planning & Execution | <status> |

### Agent Status

| Agent | Status | Current Task |
|-------|--------|--------------|
| Conductor | <status> | - |
| Leader-Spec | <status> | <task> |
| Leader-Impl | <status> | <task> |

### Artifacts

<list of created artifacts>

### Next Action

<recommended action>
```

## Status Display Examples

### Active Session

```
## AIDA Session Status

### Basic Info
- **Session ID**: a1b2c3d4-e5f6-7890
- **Phase**: specification (Phase 1-2)
- **Started**: 2025-12-23 10:00:00
- **Updated**: 2025-12-23 10:15:00
- **Project Directory**: ./

### Phase Progress

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Extraction & Architecture | Done |
| 2 | Structure | In Progress |
| 3 | Alignment | Pending |
| 4 | Verification | Pending |
| 5 | Planning & Execution | Pending |

### Next Action

Run `/aida:work` to continue current phase
```

### No Active Session

```
## AIDA Session Status

No active session.

To start a new pipeline:
/aida:start "project description"

To initialize workspace:
/aida:init
```
