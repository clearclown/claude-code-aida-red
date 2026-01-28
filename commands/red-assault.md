---
description: "Run AIDA-RED security scan against a target URL or local AIDA project."
argument-hint: "--target <url-or-path> [--tools <tool1,tool2,...>] [--intensity <level>]"
---

# /aida:red-assault

Launch a defensive security scan against a target application.

## Usage

```
/aida:red-assault --target http://localhost:8080
/aida:red-assault --target http://localhost:8080 --tools nuclei,nikto
/aida:red-assault --target ../my-aida-project --intensity maximum
```

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--target` | URL to scan, or path to AIDA project | Required |
| `--tools` | Comma-separated list of tools | Depends on intensity |
| `--intensity` | `minimum`, `standard`, `maximum` | `standard` |

### Tool Selection by Intensity

| Intensity | Tools |
|-----------|-------|
| `minimum` | nuclei, health-check |
| `standard` | nuclei, nikto, nmap, sslscan |
| `maximum` | nuclei, nikto, nmap, ffuf, sslscan, sqlmap |

---

## MANDATORY EXECUTION PROTOCOL

**Execute these steps in order using Bash tool.**

### Step 0: Validate Prerequisites

Check that AIDA-RED is initialized:

```bash
# Check scanner image exists
RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null)
$RUNTIME image exists aida-red-scanner 2>/dev/null && echo "ready" || echo "not-initialized"
```

If `not-initialized`, tell user to run `/aida:red-init` first.

### Step 1: Resolve Target

If `--target` is a path (not a URL):

```bash
# Check if it's an AIDA project
if [[ -d "$TARGET/.aida" ]]; then
    # Read docker-compose to find exposed ports
    # Look for health endpoints
    echo "AIDA project detected. Looking for running services..."
fi
```

If target is a URL, use it directly.

### Step 2: Determine Tools

Based on intensity, select the tools to run. If `--tools` is specified, use that list instead.

### Step 3: Network Setup

If target is a Docker/Podman container, connect it to aida-red-net:

```bash
RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null)

# Create network if needed
$RUNTIME network exists aida-red-net 2>/dev/null || $RUNTIME network create aida-red-net

# If target is a container, connect to network
# $RUNTIME network connect aida-red-net <target-container>
```

### Step 4: Run Scans

**Execute each tool using the run-scan.sh script.**

For each selected tool, call:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" \
  --tool <tool-name> \
  --target <target-url> \
  --output .aida-red/results/<timestamp>
```

**Run independent tools in parallel where possible** using Bash background jobs or separate Bash tool calls.

Example for `standard` intensity:

```bash
# These can run in parallel
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" --tool nuclei --target "$TARGET" --output .aida-red/results/current &
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" --tool nikto --target "$TARGET" --output .aida-red/results/current &
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" --tool nmap --target "$TARGET" --output .aida-red/results/current &
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" --tool sslscan --target "$TARGET" --output .aida-red/results/current &
wait
```

### Step 5: Parse Results

For each completed scan, parse the raw output into unified findings:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/parse-results.sh" \
  --tool <tool-name> \
  --input .aida-red/results/current/<scan-id>-raw.json \
  --severity-min low
```

### Step 6: Analyze & Report

**This is where YOU (Claude) add value.**

Read all parsed findings and:

1. **Deduplicate**: Merge overlapping findings from different tools
2. **Classify**: Assign final severity based on context
3. **Prioritize**: Order by risk (Critical > High > Medium > Low)
4. **Explain**: Provide human-readable descriptions and remediation advice
5. **Generate reproduction steps**: Where possible, create curl/test commands

### Step 7: Save Report

Write unified report to `.aida-red/reports/assault-<timestamp>.json`:

```json
{
  "campaign_id": "<uuid>",
  "target": "<url>",
  "timestamp": "<ISO8601>",
  "tools_used": ["nuclei", "nikto", "nmap", "sslscan"],
  "findings": [
    {
      "id": "FINDING-001",
      "severity": "high",
      "tool": "nuclei",
      "title": "...",
      "description": "...",
      "remediation": "...",
      "evidence": "..."
    }
  ],
  "summary": {
    "critical": 0,
    "high": 2,
    "medium": 5,
    "low": 3,
    "info": 10,
    "total": 20
  }
}
```

### Step 8: AIDA Integration (if applicable)

If target is an AIDA project and findings exist:

```bash
# Write findings to AIDA's evidence directory
mkdir -p "$TARGET/.aida/tdd-evidence/external-bugs"
cp .aida-red/reports/assault-*.json "$TARGET/.aida/tdd-evidence/external-bugs/"
```

### Step 9: Present Results

Show a summary table to the user:

```
AIDA-RED Assault Complete

Target: http://localhost:8080
Duration: 2m 34s
Tools: nuclei, nikto, nmap, sslscan

Findings:
  Critical:  0
  High:      2
  Medium:    5
  Low:       3
  Info:      10

Top Issues:
  [HIGH] Outdated TLS Configuration - TLS 1.0 enabled
  [HIGH] Missing Security Headers - X-Frame-Options not set
  [MED]  Information Disclosure - Server version in headers
  [MED]  Open Port - Port 5432 (PostgreSQL) exposed
  [MED]  Directory Listing - /assets/ directory listing enabled

Full report: .aida-red/reports/assault-<timestamp>.json
```

---

## Cleanup

After the scan completes, clean up temporary containers:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/cleanup.sh"
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Target unreachable | Report connection error, check URL |
| Tool timeout | Report partial results, note the timeout |
| Container crash | Retry once, report if persistent |
| No findings | Report clean scan (this is good news!) |
| Permission denied | Suggest running with appropriate permissions |
