---
description: "Show AIDA-RED scanner status, available tools, and recent scan results."
---

# /aida:red-status

Show the current state of AIDA-RED: container status, available tools, and recent findings.

## Usage

```
/aida:red-status
```

---

## EXECUTION PROTOCOL

### Step 1: Check Container Runtime

```bash
RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "none")
echo "Runtime: $RUNTIME"

if [[ "$RUNTIME" != "none" ]]; then
  # Check image
  $RUNTIME image exists aida-red-scanner 2>/dev/null && echo "Image: ready" || echo "Image: not built"

  # Check network
  $RUNTIME network exists aida-red-net 2>/dev/null && echo "Network: ready" || echo "Network: not created"

  # Check running containers
  $RUNTIME ps --filter "name=aida-red" --format "{{.Names}} {{.Status}}" 2>/dev/null
fi
```

### Step 2: Check Local State

```bash
# Recent results
ls -lt .aida-red/results/ 2>/dev/null | head -5

# Recent reports
ls -lt .aida-red/reports/ 2>/dev/null | head -5

# Count total findings
find .aida-red/reports -name "*.json" -exec jq '.summary.total // 0' {} \; 2>/dev/null | paste -sd+ | bc 2>/dev/null || echo 0
```

### Step 3: Display Status

Present the results:

```
AIDA-RED Status
===============

Runtime:   podman v5.x
Image:     aida-red-scanner (ready)
Network:   aida-red-net (ready)

Available Tools:
  nuclei    - Template-based vulnerability scanner
  nikto     - Web server misconfiguration scanner
  nmap      - Network port scanner
  ffuf      - Web fuzzer
  sslscan   - SSL/TLS analyzer
  sqlmap    - SQL injection detector
  stress-ng - Resource stress tester

Recent Scans:
  2026-01-28 14:30  http://localhost:8080   5 findings (2H/3M)
  2026-01-27 09:15  http://localhost:3000   0 findings (clean)

Commands:
  /aida:red-init       Initialize / rebuild scanner
  /aida:red-assault    Run security scan
  /aida:red-report     View detailed report
  /aida:red-cleanup    Remove containers and cleanup
```
