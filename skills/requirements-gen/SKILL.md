---
name: requirements-gen
description: |
  Generate structured requirements from natural language.
  No API key required - uses Claude Code OAuth.
tools: Read, Write, Edit, Glob
---

# Requirements Generation Skill

Generate structured requirements documentation from natural language ideas.

## Output Structure

```
.aida/artifacts/requirements/
  00_overview.md        # Project overview
  01_functional.md      # Functional requirements
  02_non_functional.md  # Non-functional requirements
  03_constraints.md     # Constraints
  04_acceptance.md      # Acceptance criteria
```

## Execution Protocol

### Step 1: Input Analysis

Analyze natural language input to extract:
- Project purpose
- Main features
- Target users
- Technical constraints

### Step 2: Generate Requirements

Generate each document following templates:

#### 00_overview.md

```markdown
# Project Overview

## Purpose
{{PROJECT_PURPOSE}}

## Vision
{{PROJECT_VISION}}

## Scope
### In Scope
{{IN_SCOPE}}

### Out of Scope
{{OUT_OF_SCOPE}}

## Stakeholders
{{STAKEHOLDERS}}

## Success Metrics
{{SUCCESS_METRICS}}
```

#### 01_functional.md

```markdown
# Functional Requirements

## User Stories

### US-001: {{STORY_TITLE}}
- **As a** {{USER_ROLE}}
- **I want** {{ACTION}}
- **So that** {{BENEFIT}}

**Acceptance Criteria:**
1. {{CRITERIA_1}}
2. {{CRITERIA_2}}

## Feature List

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F-001 | {{NAME}} | {{DESC}} | {{PRIORITY}} |
```

#### 02_non_functional.md

```markdown
# Non-Functional Requirements

## Performance
- Response time: {{RESPONSE_TIME}}
- Throughput: {{THROUGHPUT}}

## Security
- Authentication: {{AUTH_METHOD}}
- Encryption: {{ENCRYPTION}}

## Availability
- Uptime target: {{UPTIME}}
- Backup: {{BACKUP}}

## Scalability
- Expected users: {{USERS}}
- Data volume: {{DATA_VOLUME}}
```

#### 03_constraints.md

```markdown
# Constraints

## Technical Constraints
{{TECH_CONSTRAINTS}}

## Business Constraints
{{BIZ_CONSTRAINTS}}

## Time Constraints
{{TIME_CONSTRAINTS}}

## Resource Constraints
{{RESOURCE_CONSTRAINTS}}
```

#### 04_acceptance.md

```markdown
# Acceptance Criteria

## Global Acceptance Criteria
{{GLOBAL_CRITERIA}}

## Feature Acceptance Criteria
### {{FEATURE_NAME}}
- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}

## Test Requirements
{{TEST_REQUIREMENTS}}
```

### Step 3: File Output

```bash
mkdir -p .aida/artifacts/requirements/
```

Write each file to `.aida/artifacts/requirements/`.

### Step 4: Report Result

```json
{
  "task_id": "req-{{TIMESTAMP}}",
  "completed_by": "requirements-gen",
  "status": "completed",
  "success": true,
  "output": {
    "files": [
      ".aida/artifacts/requirements/00_overview.md",
      ".aida/artifacts/requirements/01_functional.md",
      ".aida/artifacts/requirements/02_non_functional.md",
      ".aida/artifacts/requirements/03_constraints.md",
      ".aida/artifacts/requirements/04_acceptance.md"
    ]
  },
  "next_step": "Generate design document"
}
```

## Example

Input: "Create a TODO app with authentication"

Output:
```markdown
# Project Overview

## Purpose
Develop a TODO application where users can efficiently manage their tasks.

## Vision
Simple, intuitive UI that allows anyone to easily start task management.

## Scope
### In Scope
- User authentication (registration, login, logout)
- Task CRUD operations
- Task deadline setting
- Task categorization

### Out of Scope
- Team features
- Calendar integration
- Mobile app
```
