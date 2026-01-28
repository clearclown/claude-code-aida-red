---
name: aida:resume
description: |
  AIDA Resume - Continue from last session state.
  Reads session.json and resumes from where AIDA left off.
  Useful for continuing interrupted implementations.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/hooks/stop/quality-gate-enforcer.sh"
          timeout: 300
---

# AIDA Resume

Continue AIDA execution from the last saved session state.

## Usage

```
/aida:resume
```

Or with specific project:
```
/aida:resume twitter-clone
```

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

---

## Step 1: Read Session State

Read `.aida/state/session.json` to understand current state:

```bash
cat .aida/state/session.json
```

Extract key information:
- `current_phase` - Which phase are we in?
- `project_name` - What project?
- `pending_tasks` - What's left to do?
- `completed_tasks` - What's already done?
- `quality_gates_passed` - Have gates passed?

---

## Step 2: Determine Resume Point

Based on `current_phase`:

| Phase | Action |
|-------|--------|
| `SPEC_PHASE` | Resume specification generation (Phases 1-4) |
| `IMPL_PHASE` | Resume implementation (Phase 5) |
| `COMPLETED` | Project already done - show status |
| Missing/Empty | No session - suggest `/aida` instead |

---

## Step 3: Resume Based on Phase

### If SPEC_PHASE:

1. Check which spec outputs exist:
   - `.aida/specs/{{PROJECT}}-requirements.md`
   - `.aida/specs/{{PROJECT}}-design.md`
   - `.aida/specs/{{PROJECT}}-tasks.md`

2. If any missing, launch Leader-Spec to complete:
   ```
   Task tool:
     description: "Leader-Spec: Complete Remaining Phases"
     subagent_type: "general-purpose"
     model: "sonnet"
     prompt: [see leader-spec.md]
   ```

3. After completion, transition to IMPL_PHASE

### If IMPL_PHASE:

1. Check what implementation exists:
   ```bash
   ls -la ./backend/
   ls -la ./frontend/
   ls -la ./docker-compose.yml
   ```

2. Run quality gates to see what's failing:
   ```bash
   ./scripts/quality-gates.sh {{PROJECT}}
   ```

3. Based on failures, launch appropriate Players:
   - Backend tests failing → Launch Backend Player
   - Frontend tests failing → Launch Frontend Player
   - Docker failing → Launch Docker Player
   - E2E failing → Fix E2E tests

4. Iterate until ALL gates pass

### If COMPLETED:

Show project status and exit:
```
Project {{PROJECT}} is already complete.

Quality Gates: ALL PASSED
Location: ./

To run the project:
  docker compose up -d
```

---

## Step 4: Continue with Quality Gate Loop

After resuming, follow the standard quality gate iteration:

```
┌─────────────────────────────────────────────────────────────────┐
│  1. RUN GATES → ./scripts/quality-gates.sh {{PROJECT}}          │
│                                                                  │
│  2. IF FAILED:                                                   │
│     → Identify failing gates                                     │
│     → Fix issues (add tests, fix code, etc.)                     │
│     → GOTO step 1                                                │
│                                                                  │
│  3. IF ALL PASS:                                                 │
│     → Update session.json: quality_gates_passed = true           │
│     → Update kanban.md                                           │
│     → Output "DONE"                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 5: Update Session State

After each action, update `.aida/state/session.json`:

```json
{
  "resumed_at": "<ISO8601>",
  "resume_count": N+1
}
```

---

## Example Session Read

```json
{
  "session_id": "aida-20260111-twitter-clone",
  "current_phase": "IMPL_PHASE",
  "project_name": "twitter-clone",
  "pending_tasks": ["impl-frontend", "quality-gates"],
  "completed_tasks": ["spec-requirements", "spec-design", "spec-tasks", "impl-backend"],
  "quality_gates_passed": false
}
```

This tells us:
- Phase: Implementation (Phase 5)
- Backend is done
- Frontend is pending
- Quality gates haven't passed yet

Resume action: Launch Frontend Player, then run quality gates.

---

## Error Handling

### No Session File

```
No active AIDA session found.

To start a new project:
  /aida "Your project description"

To check status:
  /aida:status
```

### Corrupted Session

If session.json is malformed:
1. Try to read kanban.md for state
2. Check ./ for existing implementation
3. Reconstruct session state from artifacts

### Project Directory Missing

If ./{{PROJECT}} doesn't exist but session says IMPL_PHASE:
1. Reset to SPEC_PHASE
2. Verify specs exist
3. Re-launch implementation

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida` | Start new project from scratch |
| `/aida:status` | Check current state without resuming |
| `/aida:fix` | Fix existing project to meet quality gates |
