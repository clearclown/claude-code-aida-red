---
description: Start AIDA multi-agent pipeline with Task tool delegation
argument-hint: <project description>
---

# AIDA Pipeline Start

Start a new AIDA pipeline for the given project description.

## Usage

```
/aida:start "Create a Twitter clone application"
```

## Prerequisites

Ensure `.aida/` directory exists (run `/aida:init` if not).

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

---

### Step 1: Initialize Session

Create AIDA directories:
```bash
mkdir -p .aida/state .aida/checkpoints .aida/artifacts/requirements .aida/artifacts/designs .aida/tasks .aida/results .aida/specs .aida/errors
```

Create `.aida/state/session.json`:
```json
{
  "session_id": "<UUID>",
  "started_at": "<ISO8601>",
  "current_phase": "SPEC_PHASE",
  "phase": 1,
  "phase_name": "extraction",
  "user_request": "$ARGUMENTS",
  "project_name": "<derived from request>",
  "project_dir": ".",
  "phase_history": [
    {"phase": "INITIALIZING", "entered_at": "<ISO8601>", "exited_at": "<ISO8601>"}
  ],
  "leaders": {
    "spec": "pending",
    "impl": "pending"
  },
  "active_agents": [],
  "completed_tasks": [],
  "pending_tasks": ["spec-requirements", "spec-design", "spec-tasks"]
}
```

---

### Step 2: Create Feature List

Analyze user request and create `.aida/feature_list.json`:

```json
[
  {
    "id": "feat-<name>",
    "name": "Feature Name",
    "description": "Feature description",
    "spec_status": "pending",
    "impl_status": "pending"
  }
]
```

---

### Step 3: Launch Leader-Spec Subagent

<MANDATORY_ACTION id="launch-leader-spec">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Do NOT just describe the Task tool call - actually execute it.

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Spec: Specification Phases 1-4" |
| subagent_type | "general-purpose" |
| model | "sonnet" |
| run_in_background | false |
| prompt | See below |

**Task Prompt:**

```
You are AIDA Leader-Spec agent.

## CRITICAL INSTRUCTION
Read and follow the full instructions in: agents/leader-spec.md

## Current Session
- Session ID: {{SESSION_ID}}
- Project: {{PROJECT_NAME}}
- User Request: {{USER_REQUEST}}
- Working Directory: {{CWD}}
- Project Directory: {{PROJECT_DIR}}

## Your Mission

Execute Phases 1-4 of the AIDA pipeline:

### Phase 1: Extraction & Architecture
1. Analyze user requirements thoroughly
2. Extract core features and constraints
3. Design high-level architecture
4. Write .aida/artifacts/requirements/extraction.md

### Phase 2: Structure
1. Define directory structure
2. Create data schemas
3. Define API contracts
4. Write .aida/artifacts/designs/structure.md

### Phase 3: Alignment
1. Verify requirements consistency
2. Check for conflicts or gaps
3. Write .aida/artifacts/alignment.md

### Phase 4: Verification & Output
1. Review all specs for completeness
2. Write final specifications:
   - .aida/specs/{{PROJECT}}-requirements.md (comprehensive)
   - .aida/specs/{{PROJECT}}-design.md (technical design)
   - .aida/specs/{{PROJECT}}-tasks.md (implementation tasks)

## Player Delegation
For parallel tasks, spawn player subagents using Task tool with model: haiku.
Read agents/player.md for player protocol.

## Completion Checklist
Before completing, verify:
- [ ] .aida/specs/{{PROJECT}}-requirements.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-design.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-tasks.md exists
- [ ] .aida/results/spec-complete.json written

## Completion Report
Write to .aida/results/spec-complete.json:
{
  "task_id": "spec-{{PROJECT}}",
  "status": "completed",
  "completed_at": "ISO8601",
  "outputs": {
    "requirements": ".aida/specs/{{PROJECT}}-requirements.md",
    "design": ".aida/specs/{{PROJECT}}-design.md",
    "tasks": ".aida/specs/{{PROJECT}}-tasks.md"
  },
  "summary": "Specification phases 1-4 complete"
}

Update .aida/state/session.json with:
- current_phase: "IMPL_PHASE"
- phase: 5
- leaders.spec: "completed"
```

</MANDATORY_ACTION>

**STOP: Do NOT proceed to Step 4 until Task tool has been invoked and Leader-Spec completes.**

---

### Step 4: Update Session State

After Leader-Spec completes, update `.aida/state/session.json`:
```json
{
  "current_phase": "IMPL_PHASE",
  "phase": 5,
  "leaders": {
    "spec": "completed",
    "impl": "pending"
  },
  "active_agents": [],
  "completed_tasks": ["spec-requirements", "spec-design", "spec-tasks"]
}
```

---

### Step 5: Create Kanban

Create/update `.aida/kanban.md`:
```markdown
# Project Kanban - {{PROJECT_NAME}}

## Phase 1: Extraction - COMPLETE
- [x] Session initialized
- [x] Requirements extraction
- [x] Architecture design

## Phase 2: Structure - COMPLETE
- [x] Directory structure
- [x] Data schemas
- [x] API contracts

## Phase 3: Alignment - COMPLETE
- [x] Requirements consistency verified

## Phase 4: Verification - COMPLETE
- [x] Spec review complete
- [x] Final specs written

## Phase 5: Implementation - PENDING
- [ ] Backend implementation (TDD)
- [ ] Frontend implementation (TDD)
- [ ] Docker environment
- [ ] Quality gates verification

Next: Run /aida:work to start implementation phase
```

---

## Output

On success:
```
AIDA Pipeline Started

Session: <SESSION_ID>
Project: <PROJECT_NAME>
Phase: Spec phases complete, ready for implementation

Specifications generated:
- .aida/specs/{{PROJECT}}-requirements.md
- .aida/specs/{{PROJECT}}-design.md
- .aida/specs/{{PROJECT}}-tasks.md

Next steps:
- Review generated specifications
- Run /aida:work to start implementation
- Or run /aida:status for current status
```

---

## Multi-Agent Architecture

```
/aida:start
    |
    v
[You] --> Task tool --> [Leader-Spec]
                             |
                             +--> Task tool --> [Player] (haiku, parallel)
                             +--> Task tool --> [Player] (haiku, parallel)
                             |
                             v
                        .aida/specs/
```

---

## CRITICAL REQUIREMENTS

1. **Task tool MUST be invoked** - Leader-Spec runs as a subagent via Task tool
2. **Wait for completion** - `run_in_background: false` ensures specs are ready
3. **Verify outputs exist** - Check spec files were actually created
4. **File-based state** - All state persists in .aida/
5. **Player delegation** - Leader-Spec spawns Players for parallel work

---

## Validation Checkpoint

Before reporting success, verify:

```bash
# Check spec files exist
ls -la .aida/specs/
test -f .aida/specs/*-requirements.md
test -f .aida/specs/*-design.md
test -f .aida/specs/*-tasks.md

# Validate output structure
./scripts/validate-outputs.sh {{PROJECT}} spec
```

If validation fails, the pipeline has not started correctly.
