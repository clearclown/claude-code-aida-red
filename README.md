# AIDA-RED: Defensive Security Testing Framework

**AIDA-RED** (Automated Intrusion & Destruction Architecture) - The Red Team counterpart to AIDA.

<p align="center">
  <img src="docs/pics/aida-red-logo.svg" alt="AIDA-RED Logo" width="600">
</p>

English | [日本語](docs/readmeLang/README_ja.md) | [简体中文](docs/readmeLang/README_zh-CN.md) | [繁體中文](docs/readmeLang/README_zh-TW.md) | [Русский](docs/readmeLang/README_ru.md) | [فارسی](docs/readmeLang/README_fa.md) | [العربية](docs/readmeLang/README_ar.md)

> **"If it breaks, it wasn't ready."**

---

## Overview

AIDA-RED is a **defensive security testing framework** that integrates with [claude-code-aida](https://github.com/clearclown/claude-code-aida). While AIDA focuses on **building** applications with TDD, AIDA-RED focuses on **breaking** them to find vulnerabilities before attackers do.

**Key Innovation**: AIDA-RED uses **Podman/Docker containers** running **Kali Linux** security tools, orchestrated by Claude Code. Claude doesn't write attack code - it calls battle-tested open source security tools and analyzes their output.

### Philosophy

1. **Zero Trust**: Assume every input is an attack vector
2. **Zero Mock**: Attack the running container, not isolated functions
3. **Real Tools**: Use proven security scanners (nuclei, nikto, nmap), not custom exploits
4. **Actionable Reports**: Every finding includes reproduction steps and remediation advice

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Code                               │
│                    (Orchestrator & Analyst)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ /aida:red-  │  │ /aida:red-  │  │ /aida:red-  │              │
│  │    init     │  │   assault   │  │   report    │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
└─────────┼────────────────┼────────────────┼─────────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Podman / Docker                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              aida-red-scanner (Kali Linux)                 │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │ │
│  │  │ nuclei  │ │  nikto  │ │  nmap   │ │  ffuf   │  ...     │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                             │                                    │
│                    aida-red-net (Podman Network)                │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 Target Application                         │ │
│  │            (Your AIDA-generated project)                   │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Tools

AIDA-RED comes with industry-standard security tools pre-installed:

| Tool | Purpose | Use Case |
|------|---------|----------|
| **[nuclei](https://github.com/projectdiscovery/nuclei)** | Template-based vulnerability scanner | CVE detection, misconfigurations |
| **[nikto](https://github.com/sullo/nikto)** | Web server scanner | Server misconfigurations, outdated software |
| **[nmap](https://nmap.org/)** | Network scanner | Port discovery, service detection |
| **[ffuf](https://github.com/ffuf/ffuf)** | Web fuzzer | Directory brute-forcing, parameter fuzzing |
| **[sslscan](https://github.com/rbsec/sslscan)** | SSL/TLS analyzer | Certificate issues, weak ciphers |
| **[sqlmap](https://sqlmap.org/)** | SQL injection detector | Database vulnerabilities (full image) |
| **[stress-ng](https://github.com/ColinIanKing/stress-ng)** | Stress tester | Resource exhaustion testing |

---

## Installation

### Prerequisites

- **Podman** (recommended) or **Docker**
- **Claude Code** with AIDA plugin installed

```bash
# Install Podman (Ubuntu/Debian)
sudo apt install podman

# Or Docker
sudo apt install docker.io
```

### Install AIDA-RED

AIDA-RED is included in the AIDA plugin. No separate installation needed.

```bash
# Verify installation
/aida:red-status
```

### Build Scanner Image

```bash
# Initialize and build the Kali scanner container
/aida:red-init

# Or use lightweight version (faster build, fewer tools)
/aida:red-init --lite
```

**Image Sizes:**
- Full: ~2GB (includes sqlmap, ZAP CLI)
- Lite: ~624MB (nuclei, nikto, nmap, ffuf, sslscan)

---

## Usage

### Quick Start

```bash
# 1. Build your application with AIDA
/aida "Create a REST API with user authentication"

# 2. Initialize AIDA-RED scanner
/aida:red-init --lite

# 3. Run security scan against your running app
/aida:red-assault --target http://localhost:8080

# 4. View the report
/aida:red-report
```

### Commands

| Command | Description |
|---------|-------------|
| `/aida:red-init` | Build Kali scanner container, create network |
| `/aida:red-assault` | Run security scans against target |
| `/aida:red-status` | Show scanner status and recent findings |
| `/aida:red-report` | Generate detailed vulnerability report |
| `/aida:red-cleanup` | Remove containers and network |

### Assault Options

```bash
# Basic scan (standard intensity)
/aida:red-assault --target http://localhost:8080

# Maximum intensity (all tools)
/aida:red-assault --target http://localhost:8080 --intensity maximum

# Specific tools only
/aida:red-assault --target http://localhost:8080 --tools nuclei,nikto

# Scan AIDA project (auto-detect running services)
/aida:red-assault --target ../my-aida-project
```

### Intensity Levels

| Level | Tools | Duration |
|-------|-------|----------|
| `minimum` | nuclei, health-check | ~1 min |
| `standard` | nuclei, nikto, nmap, sslscan | ~5 min |
| `maximum` | All tools including ffuf, sqlmap | ~15 min |

---

## Example Output

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

Full report: .aida-red/reports/assault-20260128.json
```

---

## Directory Structure

```
your-project/
├── .aida/                    # AIDA build artifacts
│   └── tdd-evidence/
│       └── external-bugs/    # AIDA-RED injects findings here
│
├── .aida-red/                # AIDA-RED local state
│   ├── config/
│   │   └── scanner.json      # Scanner configuration
│   ├── results/              # Raw scan outputs
│   │   └── 20260128_143000/
│   │       ├── nmap-*.json
│   │       ├── nikto-*.json
│   │       └── nuclei-*.jsonl
│   └── reports/              # Analyzed reports
│       └── assault-20260128.json
│
└── (your application code)

# Plugin structure (in claude-code-aida-red/)
├── commands/
│   ├── red-init.md           # /aida:red-init
│   ├── red-assault.md        # /aida:red-assault
│   ├── red-status.md         # /aida:red-status
│   ├── red-report.md         # /aida:red-report
│   └── red-cleanup.md        # /aida:red-cleanup
├── container/
│   ├── Containerfile         # Full Kali scanner image
│   └── Containerfile.lite    # Lightweight version
├── scripts/red/
│   ├── setup-kali.sh         # Build image & network
│   ├── run-scan.sh           # Execute individual tools
│   ├── parse-results.sh      # Parse tool outputs to JSON
│   └── cleanup.sh            # Remove containers
└── aida-red/
    └── agents/               # Villain agent definitions
        ├── warlord.md        # Orchestrator
        ├── joker.md          # Fuzzing specialist
        ├── shadow.md         # Security specialist
        └── chaos.md          # Infrastructure specialist
```

---

## Integration with AIDA

AIDA-RED automatically integrates with AIDA's workflow:

1. **Auto-Trigger**: When AIDA completes (quality gates pass), AIDA-RED suggests running a security scan

2. **Evidence Injection**: Findings are written to `.aida/tdd-evidence/external-bugs/`, causing AIDA's quality gates to **fail** until issues are fixed

3. **Continuous Loop**: Fix vulnerabilities → AIDA rebuilds → AIDA-RED scans again → repeat until clean

```
AIDA Build Complete
        ↓
AIDA-RED Scan
        ↓
Vulnerabilities Found? ─── No ───→ Done!
        │
       Yes
        ↓
Inject into AIDA Evidence
        ↓
AIDA Quality Gates FAIL
        ↓
Developer Fixes Issues
        ↓
AIDA Rebuild → Loop
```

---

## The Three Villains (Agent Personas)

AIDA-RED uses three specialized "Villain" agents for different attack vectors:

### The Joker (Logic Fuzzer)
Generates inputs that are "technically valid but logically destructive."
- Boundary values, massive payloads, Unicode injection
- Race conditions, integer overflows
- Tools: `ffuf`, `nuclei` (fuzzing templates)

### The Shadow (Security Breaker)
Finds authorization bypasses and data leakage.
- IDOR, privilege escalation, JWT manipulation
- SQL injection, authentication bypass
- Tools: `nuclei`, `nikto`, `sqlmap`

### The Chaos (Infrastructure Smasher)
Breaks the environment, not just the code.
- Container crashes, network partitions
- Resource exhaustion, monkey testing
- Tools: `stress-ng`, `nmap`

---

## Configuration

### Scanner Configuration

`.aida-red/config/scanner.json`:

```json
{
  "initialized_at": "2026-01-28T14:00:00Z",
  "runtime": "podman",
  "image": "aida-red-scanner-lite",
  "network": "aida-red-net",
  "default_tools": ["nuclei", "nikto", "nmap", "sslscan"],
  "timeout": 300,
  "severity_threshold": "low"
}
```

### Custom Nuclei Templates

Add custom vulnerability templates:

```bash
# Copy templates to scanner
podman cp ./my-templates/ aida-red-kali:/work/templates/

# Run with custom templates
/aida:red-assault --target http://localhost:8080 --args "-t /work/templates/"
```

---

## Troubleshooting

### "No container runtime found"

Install Podman or Docker:
```bash
sudo apt install podman  # Ubuntu/Debian
brew install podman      # macOS
```

### "Image build failed"

Try the lite version (smaller, fewer dependencies):
```bash
/aida:red-init --lite
```

### "nmap: Operation not permitted"

The script automatically adds `--cap-add=NET_RAW` for nmap. If running manually:
```bash
podman run --cap-add=NET_RAW --cap-add=NET_ADMIN aida-red-scanner-lite "nmap ..."
```

### "Target unreachable"

Ensure target is on the same Podman network:
```bash
podman network connect aida-red-net your-app-container
```

---

## Security Considerations

AIDA-RED is designed for **defensive security testing** of your own applications:

- Only scan applications you own or have permission to test
- Never use against production systems without authorization
- Results may include false positives - verify findings manually
- Some tools (sqlmap) can modify data - use with caution

---

## Contributing

Contributions welcome! Areas of interest:

- Additional tool integrations (Burp Suite CLI, OWASP ZAP)
- Custom nuclei templates for common frameworks
- Better result parsing and deduplication
- CI/CD integration examples

---

## License

MIT License - Use responsibly. You are responsible for how you use these tools.

---

## Credits

- [Kali Linux](https://www.kali.org/) - The security distribution
- [Project Discovery](https://projectdiscovery.io/) - Nuclei and other tools
- [OWASP](https://owasp.org/) - Security testing methodologies
- [claude-code-aida](https://github.com/clearclown/claude-code-aida) - The builder that AIDA-RED tests
