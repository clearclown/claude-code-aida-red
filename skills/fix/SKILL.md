---
name: aida:fix
description: |
  AIDA Fix - Fix existing project to meet all quality gates.
  Takes a partially-built project and iterates until all 19 gates pass.
  Useful for completing interrupted implementations or improving test coverage.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/hooks/stop/quality-gate-enforcer.sh"
          timeout: 300
---

# AIDA Fix

Fix an existing project to meet all 19 quality gates.

## Usage

```
/aida:fix <project-name>
```

Example:
```
/aida:fix twitter-clone
```

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

This command takes an existing (possibly incomplete) project and fixes it to pass all quality gates.

---

## Step 1: Validate Project Exists

Check project directory:

```bash
ls -la ./
ls -la ./backend/
ls -la ./frontend/
```

**If project doesn't exist:**
```
Project {{PROJECT}} not found.

Available projects:
$(ls ./)

To create a new project:
  /aida "Your project description"
```

---

## Step 2: Run Quality Gates (Diagnostic)

Run quality gates to identify failures:

```bash
./scripts/quality-gates.sh {{PROJECT}} 2>&1 | tee /tmp/gate-diagnostic.log
```

Parse the output to identify:
- Which gates PASSED
- Which gates FAILED
- Specific error messages

---

## Step 3: Create Fix Plan

Based on gate failures, create a prioritized fix plan:

### Gate 1-2 (Backend Build/Tests) Failures:
- Syntax errors in Go code
- Missing dependencies
- Failing tests

### Gate 3-4 (Frontend Build/Tests) Failures:
- TypeScript errors
- Missing packages
- Failing component tests

### Gate 5-7 (Docker) Failures:
- Dockerfile issues
- docker-compose.yml problems
- Health check failures

### Gate 8 (API Coverage) Failures:
- Need more handler functions
- Missing endpoints

### Gate 9 (Frontend Features) Failures:
- Need more pages
- Missing routing
- No API client

### Gate 10 (Integration) Failures:
- Frontend/Backend not connected
- Missing CORS
- No Docker links

### Gate 11 (Backend Test Count < 80) Failures:
- Add more unit tests
- Add integration tests
- Add edge case tests

### Gate 12 (Frontend Test Count < 100) Failures:
- Add component tests
- Add context tests
- Add API client tests

### Gate 13 (Empty Array Pattern) Failures:
- Replace `var slice []T` with `make([]T, 0)`
- Ensure JSON returns `[]` not `null`

### Gate 14 (Backend Coverage < 75%) Failures:
- Add tests for uncovered code
- Focus on handlers and services

### Gate 15-18 (E2E/Design) Failures:
- Add Playwright tests
- Improve UI components
- Add more E2E scenarios

### Gate 19 (E2E Execution) Failures:
- Fix Playwright configuration
- Update selectors
- Fix timing issues

---

## Step 4: Execute Fixes

For each failure category, either:

### A. Fix Directly (Minor Issues)
- Syntax errors
- Missing imports
- Configuration issues
- Small code changes (<20 lines)

### B. Spawn Player (Major Issues)

**Backend Player for test additions:**
```
Task tool:
  description: "Backend Player: Add Tests for Coverage"
  subagent_type: "general-purpose"
  model: "sonnet"
  prompt: |
    You are AIDA Backend Player in FIX mode.

    ## Current State
    Project: {{PROJECT}}
    Location: ./backend/

    ## Problem
    {{SPECIFIC_GATE_FAILURE}}

    ## Your Task
    {{SPECIFIC_FIX_INSTRUCTIONS}}

    ## Requirements
    - Follow TDD (write test first, then implementation)
    - Run `go test ./...` after each change
    - Achieve minimum 80 tests, 75% coverage

    ## Completion
    Write results to .aida/results/fix-backend-{{PROJECT}}.json
```

**Frontend Player for test additions:**
```
Task tool:
  description: "Frontend Player: Add Tests for Coverage"
  subagent_type: "general-purpose"
  model: "sonnet"
  prompt: |
    You are AIDA Frontend Player in FIX mode.

    ## Current State
    Project: {{PROJECT}}
    Location: ./frontend/

    ## Problem
    {{SPECIFIC_GATE_FAILURE}}

    ## Your Task
    {{SPECIFIC_FIX_INSTRUCTIONS}}

    ## Requirements
    - Follow TDD
    - Run `pnpm test -- --run` after each change
    - Achieve minimum 100 tests, 70% coverage
    - Ensure E2E tests pass

    ## Completion
    Write results to .aida/results/fix-frontend-{{PROJECT}}.json
```

---

## Step 5: Iterate Until All Gates Pass

```
┌─────────────────────────────────────────────────────────────────┐
│  FIX LOOP (ralph-loop style)                                     │
│                                                                  │
│  1. RUN GATES → ./scripts/quality-gates.sh {{PROJECT}}          │
│                                                                  │
│  2. PARSE OUTPUT → Which gates failed?                          │
│                                                                  │
│  3. FOR EACH FAILURE:                                            │
│     → Determine fix strategy                                     │
│     → Apply fix (direct or via Player)                          │
│     → Verify fix worked                                          │
│                                                                  │
│  4. RE-RUN GATES                                                 │
│                                                                  │
│  5. IF ALL 19 PASS → DONE                                        │
│     ELSE → GOTO step 3                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 6: Run Docker + E2E Verification

After basic gates pass, verify Docker and E2E:

```bash
# Start Docker environment
podman-compose up -d --build  # or docker compose

# Wait for services
sleep 30

# Health checks
curl -sf http://localhost:8080/health
curl -sf http://localhost:5173/

# Run E2E tests
cd frontend
E2E_BASE_URL=http://localhost:5173 pnpm test:e2e

# Cleanup
cd ..
podman-compose down
```

---

## Step 7: Update Session and Kanban

After all gates pass:

**Update session.json:**
```json
{
  "current_phase": "COMPLETED",
  "quality_gates_passed": true,
  "fixed_at": "<ISO8601>",
  "fix_summary": {
    "gates_fixed": ["Gate 11", "Gate 12", "Gate 19"],
    "tests_added": 45,
    "coverage_improvement": "68% → 83%"
  }
}
```

**Update kanban.md:**
```markdown
## Status: COMPLETED ✅ (Fixed)

## Quality Gates - ALL 19 PASSED ✅
- [x] Gate 1-18: (existing gates)
- [x] Gate 19: E2E Test Execution (Playwright)

## Fix Summary
- Fixed at: {{TIMESTAMP}}
- Gates fixed: {{LIST}}
- Tests added: {{COUNT}}
```

---

## Step 8: Report Completion

```
AIDA Fix Complete

Project: {{PROJECT}}
Duration: {{DURATION}}

Gates Fixed:
- Gate 11: Backend Test Count (50 → 85)
- Gate 12: Frontend Test Count (80 → 110)
- Gate 14: Backend Coverage (65% → 78%)
- Gate 19: E2E Test Execution (PASS)

Quality Gates: 19/19 PASSED

To run the project:
  docker compose up -d
  open http://localhost:5173
```

---

## Common Fix Patterns

### Adding Backend Tests Quickly

Focus on table-driven tests for high coverage:

```go
func TestHandler_AllCases(t *testing.T) {
    tests := []struct {
        name           string
        input          string
        expectedStatus int
    }{
        {"valid", `{"field":"value"}`, 200},
        {"empty", ``, 400},
        {"invalid json", `{bad}`, 400},
        // Add 10+ cases for quick coverage boost
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // test implementation
        })
    }
}
```

### Adding Frontend Tests Quickly

Focus on render and interaction tests:

```tsx
describe('Component', () => {
  it('renders correctly', () => { ... });
  it('handles click', () => { ... });
  it('shows loading state', () => { ... });
  it('shows error state', () => { ... });
  it('handles empty data', () => { ... });
  // 5 tests per component = quick coverage
});
```

### Fixing E2E Test Failures

Common issues:
1. **Selector not found** → Update to use `getByRole` or `getByText`
2. **Timeout** → Add explicit waits
3. **Network error** → Ensure backend is running
4. **State pollution** → Add proper test isolation

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida` | Start new project from scratch |
| `/aida:resume` | Continue from last session state |
| `/aida:status` | Check current state |
