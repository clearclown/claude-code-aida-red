---
description: Execute current phase tasks with Task tool delegation
---

# AIDA Work

Execute tasks for the current pipeline phase using Task tool to spawn appropriate leaders.

## Usage

```
/aida:work
```

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

---

### Step 1: Read Current State

Read `.aida/state/session.json` and determine:
- `current_phase`: "SPEC_PHASE" or "IMPL_PHASE" or "COMPLETED"
- `phase`: 1-5 (numeric phase indicator)
- `project_name`: Name of the project
- `user_request`: Original user request
- `project_dir`: Directory for project code output

**If no session exists, check for checkpoint:**

```bash
# Check for available checkpoints
ls .aida/checkpoints/*.json 2>/dev/null
```

If checkpoints exist:
```
No active session, but checkpoint found.

Available checkpoints:
  - twitter-clone_20260110_123456

To restore: ./scripts/checkpoint.sh restore twitter-clone
To start fresh: /aida:start "project description"
```

**If no session and no checkpoints:**
```
No active session found.

Run: /aida:start "project description"
```
**STOP HERE** if no session.

---

### Step 2: Check Phase and Dispatch

#### If `current_phase` == "COMPLETED":

```
Pipeline already completed.

Session: {{SESSION_ID}}
Project: {{PROJECT_NAME}}
Status: Completed

Results:
- Specs: .aida/specs/{{PROJECT}}-*.md
- Project: {{PROJECT_DIR}}/
- Quality Report: .aida/results/impl-complete.json

To run quality gates:
  ./scripts/quality-gates.sh {{PROJECT}}

To start new pipeline:
  /aida:start "new project description"
```

**STOP HERE** if completed.

---

#### If `current_phase` == "SPEC_PHASE" (Phases 1-4):

<MANDATORY_ACTION id="launch-leader-spec">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Do NOT just describe the Task tool call - actually execute it.

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Spec: Continue Phase {{PHASE}}" |
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
- Current Phase: {{PHASE}}
- User Request: {{USER_REQUEST}}
- Working Directory: {{CWD}}
- Project Directory: {{PROJECT_DIR}}

## Phase Definitions
- Phase 1: Extraction & Architecture
- Phase 2: Structure & Schema
- Phase 3: Alignment & Consistency
- Phase 4: Verification & Finalization

## Your Mission

Continue from where previous work stopped:
1. Check .aida/artifacts/ for existing work
2. Complete current phase {{PHASE}} tasks
3. When phase complete, advance to next phase
4. After Phase 4, write final specs:
   - .aida/specs/{{PROJECT}}-requirements.md
   - .aida/specs/{{PROJECT}}-design.md
   - .aida/specs/{{PROJECT}}-tasks.md

## Player Delegation
For parallel tasks, spawn players using Task tool:
- subagent_type: "general-purpose"
- model: "haiku"
- Read agents/player.md for player protocol

## Completion Checklist
Before completing:
- [ ] All phase 1-4 work verified
- [ ] .aida/specs/{{PROJECT}}-requirements.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-design.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-tasks.md exists

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

Update .aida/state/session.json:
- current_phase: "IMPL_PHASE"
- phase: 5
- leaders.spec: "completed"
```

</MANDATORY_ACTION>

**STOP: Wait for Task tool completion before proceeding.**

---

#### If `current_phase` == "IMPL_PHASE" (Phase 5):

**Pre-flight Check:** Before launching Leader-Impl, verify specs exist:

```bash
test -f .aida/specs/*-requirements.md || echo "ERROR: Requirements missing"
test -f .aida/specs/*-design.md || echo "ERROR: Design missing"
test -f .aida/specs/*-tasks.md || echo "ERROR: Tasks missing"
```

If any spec is missing, report error and suggest `/aida:work` to complete specs first.

<MANDATORY_ACTION id="launch-leader-impl">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Do NOT just describe the Task tool call - actually execute it.

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Impl: TDD Implementation Phase" |
| subagent_type | "general-purpose" |
| model | "sonnet" |
| run_in_background | false |
| prompt | See below |

**Task Prompt:**

```
You are AIDA Leader-Impl agent.

## CRITICAL INSTRUCTION
Read and follow the full instructions in: agents/leader-impl.md

## Current Session
- Session ID: {{SESSION_ID}}
- Project: {{PROJECT_NAME}}
- Working Directory: {{CWD}}
- Project Directory: {{PROJECT_DIR}}

## Specifications (MUST READ)
- .aida/specs/{{PROJECT}}-requirements.md
- .aida/specs/{{PROJECT}}-design.md
- .aida/specs/{{PROJECT}}-tasks.md

## TDD Protocol (MANDATORY)
Every implementation MUST follow:
1. RED: Write failing test FIRST
2. GREEN: Minimal code to pass test
3. REFACTOR: Clean up while tests pass

NO code without tests. NO tests without running them.

## Player Delegation
For each implementation component, spawn separate Players:

### Backend Player
- subagent_type: "general-purpose"
- model: "haiku"
- Must produce: {{PROJECT_DIR}}/backend/
- Must have: minimum 5 test files (*_test.go)

### Frontend Player (MANDATORY - SEPARATE)
- subagent_type: "general-purpose"
- model: "haiku"
- Must initialize with: npm create vite@latest frontend -- --template react-ts
- Must produce: {{PROJECT_DIR}}/frontend/
- Must have: minimum 3 test files (*.test.tsx)

### Docker Player
- subagent_type: "general-purpose"
- model: "haiku"
- Must produce: docker-compose.yml, Dockerfiles

## Quality Gates (ALL MUST PASS)
After all players complete, run verification:
./scripts/quality-gates.sh {{PROJECT}}

Gates:
1. Backend Build: go build ./...
2. Backend Tests: go test ./...
3. Frontend Build: npm run build
4. Frontend Tests: npm test -- --run
5. Docker Build: docker compose build
6. Docker Run: docker compose up -d
7. Health Check: curl localhost:8080/health

## Completion Checklist
Before completing:
- [ ] Backend directory has working Go code
- [ ] Frontend directory has working React code
- [ ] Docker compose works
- [ ] ALL quality gates pass
- [ ] Test output captured in report

## Completion Report
Write to .aida/results/impl-complete.json:
{
  "task_id": "impl-{{PROJECT}}",
  "status": "completed",
  "completed_at": "ISO8601",
  "project_path": "{{PROJECT_DIR}}/",
  "quality_gates": {
    "backend_build": true,
    "backend_tests": true,
    "frontend_build": true,
    "frontend_tests": true,
    "docker_build": true,
    "docker_run": true,
    "health_check": true,
    "all_passed": true
  },
  "verification": {
    "backend": {
      "test_count": N,
      "test_output": "..."
    },
    "frontend": {
      "test_count": N,
      "test_output": "..."
    }
  },
  "summary": "Implementation complete, all quality gates passed"
}

Update .aida/state/session.json:
- current_phase: "COMPLETED"
- leaders.impl: "completed"
```

</MANDATORY_ACTION>

**STOP: Wait for Task tool completion before proceeding.**

---

### Step 3: Post-Completion Verification

After Leader completes, verify outputs:

#### For Spec Phase Completion:
```bash
./scripts/validate-outputs.sh {{PROJECT}} spec
```

#### For Impl Phase Completion:
```bash
./scripts/validate-outputs.sh {{PROJECT}} impl
./scripts/verify-tdd.sh {{PROJECT}} all
./scripts/quality-gates.sh {{PROJECT}}
```

---

### Step 4: Update Kanban

Update `.aida/kanban.md` with current status:

```markdown
# Project Kanban - {{PROJECT_NAME}}

## Current Status: {{CURRENT_PHASE}}

## Spec Phase
- [x/pending] Phase 1: Extraction
- [x/pending] Phase 2: Structure
- [x/pending] Phase 3: Alignment
- [x/pending] Phase 4: Verification

## Impl Phase
- [x/pending] Backend Implementation
- [x/pending] Frontend Implementation
- [x/pending] Docker Setup
- [x/pending] Quality Gates

## Quality Gates
- [x/pending] Backend Build
- [x/pending] Backend Tests
- [x/pending] Frontend Build
- [x/pending] Frontend Tests
- [x/pending] Docker Build
- [x/pending] Docker Run
- [x/pending] Health Check
```

---

## Output Format

### Work Started (Spec Phase)

```
AIDA Work - Spec Phase {{PHASE}}

Session: {{SESSION_ID}}
Project: {{PROJECT_NAME}}
Leader: Leader-Spec (sonnet)

Task tool invoked. Leader-Spec is working on Phase {{PHASE}}.

Phase {{PHASE}} Tasks:
- [description of phase tasks]

Monitor Progress:
- .aida/state/session.json
- .aida/artifacts/

When complete, run /aida:work again to continue.
```

### Work Started (Impl Phase)

```
AIDA Work - Implementation Phase

Session: {{SESSION_ID}}
Project: {{PROJECT_NAME}}
Leader: Leader-Impl (sonnet)
Mode: TDD (Test-Driven Development)

Task tool invoked. Leader-Impl is orchestrating implementation.

TDD Cycle: RED -> GREEN -> REFACTOR

Quality Gates Required:
1. Backend Build
2. Backend Tests
3. Frontend Build
4. Frontend Tests
5. Docker Build
6. Docker Run
7. Health Check

Monitor Progress:
- .aida/state/session.json
- {{PROJECT_DIR}}/

Verify completion:
  ./scripts/quality-gates.sh {{PROJECT}}
```

---

## Multi-Agent Architecture

```
/aida:work
    |
    +-- Read session.json
    |
    +-- SPEC_PHASE? -----> Task tool -----> [Leader-Spec]
    |   (phases 1-4)                              |
    |                                             +--> Task tool --> [Player] (haiku)
    |                                             +--> Task tool --> [Player] (haiku)
    |
    +-- IMPL_PHASE? -----> Task tool -----> [Leader-Impl]
        (phase 5)                                 |
                                                  +--> Task tool --> [Backend Player]
                                                  +--> Task tool --> [Frontend Player]
                                                  +--> Task tool --> [Docker Player]
                                                  |
                                                  +--> quality-gates.sh (verification)
```

---

## CRITICAL REQUIREMENTS

1. **Task tool MUST be invoked** - Leaders run as subagents via Task tool
2. **Phase-aware dispatch** - Check session.json to determine correct leader
3. **Wait for completion** - `run_in_background: false` ensures sequential execution
4. **Quality gates** - Implementation phase MUST pass all 7 gates
5. **TDD mandatory** - No code without tests in impl phase
6. **Verify outputs** - Use validation scripts to confirm completion
7. **Model selection** - Leaders use `sonnet`, Players use `haiku`

---

## Error Recovery

### Leader Fails to Complete

1. Check `.aida/errors/` for error reports
2. Read leader's partial output
3. Re-run `/aida:work` to resume from checkpoint

### Quality Gates Fail

1. Identify failed gate from output
2. Fix the issue (or have Leader-Impl fix it)
3. Re-run: `./scripts/quality-gates.sh {{PROJECT}}`

### Missing Specs for Impl Phase

```
ERROR: Cannot start implementation - specs missing.

Required files:
- .aida/specs/{{PROJECT}}-requirements.md
- .aida/specs/{{PROJECT}}-design.md
- .aida/specs/{{PROJECT}}-tasks.md

Run /aida:work to complete spec phase first.
```
