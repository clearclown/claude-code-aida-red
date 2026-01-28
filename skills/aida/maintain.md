---
name: aida:maintain
description: |
  Project maintenance automation for dependency updates, security audits,
  issue handling, and quality improvements. Supports any project type.
tools: Read, Write, Edit, Bash, Glob, Grep, Task, WebFetch
---

# AIDA Maintain

Automate project maintenance tasks: dependency updates, security audits, issue resolution, and quality improvements.

## Usage

```
# Issue handling (GitHub, GitLab, Jira)
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123

# Dependency updates
/aida:maintain /path/to/project --update-deps

# Security audit
/aida:maintain /path/to/project --security

# Quality improvements (coverage, dead code, docs)
/aida:maintain /path/to/project --improve

# Fix failing tests
/aida:maintain /path/to/project --fix-tests

# All maintenance tasks
/aida:maintain /path/to/project --all
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

### Step 2: Parse Maintenance Mode

```
MODE = $ARGUMENTS.mode  # --issue, --update-deps, --security, --improve, --fix-tests, --all

# Extract mode-specific options
if MODE == "--issue":
    ISSUE_URL = $ARGUMENTS.issue
elif MODE == "--update-deps":
    UPDATE_TYPE = $ARGUMENTS.type  # major, minor, patch, security
elif MODE == "--improve":
    IMPROVE_TARGET = $ARGUMENTS.target  # coverage, docs, refactor
```

---

## Mode 1: Issue Handling (`--issue`)

### Supported Issue Sources

| Source | URL Pattern | Fetch Method |
|--------|-------------|--------------|
| GitHub | `github.com/.../issues/N` | `gh issue view` |
| GitLab | `gitlab.com/.../issues/N` | `glab issue view` |
| Jira | `*.atlassian.net/browse/X-N` | API with token |
| Linear | `linear.app/.../issue/X-N` | API with token |

### Workflow

<MANDATORY_ACTION id="issue-handling">

**Step 1: Fetch Issue**

```bash
if [[ "$ISSUE_URL" == *"github.com"*"/issues/"* ]]; then
  ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oP 'issues/\K\d+')
  REPO=$(echo "$ISSUE_URL" | grep -oP 'github.com/\K[^/]+/[^/]+')

  ISSUE_CONTENT=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" \
    --json title,body,labels,assignees,state \
    --jq '{title, body, labels: [.labels[].name], state}')
fi
```

**Step 2: Analyze Issue**

Based on issue content, determine:
- Issue type: bug, feature, refactor, docs, security
- Affected components (from analysis.json)
- Required changes

**Step 3: Generate Fix Plan**

For bugs:
1. Reproduce the issue (if possible)
2. Write failing test that captures the bug
3. Fix the code
4. Verify test passes

For features:
1. Design minimal implementation
2. TDD: Write tests first
3. Implement feature
4. Integration tests

**Step 4: Execute Fix**

Launch Task agent for implementation:

```
Task(
  description="Fix Issue: <ISSUE_TITLE>",
  subagent_type="general-purpose",
  prompt="""
    You are AIDA maintenance agent fixing issue: <ISSUE_TITLE>

    Issue Content:
    <ISSUE_BODY>

    Project Analysis:
    <ANALYSIS_JSON>

    Instructions:
    1. Locate affected code
    2. Write failing test (TDD)
    3. Implement fix
    4. Run all tests
    5. Report results
  """
)
```

</MANDATORY_ACTION>

---

## Mode 2: Dependency Updates (`--update-deps`)

### Supported Package Managers

| Language | Package Manager | Detection | Update Command |
|----------|-----------------|-----------|----------------|
| Go | go mod | go.mod | `go get -u` |
| Node.js | npm | package.json | `npm update` |
| Node.js | pnpm | pnpm-lock.yaml | `pnpm update` |
| Node.js | yarn | yarn.lock | `yarn upgrade` |
| Python | pip | requirements.txt | `pip install -U` |
| Python | poetry | pyproject.toml | `poetry update` |
| Python | uv | uv.lock | `uv sync --upgrade` |
| Rust | cargo | Cargo.toml | `cargo update` |
| Ruby | bundler | Gemfile | `bundle update` |
| Java | maven | pom.xml | `mvn versions:use-latest-releases` |
| Java | gradle | build.gradle | `gradle dependencyUpdates` |

### Workflow

<MANDATORY_ACTION id="update-deps">

**Step 1: Detect Package Manager**

```bash
# Read from analysis
COMPONENTS=$(jq -r '.components' "$ANALYSIS_FILE")

for component in $(echo "$COMPONENTS" | jq -r '.[].name'); do
  lang=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .lang")
  path=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .path")

  cd "$PROJECT_PATH/$path"

  case "$lang" in
    go)
      echo "Updating Go dependencies..."
      go get -u ./...
      go mod tidy
      ;;
    typescript|javascript)
      if [[ -f "pnpm-lock.yaml" ]]; then
        pnpm update
      elif [[ -f "yarn.lock" ]]; then
        yarn upgrade
      else
        npm update
      fi
      ;;
    python)
      if [[ -f "pyproject.toml" ]]; then
        poetry update || uv sync --upgrade
      elif [[ -f "requirements.txt" ]]; then
        pip install -U -r requirements.txt
      fi
      ;;
    rust)
      cargo update
      ;;
  esac
done
```

**Step 2: Run Tests**

After updating, run all tests to catch breaking changes:

```bash
./scripts/enhance-quality-gates.sh "$ANALYSIS_FILE" "$PROJECT_PATH"
```

**Step 3: Handle Breaking Changes**

If tests fail after update:
1. Identify breaking changes from changelogs
2. Update code to match new API
3. Re-run tests

**Step 4: Report Results**

```json
{
  "mode": "update-deps",
  "status": "completed",
  "updates": [
    {"package": "example/pkg", "from": "1.2.3", "to": "1.3.0"},
    ...
  ],
  "breaking_changes_fixed": 2,
  "tests_passing": true
}
```

</MANDATORY_ACTION>

---

## Mode 3: Security Audit (`--security`)

### Security Scanners

| Language | Tool | Command |
|----------|------|---------|
| Go | govulncheck | `govulncheck ./...` |
| Node.js | npm audit | `npm audit` |
| Python | pip-audit | `pip-audit` |
| Python | safety | `safety check` |
| Rust | cargo-audit | `cargo audit` |
| Java | OWASP DC | `dependency-check` |
| Generic | trivy | `trivy fs .` |

### Workflow

<MANDATORY_ACTION id="security-audit">

**Step 1: Run Security Scans**

```bash
VULNERABILITIES=()

for component in $(echo "$COMPONENTS" | jq -r '.[].name'); do
  lang=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .lang")
  path=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .path")

  cd "$PROJECT_PATH/$path"

  case "$lang" in
    go)
      if command -v govulncheck &>/dev/null; then
        govulncheck ./... 2>&1 | tee /tmp/vuln-$component.log
      fi
      ;;
    typescript|javascript)
      npm audit --json > /tmp/vuln-$component.json 2>&1 || true
      ;;
    python)
      pip-audit 2>&1 | tee /tmp/vuln-$component.log || true
      ;;
    rust)
      cargo audit 2>&1 | tee /tmp/vuln-$component.log || true
      ;;
  esac
done
```

**Step 2: Parse Vulnerabilities**

```bash
# Aggregate and categorize vulnerabilities
# - Critical: Requires immediate fix
# - High: Should fix soon
# - Medium: Plan to fix
# - Low: Informational
```

**Step 3: Auto-Fix Where Possible**

```bash
# npm can auto-fix some vulnerabilities
npm audit fix

# For others, update to patched versions
```

**Step 4: Report**

```markdown
# Security Audit Report

## Summary
- Critical: 0
- High: 2
- Medium: 5
- Low: 12

## Critical & High Vulnerabilities

### CVE-2024-XXXX (High)
- Package: example-pkg
- Affected: 1.2.3
- Fixed in: 1.2.4
- Action: Updated automatically

...
```

</MANDATORY_ACTION>

---

## Mode 4: Quality Improvements (`--improve`)

### Improvement Targets

| Target | Description |
|--------|-------------|
| coverage | Increase test coverage |
| docs | Improve documentation |
| refactor | Clean up code smells |
| dead-code | Remove unused code |
| types | Add type annotations |

### Workflow

<MANDATORY_ACTION id="quality-improve">

**Coverage Improvement**

1. Identify untested code:
   ```bash
   # Go
   go test -coverprofile=coverage.out ./...
   go tool cover -func=coverage.out | grep -v "100.0%"

   # Node.js
   npm test -- --coverage
   ```

2. Generate tests for uncovered functions
3. Prioritize critical paths

**Documentation Improvement**

1. Find undocumented exports
2. Generate JSDoc/GoDoc comments
3. Update README if outdated

**Dead Code Removal**

1. Run static analysis:
   ```bash
   # Go
   staticcheck ./...

   # TypeScript
   npx ts-prune

   # Python
   vulture .
   ```

2. Remove unused exports/functions
3. Verify tests still pass

</MANDATORY_ACTION>

---

## Mode 5: Fix Failing Tests (`--fix-tests`)

### Workflow

<MANDATORY_ACTION id="fix-tests">

**Step 1: Identify Failing Tests**

```bash
# Run tests and capture failures
for component in $(echo "$COMPONENTS" | jq -r '.[].name'); do
  test_cmd=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .test_command")
  path=$(echo "$COMPONENTS" | jq -r ".[] | select(.name==\"$component\") | .path")

  cd "$PROJECT_PATH/$path"
  $test_cmd 2>&1 | tee /tmp/test-$component.log
done
```

**Step 2: Analyze Failures**

- Parse test output for failure messages
- Identify failure patterns (assertion, timeout, error)
- Determine if test or code is wrong

**Step 3: Fix**

For each failing test:
1. Read the test code
2. Read the implementation being tested
3. Determine the cause:
   - Bug in code → Fix code
   - Outdated test → Update test
   - Environment issue → Fix setup

**Step 4: Verify**

Run all tests to ensure no regressions.

</MANDATORY_ACTION>

---

## Output Report

After maintenance completes:

```markdown
# AIDA Maintenance Report

## Project: {{PROJECT_NAME}}
## Mode: {{MODE}}
## Date: {{DATE}}

## Summary

{{MODE_SPECIFIC_SUMMARY}}

## Actions Taken

1. {{ACTION_1}}
2. {{ACTION_2}}
...

## Test Results

- Total: {{TOTAL}}
- Passed: {{PASSED}}
- Failed: {{FAILED}}
- Skipped: {{SKIPPED}}

## Recommendations

- {{RECOMMENDATION_1}}
- {{RECOMMENDATION_2}}

## Next Steps

To verify changes:
  cd {{PROJECT_PATH}}
  {{TEST_COMMAND}}
```

---

## Session Tracking

Updates `.aida/state/session.json`:

```json
{
  "session_id": "<UUID>",
  "mode": "aida:maintain",
  "started_at": "<ISO8601>",
  "project_name": "<name>",
  "project_path": "<path>",
  "maintenance_type": "<issue|update-deps|security|improve|fix-tests>",
  "current_phase": "MAINTENANCE",
  "actions_completed": [],
  "issues_fixed": [],
  "dependencies_updated": [],
  "vulnerabilities_patched": []
}
```

---

## Error Handling

### Issue Not Found

```
Error: Could not fetch issue

The issue URL may be:
- Private (authentication required)
- Deleted or moved
- Invalid format

Solutions:
1. Check URL is correct
2. Authenticate: gh auth login
3. Provide issue content manually
```

### Dependency Conflict

```
Error: Dependency conflict detected

Package A requires X >= 2.0
Package B requires X < 2.0

Options:
1. Update Package B first
2. Use resolution override
3. Fork and patch
```

### Security Fix Breaks Tests

```
Warning: Security update caused test failures

Affected tests:
- TestFoo (timeout)
- TestBar (assertion)

The security update may have changed API behavior.
Manual review required.
```

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida:analyze` | Analyze project first |
| `/aida:enhance` | Add new features |
| `/aida:import` | Import external project |
| `/aida:status` | Check maintenance progress |
