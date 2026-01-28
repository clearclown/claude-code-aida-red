# /red:assault - Launch Attack Campaign

Main entry point for AIDA-RED. Starts the Warlord and begins the attack campaign.

## Usage

```
/red:assault --target <path> [options]
```

## Arguments

| Argument | Description | Required | Default |
|----------|-------------|----------|---------|
| `--target` | Path to AIDA project | Yes | - |
| `--intensity` | Attack intensity level | No | standard |
| `--focus` | Specific area to attack | No | all |
| `--villain` | Run specific villain only | No | all |

### Intensity Levels

| Level | Villains | Duration | Coverage |
|-------|----------|----------|----------|
| `minimum` | Joker only | Quick | Basic fuzzing |
| `standard` | Joker + Shadow | Medium | Fuzzing + Security |
| `maximum` | All villains | Extended | Full assault |

### Focus Areas

- `backend` - Target Go/backend code
- `frontend` - Target React/frontend code
- `api` - Target REST API endpoints
- `auth` - Target authentication/authorization
- `docker` - Target container infrastructure
- `all` - No focus restriction (default)

### Villain Selection

- `joker` - Logic fuzzing only
- `shadow` - Security testing only
- `chaos` - Infrastructure chaos only

---

## Execution Protocol

### Phase 1: Reconnaissance

Read and analyze AIDA specs:

```
Reading: .aida/specs/{{project}}-requirements.md
Reading: .aida/specs/{{project}}-design.md
Reading: .aida/specs/{{project}}-tasks.md

Extracting:
- API endpoints: {{count}} found
- Auth mechanisms: {{mechanisms}}
- Tech stack: {{stack}}
- Business rules: {{count}} identified
```

### Phase 2: Target Validation

Verify target is ready for attack:

```
Checking AIDA status...
  Phase: COMPLETED
  Quality Gates: PASSED

Target is ready for assault.
```

### Phase 3: Warlord Deployment

Deploy the Warlord to coordinate the attack:

**YOU MUST USE THE TASK TOOL TO DEPLOY THE WARLORD.**

```yaml
Task:
  description: "Warlord: Coordinate AIDA-RED assault"
  subagent_type: "general-purpose"
  model: "sonnet"
  run_in_background: false
  prompt: |
    You are the Warlord, commander of AIDA-RED.

    Read: aida-red/agents/warlord.md

    Target: {{TARGET_PATH}}
    Intensity: {{INTENSITY}}
    Focus: {{FOCUS}}

    Mission:
    1. Gather intelligence from .aida/specs/
    2. Deploy appropriate Villain agents
    3. Coordinate attack campaign
    4. Compile vulnerability report

    Deploy Villains using Task tool:
    - Joker: aida-red/agents/joker.md (model: haiku)
    - Shadow: aida-red/agents/shadow.md (model: haiku)
    - Chaos: aida-red/agents/chaos.md (model: haiku)

    Output findings to: .aida-red/reports/
    Inject bugs to: .aida/tdd-evidence/external-bugs/
```

### Phase 4: Villain Execution

Each villain runs their specialized attacks:

**Joker (Fuzzing)**
```
Generating boundary value payloads...
Testing integer overflow...
Testing Unicode injection...
Testing race conditions...
Found: 3 crashes, 2 hangs
```

**Shadow (Security)**
```
Analyzing authorization logic...
Testing IDOR vulnerabilities...
Testing JWT manipulation...
Testing privilege escalation...
Found: 1 auth bypass, 2 data leaks
```

**Chaos (Infrastructure)**
```
Preparing container chaos...
Testing network partitions...
Testing resource exhaustion...
Testing monkey interactions...
Found: 2 inconsistent states
```

### Phase 5: Report Generation

Compile final vulnerability report:

```
=== AIDA-RED ASSAULT REPORT ===

Campaign: {{CAMPAIGN_ID}}
Target: {{TARGET}}
Duration: {{DURATION}}

FINDINGS:
  CRITICAL: 1
  HIGH: 3
  MEDIUM: 4
  LOW: 2

By Villain:
  Joker: 5 findings
  Shadow: 3 findings
  Chaos: 2 findings

Reproduction scripts written to:
  .aida-red/reports/joker/*.spec.ts
  .aida-red/reports/shadow/*.spec.ts
  .aida-red/reports/chaos/*.spec.ts

Injected into AIDA evidence:
  .aida/tdd-evidence/external-bugs/

AIDA's next quality gate run will FAIL.
```

---

## Example Execution

```bash
# Full assault with maximum intensity
/red:assault --target ../my-project --intensity maximum

# Security-focused attack only
/red:assault --target ../my-project --villain shadow --focus auth

# Quick fuzzing check
/red:assault --target ../my-project --intensity minimum --focus api
```

---

## Success Criteria

The assault is successful when:

1. All enabled villains have executed
2. Findings have reproduction scripts
3. Bugs injected into AIDA evidence
4. Final report generated

---

## Integration with AIDA

After assault completes:

1. Vulnerability tests are in `.aida/tdd-evidence/external-bugs/`
2. Running `./scripts/quality-gates.sh` will **FAIL**
3. AIDA must fix issues and re-run to pass
4. Cycle continues until no new bugs found

---

## Error Handling

| Error | Action |
|-------|--------|
| No AIDA specs | Proceed with limited intelligence |
| Target not built | Warning, attempt anyway |
| Docker not available | Skip Chaos agent |
| Villain crash | Log error, continue with others |
