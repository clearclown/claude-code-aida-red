# /red:status - Show Attack Status

Display the current status of AIDA-RED campaigns, active villains, and bug counts.

## Usage

```
/red:status [--campaign <id>] [--verbose]
```

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--campaign` | Specific campaign ID | Latest |
| `--verbose` | Show detailed findings | false |

---

## Execution

### Step 1: Read Status Files

Read from `.aida-red/operations/`:

```bash
# Read main status
cat .aida-red/operations/status.json

# Read active campaign
cat .aida-red/operations/targets.json
```

### Step 2: Count Findings

```bash
# Count reproduction scripts per villain
joker_count=$(find .aida-red/reports/joker -name "*.spec.ts" | wc -l)
shadow_count=$(find .aida-red/reports/shadow -name "*.spec.ts" | wc -l)
chaos_count=$(find .aida-red/reports/chaos -name "*.spec.ts" | wc -l)
```

### Step 3: Display Status

---

## Output Format

### Basic Status

```
╔══════════════════════════════════════════════════════════════╗
║                    AIDA-RED STATUS                           ║
╠══════════════════════════════════════════════════════════════╣
║ Campaign: {{CAMPAIGN_ID}}                                    ║
║ Target: {{TARGET_PATH}}                                      ║
║ Phase: {{PHASE}}                                             ║
║ Duration: {{DURATION}}                                       ║
╠══════════════════════════════════════════════════════════════╣
║ VILLAINS                                                     ║
║ ┌────────┬──────────┬──────────┐                            ║
║ │ Name   │ Status   │ Findings │                            ║
║ ├────────┼──────────┼──────────┤                            ║
║ │ Joker  │ {{STATUS}} │ {{COUNT}} │                         ║
║ │ Shadow │ {{STATUS}} │ {{COUNT}} │                         ║
║ │ Chaos  │ {{STATUS}} │ {{COUNT}} │                         ║
║ └────────┴──────────┴──────────┘                            ║
╠══════════════════════════════════════════════════════════════╣
║ FINDINGS SUMMARY                                             ║
║   Critical: {{CRITICAL}}                                     ║
║   High: {{HIGH}}                                             ║
║   Medium: {{MEDIUM}}                                         ║
║   Low: {{LOW}}                                               ║
║   Total: {{TOTAL}}                                           ║
╚══════════════════════════════════════════════════════════════╝
```

### Verbose Output (--verbose)

```
╔══════════════════════════════════════════════════════════════╗
║                    AIDA-RED STATUS                           ║
╠══════════════════════════════════════════════════════════════╣
║ [Previous sections...]                                       ║
╠══════════════════════════════════════════════════════════════╣
║ DETAILED FINDINGS                                            ║
║                                                              ║
║ [CRITICAL] VUL-001 - Race Condition in Purchase              ║
║   Agent: Joker                                               ║
║   File: .aida-red/reports/joker/race-001.spec.ts             ║
║   Endpoint: POST /api/purchase                               ║
║                                                              ║
║ [HIGH] VUL-002 - IDOR in User Profile                        ║
║   Agent: Shadow                                              ║
║   File: .aida-red/reports/shadow/idor-001.spec.ts            ║
║   Endpoint: GET /api/users/:id                               ║
║                                                              ║
║ [HIGH] VUL-003 - JWT Algorithm Confusion                     ║
║   Agent: Shadow                                              ║
║   File: .aida-red/reports/shadow/jwt-001.spec.ts             ║
║   Endpoint: All authenticated endpoints                      ║
║                                                              ║
║ [MEDIUM] VUL-004 - Container Crash Data Loss                 ║
║   Agent: Chaos                                               ║
║   File: .aida-red/reports/chaos/crash-001.spec.ts            ║
║   Impact: Partial writes not rolled back                     ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Status Values

### Campaign Phases

| Phase | Description |
|-------|-------------|
| `INITIALIZED` | Campaign created, not started |
| `RECONNAISSANCE` | Gathering intelligence from specs |
| `ASSAULT` | Active attack in progress |
| `REPORTING` | Compiling final report |
| `COMPLETED` | Campaign finished |
| `PAUSED` | Temporarily stopped |

### Villain Statuses

| Status | Description |
|--------|-------------|
| `IDLE` | Not deployed |
| `ACTIVE` | Currently attacking |
| `COMPLETED` | Finished execution |
| `FAILED` | Crashed or errored |
| `PAUSED` | Temporarily stopped |

---

## No Active Campaign

If no campaign is active:

```
╔══════════════════════════════════════════════════════════════╗
║                    AIDA-RED STATUS                           ║
╠══════════════════════════════════════════════════════════════╣
║ Status: IDLE                                                 ║
║                                                              ║
║ No active campaign.                                          ║
║                                                              ║
║ Historical Summary:                                          ║
║   Total Campaigns: {{COUNT}}                                 ║
║   Total Findings: {{COUNT}}                                  ║
║   Last Campaign: {{DATE}}                                    ║
║                                                              ║
║ To start a new assault:                                      ║
║   /red:assault --target <path>                               ║
╚══════════════════════════════════════════════════════════════╝
```

---

## AIDA Integration Status

Also show AIDA's current state:

```
╔══════════════════════════════════════════════════════════════╗
║ AIDA INTEGRATION                                             ║
╠══════════════════════════════════════════════════════════════╣
║ AIDA Phase: {{PHASE}}                                        ║
║ Quality Gates: {{STATUS}}                                    ║
║ Injected Bugs: {{COUNT}} pending fixes                       ║
║                                                              ║
║ Next AIDA run will: {{PASS/FAIL}}                           ║
╚══════════════════════════════════════════════════════════════╝
```
