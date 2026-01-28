---
description: "Generate and display a detailed security report from AIDA-RED scan results."
argument-hint: "[--latest | --file <path>] [--severity <min-level>]"
---

# /aida:red-report

Generate a human-readable security report from scan results.

## Usage

```
/aida:red-report
/aida:red-report --latest
/aida:red-report --file .aida-red/reports/assault-20260128.json
/aida:red-report --severity high
```

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--latest` | Show the most recent report | Default behavior |
| `--file` | Path to specific report JSON | Most recent |
| `--severity` | Minimum severity to show: info, low, medium, high, critical | info |

---

## EXECUTION PROTOCOL

### Step 1: Find Report File

```bash
# Find the latest report
LATEST=$(ls -t .aida-red/reports/assault-*.json 2>/dev/null | head -1)
echo "$LATEST"
```

If no report exists, inform user to run `/aida:red-assault` first.

### Step 2: Read and Analyze

Read the JSON report file with the Read tool. Parse the findings array.

### Step 3: Present Report

Generate a formatted report covering:

1. **Executive Summary**: Target, date, total findings by severity
2. **Critical & High Findings**: Full details with remediation
3. **Medium & Low Findings**: Summary list
4. **Tool Coverage**: Which tools were used, what they found
5. **Recommendations**: Prioritized action items

Format:

```
AIDA-RED Security Report
========================

Target:    http://localhost:8080
Scanned:   2026-01-28T14:30:00Z
Tools:     nuclei, nikto, nmap, sslscan

Summary: 2 High, 5 Medium, 3 Low, 10 Info

--- HIGH SEVERITY ---

[HIGH] Outdated TLS Configuration
  Tool:        sslscan
  Evidence:    TLS 1.0 is enabled
  Impact:      Vulnerable to BEAST, POODLE attacks
  Remediation: Disable TLS 1.0 and 1.1 in server config.
               Enable only TLS 1.2+ with strong cipher suites.

[HIGH] Missing Security Headers
  Tool:        nikto
  Evidence:    X-Frame-Options, CSP, HSTS headers not set
  Impact:      Clickjacking, XSS, downgrade attacks possible
  Remediation: Add security headers to HTTP responses:
    X-Frame-Options: DENY
    Content-Security-Policy: default-src 'self'
    Strict-Transport-Security: max-age=31536000

--- MEDIUM SEVERITY ---

[MED] Server Version Disclosure
  Tool:    nikto
  Fix:     Remove Server header or set to generic value

[MED] Open Database Port (5432)
  Tool:    nmap
  Fix:     Restrict to internal network only

[MED] Directory Listing Enabled
  Tool:    ffuf
  Fix:     Disable directory listing in web server config

--- RECOMMENDATIONS ---

Priority 1 (Immediate):
  - Disable TLS 1.0/1.1
  - Add security headers

Priority 2 (This Sprint):
  - Close exposed database port
  - Disable directory listing

Priority 3 (Backlog):
  - Remove server version disclosure
  - Review informational findings
```

---

## Output Formats

If user requests JSON or wants to save:

```bash
# The raw report is already JSON
cat .aida-red/reports/assault-*.json | jq .
```
