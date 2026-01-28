# /red:init - Initialize AIDA-RED

Initialize the `.aida-red/` directory structure in the target project.

## Usage

```
/red:init [--target <path>]
```

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--target` | Path to project directory | Current directory |

---

## What This Command Does

1. Creates `.aida-red/` directory structure
2. Initializes configuration files
3. Sets up report directories
4. Links to AIDA specs if available

---

## Execution Steps

### Step 1: Create Directory Structure

```bash
mkdir -p .aida-red/{operations,reports/{joker,shadow,chaos},arsenal/{payloads,exploits},logs}
```

### Step 2: Initialize Configuration

Create `.aida-red/config.json`:

```json
{
  "version": "1.0.0",
  "initialized_at": "{{ISO8601}}",
  "target_project": "{{PROJECT_PATH}}",
  "settings": {
    "intensity": "standard",
    "auto_inject": true,
    "watch_aida": true,
    "villains_enabled": ["joker", "shadow", "chaos"]
  },
  "aida_integration": {
    "specs_path": ".aida/specs",
    "session_path": ".aida/state/session.json",
    "evidence_path": ".aida/tdd-evidence/external-bugs"
  }
}
```

### Step 3: Create .gitignore

Create `.aida-red/.gitignore`:

```gitignore
# AIDA-RED generated files
operations/
reports/
logs/
*.tmp

# Keep structure
!.gitkeep
```

### Step 4: Create Status File

Create `.aida-red/operations/status.json`:

```json
{
  "status": "INITIALIZED",
  "last_assault": null,
  "total_campaigns": 0,
  "total_findings": 0,
  "villains": {
    "joker": { "status": "IDLE", "findings": 0 },
    "shadow": { "status": "IDLE", "findings": 0 },
    "chaos": { "status": "IDLE", "findings": 0 }
  }
}
```

---

## Output

After successful initialization:

```
AIDA-RED Initialized

Project: {{PROJECT_PATH}}
Config: .aida-red/config.json

Directory Structure:
  .aida-red/
  ├── config.json
  ├── operations/
  │   └── status.json
  ├── reports/
  │   ├── joker/
  │   ├── shadow/
  │   └── chaos/
  ├── arsenal/
  │   ├── payloads/
  │   └── exploits/
  └── logs/

AIDA Integration:
  Specs: {{SPECS_STATUS}}
  Session: {{SESSION_STATUS}}

Next steps:
  /red:assault    - Start attack campaign
  /red:status     - Check status
```

---

## AIDA Integration Check

If AIDA is present in the target project:

```bash
# Check for AIDA structure
if [[ -d ".aida/specs" ]]; then
    echo "AIDA specs found - intelligence gathering enabled"
fi

if [[ -f ".aida/state/session.json" ]]; then
    echo "AIDA session found - auto-trigger enabled"
fi
```

---

## Error Handling

| Error | Resolution |
|-------|------------|
| Directory already exists | Prompt to overwrite or skip |
| No write permission | Request appropriate permissions |
| Not a project directory | Warning, but proceed |
