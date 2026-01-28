---
description: Execute complete AIDA pipeline with multi-agent orchestration via Task tool
argument-hint: <project description>
---

# AIDA Pipeline

Execute the complete AIDA pipeline from start to finish with multi-agent orchestration.

## Usage

```
/aida:pipeline "Create a Twitter clone application"
```

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

---

## Pipeline Overview

```
User Request
     |
     v
[You] ───────────────────────────────────────────────────────────────────
     |
     +── Step 1: Initialize ─────────────────────────────────────────────
     |
     +── Step 2: Launch Leader-Spec ─── Task tool ──> [Leader-Spec]
     |                                                      |
     |                                                      +──> [Players]
     |
     +── Step 3: Validate Specs ─────────────────────────────────────────
     |
     +── Step 4: Launch Leader-Impl ─── Task tool ──> [Leader-Impl]
     |                                                      |
     |                                                      +──> [Backend Player]
     |                                                      +──> [Frontend Player]
     |                                                      +──> [Docker Player]
     |
     +── Step 5: Run Quality Gates ──────────────────────────────────────
     |
     +── Step 6: Report Completion ──────────────────────────────────────
     |
     v
Completed Project (ALL 7 QUALITY GATES PASSED)
```

---

## Step 1: Initialize Session

Create output directories:
```bash
mkdir -p .aida/state .aida/checkpoints .aida/artifacts/requirements .aida/artifacts/designs .aida/tasks .aida/results .aida/specs .aida/errors
```

Derive project name from user request (kebab-case, max 20 chars):
- "Create a Twitter clone" → `twitter-clone`
- "Build todo app with auth" → `todo-app`

Create `.aida/state/session.json`:
```json
{
  "session_id": "<UUID>",
  "started_at": "<ISO8601>",
  "mode": "pipeline",
  "current_phase": "SPEC_PHASE",
  "phase": 1,
  "phase_name": "extraction",
  "user_request": "$ARGUMENTS",
  "project_name": "<derived>",
  "phase_history": [
    {"phase": "INITIALIZING", "entered_at": "<ISO8601>", "exited_at": "<ISO8601>"}
  ],
  "leaders": {
    "spec": "pending",
    "impl": "pending"
  },
  "active_agents": [],
  "completed_tasks": [],
  "pending_tasks": ["spec-requirements", "spec-design", "spec-tasks", "impl-backend", "impl-frontend", "impl-docker", "quality-gates"]
}
```

Create initial `.aida/kanban.md`:
```markdown
# Project Kanban - {{PROJECT_NAME}}

## Current Status: SPEC_PHASE (Phase 1)

## Spec Phase
- [ ] Phase 1: Extraction & Architecture
- [ ] Phase 2: Structure & Schema
- [ ] Phase 3: Alignment
- [ ] Phase 4: Verification

## Impl Phase
- [ ] Backend Implementation (TDD)
- [ ] Frontend Implementation (TDD)
- [ ] Docker Setup

## Quality Gates (ALL MUST PASS)
- [ ] Gate 1: Backend Build
- [ ] Gate 2: Backend Tests
- [ ] Gate 3: Frontend Build
- [ ] Gate 4: Frontend Tests
- [ ] Gate 5: Docker Build
- [ ] Gate 6: Docker Run
- [ ] Gate 7: Health Check
```

---

## Step 2: Launch Leader-Spec (Phases 1-4)

<MANDATORY_ACTION id="launch-leader-spec">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Do NOT just describe the Task tool call - actually execute it.

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Spec: Full Specification Phases 1-4" |
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
- Mode: Pipeline (full automation)

## Your Mission

Execute ALL specification phases (1-4) completely:

### Phase 1: Extraction & Architecture
1. Analyze user request thoroughly
2. Extract core features and constraints
3. Identify non-functional requirements
4. Design high-level architecture
5. Write .aida/artifacts/requirements/extraction.md

### Phase 2: Structure
1. Define complete directory structure
2. Create data schemas and models
3. Define API contracts with endpoints
4. Write .aida/artifacts/designs/structure.md

### Phase 3: Alignment
1. Cross-check all requirements
2. Verify consistency between specs
3. Identify and resolve conflicts
4. Write .aida/artifacts/alignment.md

### Phase 4: Verification & Finalization
1. Final review of all specifications
2. Write comprehensive final specs:
   - .aida/specs/{{PROJECT}}-requirements.md (min 500 bytes)
   - .aida/specs/{{PROJECT}}-design.md (min 500 bytes)
   - .aida/specs/{{PROJECT}}-tasks.md

## Player Delegation
For parallel work, spawn players using Task tool:
- subagent_type: "general-purpose"
- model: "haiku"
- Read agents/player.md for protocol

## Completion Checklist
Before completing, VERIFY:
- [ ] .aida/specs/{{PROJECT}}-requirements.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-design.md exists (min 500 bytes)
- [ ] .aida/specs/{{PROJECT}}-tasks.md exists

## Completion Report
Write to .aida/results/spec-complete.json:
{
  "task_id": "spec-{{PROJECT}}",
  "status": "completed",
  "completed_at": "ISO8601",
  "phase_history": [1, 2, 3, 4],
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

**STOP: Do NOT proceed to Step 3 until Task tool has been invoked and Leader-Spec completes.**

---

## Step 3: Validate Specs

After Leader-Spec completes, validate outputs:

```bash
./scripts/validate-outputs.sh {{PROJECT}} spec
```

**Required files (ALL must exist):**
- `.aida/specs/{{PROJECT}}-requirements.md` (min 500 bytes)
- `.aida/specs/{{PROJECT}}-design.md` (min 500 bytes)
- `.aida/specs/{{PROJECT}}-tasks.md` (min 100 bytes)
- `.aida/results/spec-complete.json`

**If validation fails:**
1. Report missing files
2. Re-run Leader-Spec to complete missing specs
3. Do NOT proceed to implementation

**If validation passes:**
- Update session.json: `current_phase: "IMPL_PHASE"`, `phase: 5`
- Update kanban.md: Mark spec phases complete

---

## Step 4: Launch Leader-Impl (Phase 5)

<MANDATORY_ACTION id="launch-leader-impl">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Do NOT just describe the Task tool call - actually execute it.

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Impl: Full TDD Implementation" |
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
- Mode: Pipeline (full automation)

## Specifications (MUST READ FIRST)
- .aida/specs/{{PROJECT}}-requirements.md
- .aida/specs/{{PROJECT}}-design.md
- .aida/specs/{{PROJECT}}-tasks.md

## Your Mission

Execute Phase 5: TDD Implementation completely.

### TDD Protocol (MANDATORY)
Every implementation MUST follow:
1. RED: Write failing test FIRST
2. GREEN: Minimal code to pass test
3. REFACTOR: Clean up while tests pass

NO code without tests. Tests MUST run and pass.

### Player Delegation (MANDATORY - SPAWN ALL THREE)

#### Backend Player
- subagent_type: "general-purpose"
- model: "haiku"
- Task: Implement Go backend with TDD
- Must produce: {{PROJECT}}/backend/
- Requirements:
  - go.mod with proper module path
  - cmd/server/main.go entry point
  - internal/ with models, handlers, services, repositories
  - Minimum 5 test files (*_test.go)
  - All tests MUST pass

#### Frontend Player (MANDATORY - SEPARATE SPAWN)
- subagent_type: "general-purpose"
- model: "haiku"
- Task: Implement React frontend with TDD
- MUST initialize with: npm create vite@latest frontend -- --template react-ts
- Must produce: {{PROJECT}}/frontend/
- Requirements:
  - package.json with test scripts
  - vite.config.ts
  - src/ with components, pages, hooks
  - Minimum 3 test files (*.test.tsx)
  - All tests MUST pass

#### Docker Player
- subagent_type: "general-purpose"
- model: "haiku"
- Task: Create Docker environment
- Must produce:
  - {{PROJECT}}/docker-compose.yml
  - {{PROJECT}}/backend/Dockerfile
  - {{PROJECT}}/frontend/Dockerfile
- Use Podman-compatible images: docker.io/library/...

### Quality Gates (ALL MUST PASS)
After all players complete, run:
./scripts/quality-gates.sh {{PROJECT}}

Gates:
1. Backend Build: go build ./...
2. Backend Tests: go test ./...
3. Frontend Build: npm run build
4. Frontend Tests: npm test -- --run
5. Docker Build: docker compose build
6. Docker Run: docker compose up -d
7. Health Check: curl localhost:8080/health

### Completion Checklist
Before completing, VERIFY:
- [ ] Backend directory populated with Go code
- [ ] Backend has minimum 5 test files
- [ ] Backend tests pass
- [ ] Frontend directory populated with React code
- [ ] Frontend has minimum 3 test files
- [ ] Frontend tests pass
- [ ] Docker compose runs successfully
- [ ] ALL 7 quality gates pass

### Completion Report
Write to .aida/results/impl-complete.json:
{
  "task_id": "impl-{{PROJECT}}",
  "status": "completed",
  "completed_at": "ISO8601",
  "project_path": "{{PROJECT}}/",
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

**STOP: Do NOT proceed to Step 5 until Task tool has been invoked and Leader-Impl completes.**

---

## Step 5: Run Quality Gates

After Leader-Impl completes, run full quality gate verification:

```bash
./scripts/quality-gates.sh {{PROJECT}}
```

**All 7 gates MUST pass:**

| Gate | Command | Expected |
|------|---------|----------|
| 1 | `go build ./...` | Exit 0 |
| 2 | `go test ./...` | All pass |
| 3 | `npm run build` | Exit 0 |
| 4 | `npm test -- --run` | All pass |
| 5 | `docker compose build` | Exit 0 |
| 6 | `docker compose up -d` | Services running |
| 7 | `curl localhost:8080/health` | 200 OK |

**If any gate fails:**
1. Identify the failing gate
2. Analyze the error
3. Fix directly or re-spawn Leader-Impl to fix
4. Re-run: `./scripts/quality-gates.sh {{PROJECT}}`

**Do NOT report success unless ALL gates pass.**

---

## Step 6: Report Completion

After all quality gates pass, update kanban and report:

Update `.aida/kanban.md`:
```markdown
# Project Kanban - {{PROJECT_NAME}}

## Status: COMPLETED

## Spec Phase - COMPLETE
- [x] Phase 1: Extraction & Architecture
- [x] Phase 2: Structure & Schema
- [x] Phase 3: Alignment
- [x] Phase 4: Verification

## Impl Phase - COMPLETE
- [x] Backend Implementation (TDD)
- [x] Frontend Implementation (TDD)
- [x] Docker Setup

## Quality Gates - ALL PASSED
- [x] Gate 1: Backend Build
- [x] Gate 2: Backend Tests
- [x] Gate 3: Frontend Build
- [x] Gate 4: Frontend Tests
- [x] Gate 5: Docker Build
- [x] Gate 6: Docker Run
- [x] Gate 7: Health Check
```

Update `.aida/state/session.json`:
```json
{
  "current_phase": "COMPLETED",
  "completed_at": "<ISO8601>",
  "leaders": {
    "spec": "completed",
    "impl": "completed"
  },
  "quality_gates_passed": true
}
```

**Final Output:**

```
AIDA Pipeline Complete

Session: {{SESSION_ID}}
Project: {{PROJECT_NAME}}
Duration: {{DURATION}}

Artifacts Generated:
- Specs: .aida/specs/{{PROJECT}}-*.md
- Project: {{PROJECT}}/

Quality Gates: 7/7 PASSED
- Backend Build: PASS
- Backend Tests: PASS
- Frontend Build: PASS
- Frontend Tests: PASS
- Docker Build: PASS
- Docker Run: PASS
- Health Check: PASS

TDD Verification:
- Backend: {{N}} test files, all passing
- Frontend: {{N}} test files, all passing

To run the project:
  cd {{PROJECT}}
  docker compose up -d
  open http://localhost:5173

To verify quality gates again:
  ./scripts/quality-gates.sh {{PROJECT}}
```

---

## Multi-Agent Architecture

```
/aida:pipeline
    |
    +-- Initialize session
    |
    +-- Task tool (sonnet) -----> [Leader-Spec]
    |                                  |
    |                                  +-- Task tool (haiku) --> [Requirements Player]
    |                                  +-- Task tool (haiku) --> [Design Player]
    |                                  |
    |                                  +--> .aida/specs/
    |
    +-- Validate specs (./scripts/validate-outputs.sh)
    |
    +-- Task tool (sonnet) -----> [Leader-Impl]
    |                                  |
    |                                  +-- Task tool (haiku) --> [Backend Player]
    |                                  +-- Task tool (haiku) --> [Frontend Player]
    |                                  +-- Task tool (haiku) --> [Docker Player]
    |                                  |
    |                                  +--> projects/
    |
    +-- Quality Gates (./scripts/quality-gates.sh)
    |       |
    |       +-- Gate 1: Backend Build
    |       +-- Gate 2: Backend Tests
    |       +-- Gate 3: Frontend Build
    |       +-- Gate 4: Frontend Tests
    |       +-- Gate 5: Docker Build
    |       +-- Gate 6: Docker Run
    |       +-- Gate 7: Health Check
    |
    +-- Report completion
```

---

## CRITICAL REQUIREMENTS

1. **Task tool MUST be invoked** - Leaders run as subagents via Task tool
2. **Sequential execution** - Specs MUST complete before implementation starts
3. **All gates MUST pass** - No success report without 7/7 gates
4. **TDD mandatory** - All code must have tests, tests must run
5. **Frontend SEPARATE** - Frontend Player MUST be spawned separately from Backend
6. **Model selection** - Leaders use `sonnet`, Players use `haiku`
7. **Validation scripts** - Use provided scripts for verification

---

## Error Recovery

### Spec Phase Failure
1. Check .aida/errors/ for error reports
2. Check which spec files are missing
3. Re-run Leader-Spec with specific focus

### Impl Phase Failure
1. Identify which component failed (backend/frontend/docker)
2. Re-spawn that specific player
3. Re-run quality gates

### Quality Gate Failure
1. Read gate output to identify issue
2. Fix in project directory
3. Re-run: `./scripts/quality-gates.sh {{PROJECT}}`

### Complete Restart
```bash
rm -rf {{PROJECT}}
rm -rf .aida/specs/{{PROJECT}}-*
rm .aida/state/session.json
# Then run /aida:pipeline again
```

---

## Validation Commands

```bash
# Validate spec outputs
./scripts/validate-outputs.sh {{PROJECT}} spec

# Validate impl outputs
./scripts/validate-outputs.sh {{PROJECT}} impl

# Verify TDD compliance
./scripts/verify-tdd.sh {{PROJECT}} all

# Run all quality gates
./scripts/quality-gates.sh {{PROJECT}}

# Run quality gates without Docker
./scripts/quality-gates.sh {{PROJECT}} --skip-docker
```
