---
name: pipeline
description: |
  Complete project generation pipeline with Task tool multi-agent orchestration.
  Requirements -> Design -> Tasks -> Project -> Implementation.
tools: Read, Write, Edit, Glob, Bash, Task
---

# AIDA Pipeline Skill

Complete automation pipeline for project generation using Task tool for multi-agent orchestration.

## Overview

This skill executes the full AIDA pipeline:

1. **Phases 1-4**: Specification (via Leader-Spec + Players)
2. **Phase 5**: Implementation (via Leader-Impl + TDD Players)

## Multi-Agent Architecture

```
[Pipeline Skill]
    |
    +-- Task tool --> [Leader-Spec]
    |                      |
    |                      +-- Task tool --> [Player] (haiku)
    |                      +-- Task tool --> [Player] (haiku)
    |                      |
    |                      +--> .aida/specs/
    |
    +-- Task tool --> [Leader-Impl]
                           |
                           +-- Task tool --> [TDD Player] (haiku)
                           +-- Task tool --> [TDD Player] (haiku)
                           |
                           +--> [PROJECT]/
```

## Execution Flow

### Step 1: Initialize Session

```bash
mkdir -p .aida/state .aida/checkpoints .aida/artifacts/requirements .aida/artifacts/designs .aida/tasks .aida/results .aida/specs
```

Create session state:
```json
{
  "session_id": "<UUID>",
  "started_at": "<ISO8601>",
  "mode": "pipeline",
  "phase": 1,
  "user_request": "<REQUEST>",
  "project_name": "<PROJECT>"
}
```

### Step 2: Launch Leader-Spec (Phases 1-4)

**Use Task tool with these parameters:**

| Parameter | Value |
|-----------|-------|
| description | "Leader-Spec: specification phases" |
| subagent_type | "general-purpose" |
| run_in_background | false |
| prompt | See below |

**Prompt:**
```
You are AIDA Leader-Spec agent.

Read instructions: agents/leader-spec.md

Project: [PROJECT_NAME]
User Request: [USER_REQUEST]

Execute Phases 1-4:

Phase 1: Extraction & Architecture
- Spawn players for requirements and architecture
- Output: .aida/artifacts/requirements/

Phase 2: Structure & Schema
- Spawn players for structure and schema design
- Output: .aida/artifacts/designs/

Phase 3: Alignment
- Cross-check all artifacts
- Output: .aida/artifacts/alignment.md

Phase 4: Verification
- Consolidate final specs
- Output: .aida/specs/requirements.md
- Output: .aida/specs/design.md
- Output: .aida/specs/tasks.md

For parallel work, use Task tool with model: haiku.

When complete:
- Update .aida/state/session.json with phase: 5
- Write .aida/results/spec-complete.json
```

### Step 3: Launch Leader-Impl (Phase 5)

**Use Task tool with these parameters:**

| Parameter | Value |
|-----------|-------|
| description | "Leader-Impl: TDD implementation" |
| subagent_type | "general-purpose" |
| run_in_background | false |
| prompt | See below |

**Prompt:**
```
You are AIDA Leader-Impl agent.

Read instructions: agents/leader-impl.md

Project: [PROJECT_NAME]

Read specifications:
- .aida/specs/requirements.md
- .aida/specs/design.md
- .aida/specs/tasks.md

Execute Phase 5: TDD Implementation

1. Initialize project:
   mkdir -p [PROJECT_NAME]/src
   mkdir -p [PROJECT_NAME]/tests

2. For each task in tasks.md, spawn TDD player:
   - Use Task tool with model: haiku
   - Include TDD instructions (RED-GREEN-REFACTOR)

3. Quality gates:
   - All tests pass
   - Build succeeds
   - Coverage >= 80%

When complete:
- Update .aida/state/session.json with phase: "completed"
- Write .aida/results/impl-complete.json
```

### Step 4: Report Completion

```
AIDA Pipeline Complete

Session: [SESSION_ID]
Project: [PROJECT_NAME]

Artifacts:
- Specs: .aida/specs/
  - requirements.md
  - design.md
  - tasks.md
- Project: [PROJECT_NAME]/

Test Results:
- All tests passed
- Coverage: XX%

Next Steps:
cd [PROJECT_NAME]
npm install
npm run dev
```

## Phase Details

### Phase 1: Extraction & Architecture

Player tasks (parallel):
1. Extract functional requirements
2. Extract non-functional requirements
3. Design high-level architecture

Output:
- `.aida/artifacts/requirements/extraction.md`
- `.aida/artifacts/designs/architecture.md`

### Phase 2: Structure & Schema

Player tasks (parallel):
1. Define directory structure
2. Design data schemas
3. Create API contracts

Output:
- `.aida/artifacts/designs/structure.md`
- `.aida/artifacts/designs/schemas.md`
- `.aida/artifacts/designs/api.md`

### Phase 3: Alignment

Tasks:
1. Cross-check requirements
2. Verify architecture supports features
3. Identify gaps

Output:
- `.aida/artifacts/alignment.md`

### Phase 4: Verification

Tasks:
1. Final review
2. Consolidate specs
3. Generate task breakdown

Output:
- `.aida/specs/requirements.md`
- `.aida/specs/design.md`
- `.aida/specs/tasks.md`

### Phase 5: TDD Implementation

For Next.js + TypeScript + Prisma project:

```bash
cd [PROJECT_NAME]
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --yes
npm install prisma @prisma/client
npx prisma init
```

TDD Player tasks (parallel):
1. Implement feature 1 (RED-GREEN-REFACTOR)
2. Implement feature 2 (RED-GREEN-REFACTOR)
3. Implement feature 3 (RED-GREEN-REFACTOR)

Output:
- `[PROJECT_NAME]/`

## Error Handling

If a phase fails:

1. Check `.aida/results/` for error reports
2. Review `.aida/state/session.json`
3. Options:
   - Fix issue and use `/aida:work` to continue
   - Restart with `/aida:pipeline`

## Notes

1. **Sequential phases** - Wait for each Leader to complete
2. **Parallel players** - Leaders spawn multiple players in parallel
3. **TDD enforced** - Phase 5 uses RED-GREEN-REFACTOR
4. **File-based state** - All state in .aida/
5. **Task tool required** - Subagent orchestration
