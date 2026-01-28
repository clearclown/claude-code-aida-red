---
name: aida:enhance
description: |
  Enhance existing projects based on documents or natural language instructions.
  Supports any document format, GitHub Issues, or direct specifications.
  Enforces TDD with 100% coverage target and prevents regression through quality gates.
  Uses multi-agent quality assurance with specialized Players.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/hooks/stop/enhance-gate.sh"
          timeout: 300
---

# AIDA Enhance

Enhance existing projects with new features, bug fixes, or improvements.

## Usage

```
# With specification document
/aida:enhance /path/to/project /path/to/spec.md

# With natural language instruction
/aida:enhance /path/to/project "Add user authentication with OAuth2"

# With GitHub Issue
/aida:enhance /path/to/project --issue https://github.com/org/repo/issues/123

# Interactive mode (asks for requirements)
/aida:enhance /path/to/project
```

---

## Enhanced Workflow Overview

```
/aida:enhance /path/to/project "specification"
  |
  +-- 1. Validate project + Run analysis (if needed)
  |
  +-- 2. Capture baseline (NEW)
  |     scripts/capture-baseline.sh
  |     Output: .aida/state/enhance-baseline.json
  |
  +-- 3. Generate reverse specs (NEW)
  |     scripts/generate-reverse-specs.sh
  |     Output: .aida/specs/<project>-reverse-design.md
  |
  +-- 4. Launch Leader-Enhance
  |     - Deep Code Reading phase
  |     - Integration Point Analysis
  |     - Backward Compatibility Checklist
  |     Output: Enhancement spec + Tasks
  |
  +-- 5. Launch Leader-Impl (ENHANCE MODE)
  |     - Implementation Player (TDD)
  |     - Security Player (vulnerability scan)
  |     - Test Player (edge cases)
  |     - Integration Player (E2E)
  |     - Code Review Player (patterns)
  |     Output: Modified code with 100% new code coverage
  |
  +-- 6. Quality Gates (ENHANCED)
  |     scripts/enhance-quality-gates.sh
  |     - Baseline comparison
  |     - No regression check
  |     - Security verification
  |
  +-- 7. Report completion
```

---

## MANDATORY EXECUTION PROTOCOL

**You MUST follow this protocol exactly. Do NOT deviate.**

---

### Step 1: Validate Project

```bash
# Check project exists
if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Error: Project path does not exist"
  exit 1
fi

# Check for existing analysis
ANALYSIS_FILE=".aida/analysis/$(basename $PROJECT_PATH)-analysis.json"
if [[ ! -f "$ANALYSIS_FILE" ]]; then
  echo "Project not analyzed. Running analysis first..."
  ./scripts/analyze-project.sh "$PROJECT_PATH"
fi
```

### Step 2: Parse Enhancement Specification

**Document Input:**
```bash
if [[ -f "$SPEC_PATH" ]]; then
  # Read specification document
  ENHANCEMENT_SPEC=$(cat "$SPEC_PATH")
fi
```

**Natural Language Input:**
```
ENHANCEMENT_SPEC = "$ARGUMENTS[1]"
```

**GitHub Issue Input:**
```bash
if [[ "$SPEC_PATH" == *"github.com"*"/issues/"* ]]; then
  # Fetch issue content using gh or curl
  ISSUE_NUMBER=$(echo "$SPEC_PATH" | grep -oP 'issues/\K\d+')
  REPO=$(echo "$SPEC_PATH" | grep -oP 'github.com/\K[^/]+/[^/]+')
  ENHANCEMENT_SPEC=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json title,body --jq '.title + "\n\n" + .body')
fi
```

### Step 3: Capture Baseline (NEW - CRITICAL)

**CRITICAL: Capture baseline BEFORE making any changes**

```bash
# Run the baseline capture script
./scripts/capture-baseline.sh "$PROJECT_PATH" "$ANALYSIS_FILE"

# Verify baseline captured
if [[ ! -f ".aida/state/enhance-baseline.json" ]]; then
  echo "Error: Baseline capture failed"
  exit 1
fi

# Check baseline validity
BASELINE_VALID=$(jq -r '.summary.baseline_valid' .aida/state/enhance-baseline.json)
if [[ "$BASELINE_VALID" != "true" ]]; then
  echo "Warning: Project has failing tests before enhancement"
  echo "Recommend: /aida:fix to resolve existing issues first"
fi
```

### Step 4: Generate Reverse Specifications (NEW)

```bash
# Generate reverse specs to understand existing patterns
./scripts/generate-reverse-specs.sh "$PROJECT_PATH" "$ANALYSIS_FILE"

# Verify generated
REVERSE_SPEC=".aida/specs/$(basename $PROJECT_PATH)-reverse-design.md"
if [[ ! -f "$REVERSE_SPEC" ]]; then
  echo "Error: Reverse spec generation failed"
  exit 1
fi
```

The reverse spec contains:
- Existing API endpoints
- Data models
- Coding patterns
- Directory structure
- Naming conventions
- **All new code MUST follow these patterns**

### Step 5: Launch Leader-Enhance

<MANDATORY_ACTION id="launch-leader-enhance">

**YOU MUST INVOKE THE TASK TOOL NOW.**

Use these exact parameters:

| Parameter | Value |
|-----------|-------|
| description | "Leader-Enhance: Enhancement Specification" |
| subagent_type | "general-purpose" |
| model | "sonnet" |
| run_in_background | false |
| prompt | See below |

**Task Prompt:**

```
You are AIDA Leader-Enhance agent.

## CRITICAL INSTRUCTION
Read and follow the full instructions in: agents/leader-enhance.md
Pay special attention to the NEW phases:
- Phase 0: Deep Code Reading
- Phase 0.5: Integration Point Analysis
- Backward Compatibility Checklist

## Current Session
- Project: {{PROJECT_NAME}}
- Project Path: {{PROJECT_PATH}}
- Working Directory: {{CWD}}

## Required Reading (MUST READ ALL)
- .aida/analysis/{{PROJECT}}-analysis.json
- .aida/state/enhance-baseline.json
- .aida/specs/{{PROJECT}}-reverse-design.md

## Enhancement Specification
{{ENHANCEMENT_SPEC}}

## Your Mission

### Phase 0: Deep Code Reading (NEW - CRITICAL)
1. Read all foundation documents
2. Deep read ALL affected files
3. Document patterns for each file
4. Extract naming conventions
5. Map dependencies

### Phase 0.5: Integration Point Analysis (NEW)
1. Map where new code connects to existing
2. Create dependency graph
3. Assess change impact for each point

### Backward Compatibility Checklist (NEW - MANDATORY)
Complete the full checklist before designing:
- API compatibility
- Database compatibility
- Configuration compatibility
- Code compatibility
- Test compatibility
- Runtime compatibility

### Phase 1: Understand Existing Code
1. Read analysis results
2. Identify affected modules
3. Extract existing patterns and conventions
4. Map dependencies

### Phase 2: Design Enhancement
1. Design changes following existing patterns EXACTLY
2. Identify integration points
3. Plan backward compatibility
4. Document API changes if any

### Phase 3: Generate Tasks
1. Create test tasks (TDD RED phase)
2. Create implementation tasks (TDD GREEN phase)
3. Create security review tasks
4. Create edge case test tasks
5. Create integration test tasks
6. Specify 100% coverage requirement for new code

## Output Files
Write to:
- .aida/specs/{{PROJECT}}-enhancement.md (min 500 bytes)
- .aida/specs/{{PROJECT}}-enhancement-tasks.md

## Completion
Write to .aida/results/enhance-spec-complete.json
```

</MANDATORY_ACTION>

### Step 6: Launch Leader-Impl in Enhance Mode

<MANDATORY_ACTION id="launch-leader-impl-enhance">

**YOU MUST INVOKE THE TASK TOOL NOW.**

| Parameter | Value |
|-----------|-------|
| description | "Leader-Impl: Enhancement Implementation" |
| subagent_type | "general-purpose" |
| model | "sonnet" |
| run_in_background | false |
| prompt | See below |

**Task Prompt:**

```
You are AIDA Leader-Impl agent in ENHANCE MODE.

## CRITICAL INSTRUCTION
Read and follow the full instructions in: agents/leader-impl.md
Pay special attention to the ENHANCE MODE section - it has been STRENGTHENED.

## Current Session
- Project: {{PROJECT_NAME}}
- Project Path: {{PROJECT_PATH}}
- Mode: ENHANCE (not new project)

## Required Reading (MUST READ ALL)
- .aida/specs/{{PROJECT}}-enhancement.md
- .aida/specs/{{PROJECT}}-enhancement-tasks.md
- .aida/analysis/{{PROJECT}}-analysis.json
- .aida/state/enhance-baseline.json
- .aida/specs/{{PROJECT}}-reverse-design.md

## ENHANCE MODE Protocol (STRENGTHENED)

### Rule 1: Preserve Existing Tests
All existing tests MUST continue to pass.
Run baseline tests after EVERY file modification.

### Rule 2: Follow Existing Patterns EXACTLY
Match the project's existing patterns from reverse-design.md:
- Coding style
- Directory structure
- Naming conventions
- Error handling patterns

### Rule 3: Minimal Changes
Only modify what is necessary.
Each change should be atomic and verifiable.

### Rule 4: TDD for New Features (100% COVERAGE TARGET)
New features follow TDD with 100% coverage:
1. RED: Write failing test
2. GREEN: Minimal code to pass
3. VERIFY: Run ALL tests (baseline + new)
4. REFACTOR: Clean up
5. REPEAT: Until 100% coverage for new code

**TDD Evidence Recording (Gate 20):**
```bash
./scripts/tdd-logger.sh start <feature>
./scripts/tdd-logger.sh red <test-file>
./scripts/tdd-logger.sh green <test-file>
./scripts/tdd-logger.sh complete
```

## Multi-Agent Quality Assurance

You MUST delegate to specialized Players:

1. **Implementation Player** (sonnet)
   - TDD implementation
   - Unit tests for all new code

2. **Security Player** (sonnet)
   - Vulnerability scan
   - OWASP Top 10 review

3. **Test Player** (sonnet)
   - Edge case tests
   - Boundary tests
   - Error condition tests

4. **Integration Player** (sonnet)
   - E2E tests
   - API integration tests

5. **Code Review Player** (haiku)
   - Pattern compliance check
   - Naming convention check

## Verification Loop

FOR EACH task:
1. Implement via Player
2. Run unit tests
3. Run baseline tests (no regression)
4. Check coverage
5. Security scan (every 3 features)
6. Mark complete only if ALL pass

## Rollback Strategy

If regression detected:
1. git diff HEAD~1
2. git checkout HEAD~1 -- <file>
3. Analyze root cause
4. Re-implement with fixes

## Exit Conditions
- [ ] All baseline tests pass (no regression)
- [ ] New tests for all new features
- [ ] 100% coverage for new code
- [ ] Security review passed
- [ ] Code review passed
- [ ] Build succeeds

Write to .aida/results/enhance-impl-complete.json
```

</MANDATORY_ACTION>

### Step 7: Run Quality Gates (ENHANCED)

```bash
# Run enhanced quality gates with baseline comparison
./scripts/enhance-quality-gates.sh "$PROJECT_PATH" \
  --baseline ".aida/state/enhance-baseline.json" \
  --analysis ".aida/analysis/$(basename $PROJECT_PATH)-analysis.json"

# Check gate results
GATE_RESULT=$?
if [[ $GATE_RESULT -ne 0 ]]; then
  echo "Quality gates failed. Review results and fix issues."
  exit 1
fi
```

**Enhanced Quality Gates:**

| Gate | Requirement | Action on Failure |
|------|-------------|-------------------|
| 1. Build | Build succeeds | Block completion |
| 2. Test Execution | All tests run | Block completion |
| 3. Baseline Preservation | All baseline tests pass | Block completion |
| 4. Coverage Target | 100% for new code | Block completion |
| 5. Security Check | No critical issues | Block completion |
| 6. Docker (if applicable) | Build/Run/Health | Block completion |

### Step 8: Report Completion

```
AIDA Enhancement Complete

Project: {{PROJECT_NAME}}
Enhancement: {{ENHANCEMENT_SUMMARY}}

Changes Made:
  - {{CHANGE_1}}
  - {{CHANGE_2}}

Quality Gates:
  - Build: PASS
  - Baseline Tests: PASS (no regression)
  - New Tests: +{{N}} tests added
  - New Code Coverage: 100%
  - Overall Coverage: {{BEFORE}}% → {{AFTER}}%
  - Security Review: PASS
  - Code Review: PASS

Multi-Agent Quality Assurance:
  - Implementation Player: COMPLETED
  - Security Player: PASS (0 critical issues)
  - Test Player: +{{M}} edge case tests
  - Integration Player: +{{K}} E2E tests
  - Code Review Player: PASS

Files Modified:
  - backend/internal/handler/new_feature.go (new)
  - backend/internal/handler/new_feature_test.go (new)
  - frontend/src/pages/NewFeaturePage.tsx (new)

Verification Commands:
  cd {{PROJECT_PATH}}
  {{TEST_COMMAND}}
  {{BUILD_COMMAND}}
```

---

## Document Formats (Flexible)

### Format 1: Natural Language

```
Add user authentication feature.
- Support email/password login
- Add password reset via email
- Create user profile page
```

### Format 2: Structured Requirements

```markdown
# Feature: User Authentication

## Requirements
- REQ-001: Email/password registration
- REQ-002: Login with JWT tokens
- REQ-003: Password reset flow

## API Endpoints
- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/forgot-password

## UI Changes
- Login page at /login
- Register page at /register
```

### Format 3: GitHub Issue Reference

```
Issue: https://github.com/org/repo/issues/42
Related PRs: #43, #44
```

### Format 4: Bug Fix

```markdown
# Bug: User session expires incorrectly

## Problem
Session expires after 5 minutes instead of 24 hours.

## Expected Behavior
Session should expire after 24 hours of inactivity.

## Steps to Reproduce
1. Login to application
2. Wait 6 minutes
3. Try to access protected route
4. Error: "Session expired"

## Affected Files
- backend/internal/middleware/auth.go (suspected)
```

---

## Quality Gate Enforcement (STRENGTHENED)

The enhance Stop Hook enforces strict quality requirements:

| Gate | Requirement | Failure Action |
|------|-------------|----------------|
| Build Success | Build completes without errors | Block completion |
| Test Execution | All tests run successfully | Block completion |
| Baseline Preservation | All original tests pass | Block completion |
| No Test Regression | test_count >= baseline | Block completion |
| Coverage Target | 100% coverage for new code | Block completion |
| Overall Coverage | coverage >= baseline | Block completion |
| Security Review | No critical/high issues | Block completion |
| Code Review | Pattern compliance verified | Warn (soft fail) |

### Multi-Agent Verification

The quality assurance uses multiple specialized agents:

```
Leader-Impl (ENHANCE MODE)
  |
  +-- Implementation Player
  |     Output: .aida/results/enhance-impl-*.json
  |
  +-- Security Player
  |     Output: .aida/results/security-review.json
  |     MUST: status = "pass"
  |
  +-- Test Player
  |     Output: .aida/results/edge-case-tests.json
  |
  +-- Integration Player
  |     Output: .aida/results/integration-tests.json
  |
  +-- Code Review Player
        Output: .aida/results/code-review.json
```

### Verification Scripts

```bash
# Baseline capture (before any changes)
./scripts/capture-baseline.sh "$PROJECT_PATH"

# Reverse spec generation (understand existing patterns)
./scripts/generate-reverse-specs.sh "$PROJECT_PATH"

# Quality gate check (after implementation)
./scripts/enhance-quality-gates.sh "$PROJECT_PATH" \
  --baseline ".aida/state/enhance-baseline.json" \
  --analysis ".aida/analysis/$PROJECT-analysis.json"
```

---

## Error Handling

### Baseline Tests Failing

```
Warning: Project has failing tests before enhancement

Options:
1. Proceed anyway (not recommended)
2. Fix existing issues first with: /aida:maintain {{PROJECT}} --fix-tests
3. Abort enhancement
```

### Enhancement Breaks Existing Tests

```
Error: Enhancement caused test regression

Failed Tests:
- TestUserLogin (was passing)
- TestSessionValidation (was passing)

The enhancement MUST NOT break existing functionality.
Review changes and fix regressions before completion.
```

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida:analyze` | Analyze project first |
| `/aida:import` | Import external project |
| `/aida:maintain` | Maintenance tasks |
| `/aida:status` | Check enhancement progress |
