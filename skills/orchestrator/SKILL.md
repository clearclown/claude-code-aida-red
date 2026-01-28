---
name: orchestrator
description: |
  AIDA pipeline orchestration with Task tool multi-agent delegation.
  Manages 5-phase workflow with Leader/Player subagents.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
---

# Orchestrator Skill

Orchestrates the entire AIDA pipeline using Task tool for multi-agent delegation.

## Overview

Manages 5-phase workflow and delegates work to Leader/Player subagents via Task tool.
Implements the Conductor/Leader/Player pattern.

## Architecture

```
+-----------------------------------------------------------+
|                    ORCHESTRATOR                            |
+-----------------------------------------------------------+
|                                                            |
|  +-----------------------------------------------------+  |
|  |              Task Tool Delegation                    |  |
|  |                                                       |  |
|  |  Phase 1-4: Task tool -> leader-spec                 |  |
|  |                            |                         |  |
|  |                            +-> Task tool -> player   |  |
|  |                            +-> Task tool -> player   |  |
|  |                                                       |  |
|  |  Phase 5:   Task tool -> leader-impl                 |  |
|  |                            |                         |  |
|  |                            +-> Task tool -> player   |  |
|  |                            +-> Task tool -> player   |  |
|  +-----------------------------------------------------+  |
|                                                            |
|  +-----------------------------------------------------+  |
|  |              Session Management                      |  |
|  |  .aida/state/session.json - Current state           |  |
|  |  .aida/checkpoints/ - Phase snapshots               |  |
|  +-----------------------------------------------------+  |
|                                                            |
+-----------------------------------------------------------+
```

## Task Tool Patterns

### Launching a Leader

| Parameter | Value |
|-----------|-------|
| description | "Launch [leader-name] for [phase]" |
| subagent_type | "general-purpose" |
| run_in_background | true or false |
| prompt | Leader instructions |

### Leader-Spec Launch

```
Task tool parameters:
- description: "Leader-Spec: phases 1-4"
- subagent_type: "general-purpose"
- run_in_background: true
- prompt: |
    You are AIDA Leader-Spec.
    Read: agents/leader-spec.md
    Execute phases 1-4.
    Spawn players with Task tool (model: haiku).
    Output to: .aida/specs/
```

### Leader-Impl Launch

```
Task tool parameters:
- description: "Leader-Impl: TDD implementation"
- subagent_type: "general-purpose"
- run_in_background: true
- prompt: |
    You are AIDA Leader-Impl.
    Read: agents/leader-impl.md
    Read specs from: .aida/specs/
    Spawn TDD players with Task tool (model: haiku).
    Output to: ./[PROJECT]/
```

### Player Launch (from Leader)

```
Task tool parameters:
- description: "Player: [task description]"
- subagent_type: "general-purpose"
- model: "haiku"
- run_in_background: true (parallel) or false (sequential)
- prompt: |
    You are AIDA Player.
    Read: agents/player.md
    Task: [TASK_DESCRIPTION]
    Output: [OUTPUT_PATH]
```

## Workflow (5 Phases)

```
[ORCHESTRATOR]
    |
    +-- Phase 1: Extraction & Architecture
    |   Task tool -> Leader-Spec -> Players (parallel)
    |   Output: .aida/artifacts/requirements/
    |
    +-- Phase 2: Structure
    |   Task tool -> Leader-Spec -> Players (parallel)
    |   Output: .aida/artifacts/designs/
    |
    +-- Phase 3: Alignment
    |   Task tool -> Leader-Spec
    |   Output: .aida/artifacts/alignment.md
    |
    +-- Phase 4: Verification
    |   Task tool -> Leader-Spec
    |   Output: .aida/specs/
    |
    +-- Phase 5: Implementation
        Task tool -> Leader-Impl -> TDD Players (parallel)
        Output: ./[PROJECT]/
```

## Session Management

### Directory Structure

```
.aida/
  state/
    session.json           # Session state
  checkpoints/             # Phase completion snapshots
  artifacts/
    requirements/          # Requirements output
    designs/               # Design output
  tasks/                   # Task assignments
  results/                 # Completion reports
  specs/                   # Final specifications
  kanban.md                # Project kanban board
```

### session.json

```json
{
  "session_id": "uuid-xxxx",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "phase": 3,
  "phase_name": "alignment",
  "user_request": "...",
  "project_name": "...",
  "leaders": {
    "spec": "running",
    "impl": "pending"
  },
  "phases": {
    "1": { "status": "completed" },
    "2": { "status": "completed" },
    "3": { "status": "in_progress" },
    "4": { "status": "pending" },
    "5": { "status": "pending" }
  }
}
```

## Commands Integration

### /aida:start

1. Initialize session
2. Launch leader-spec via Task tool
3. Monitor progress

### /aida:work

1. Read session state
2. Determine current phase
3. Launch appropriate leader via Task tool

### /aida:pipeline

1. Initialize session
2. Launch leader-spec (wait for completion)
3. Launch leader-impl (wait for completion)
4. Report final results

## Parallel Execution

Leaders can spawn multiple players in parallel:

```
[Leader-Spec]
    |
    +-- Task tool (run_in_background: true) --> Player 1
    +-- Task tool (run_in_background: true) --> Player 2
    +-- Task tool (run_in_background: true) --> Player 3
    |
    +-- Wait for all players
    |
    +-- Integrate outputs
```

## Context Optimization

Pass only necessary context between phases:

```
Phase 1 -> Phase 2:
  Pass: architecture_summary
  Skip: full conversation

Phase 4 -> Phase 5:
  Pass: .aida/specs/ paths
  Skip: intermediate details
```

## Kanban Integration

Update `.aida/kanban.md` after each phase:

```markdown
# Project: [PROJECT_NAME]

## Session: [SESSION_ID]

## Phases
- [x] Phase 1: Extraction (completed)
- [x] Phase 2: Structure (completed)
- [ ] Phase 3: Alignment (in progress)
- [ ] Phase 4: Verification (pending)
- [ ] Phase 5: Implementation (pending)
```
