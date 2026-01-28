# AIDA-RED: The Red Team Architecture

**AIDA-RED** (Automated Intrusion & Destruction Architecture) - The Nemesis of AIDA.

<p align="center">
  <img src="docs/pics/aida-red-logo.svg" alt="AIDA-RED Logo" width="600">
</p>

> **"If it breaks, it wasn't ready."**

## Overview

AIDA-RED is the "Red Team" counterpart to [claude-code-aida](https://github.com/clearclown/claude-code-aida). While AIDA focuses on **Construction** and passing tests, AIDA-RED focuses on **Destruction** and finding what tests missed.

It is an infinite AI-driven debugging loop that assaults the target application with fuzzing, logical exploits, and chaos engineering until a fix is deployed.

### The Philosophy of Destruction
1.  **Zero Trust**: Assume every input is an attack.
2.  **Zero Mock**: Attack the running container, not the isolated function.
3.  **Infinite Loop**: The attack stops only when the bug is fixed.

---

## The Three Villains (Agents)

AIDA-RED orchestrates three specialized destructive agents:

### 🎭 The Joker (Logic Fuzzer)
Reads `.aida/specs/*-design.md` and generates inputs that are "technically valid but logically destructive."
- **Attacks**: Boundary values, massive payloads, Unicode injection, race conditions.
- **Goal**: Trigger panics, unhandled exceptions, and timeouts.

### 🥷 The Shadow (Security Breaker)
Analyzes the source code in `src/` to hypothesize logical vulnerabilities.
- **Attacks**: IDOR (Insecure Direct Object References), Privilege Escalation, JWT manipulation, Business Logic flaws.
- **Goal**: Access data without authorization, bypass payments.

### 🐒 The Chaos (Infrastructure Smasher)
Targets the environment and UX.
- **Attacks**: Random Docker stops, Network throttling, rapid-fire UI interaction (Monkey Testing).
- **Goal**: Corrupt data state, freeze frontend, break consistency.

---

## Workflow: The Cycle of Pain

AIDA-RED works in tandem with AIDA:

1.  **Watch**: Waits for AIDA to declare `IMPL_PHASE` complete.
2.  **Assault**: Launches The Villains against the target project.
3.  **Capture**: When a crash occurs, generates a **Reproduction Script** (Playwright or Go test).
4.  **Report**: Injects the failing test into `.aida/tdd-evidence/failures/`.
5.  **Loop**: Waits for AIDA to fix it, then attacks again with evolved patterns.

---

## Directory Structure

```text
~/.claude-code-aida-red/
  ├── agents/             # The Villain Personas
  │   ├── warlord.md      # Command & Control (Orchestrator)
  │   ├── joker.md        # Fuzzing Specialist
  │   ├── shadow.md       # Security Specialist
  │   └── chaos.md        # Infrastructure Specialist
  ├── arsenal/            # Attack Libraries
  │   ├── payloads/       # Fuzzing dictionaries
  │   └── exploits/       # Common vulnerability patterns
  ├── operations/         # Active mission state
  │   └── targets.json    # Current victims
  └── reports/            # Generated vulnerability reports

```

## Installation

```bash
# Install AIDA-RED (Requires AIDA to be installed)
curl -sSL [https://raw.githubusercontent.com/clearclown/claude-code-aida-red/main/install.sh](https://raw.githubusercontent.com/clearclown/claude-code-aida-red/main/install.sh) | bash

# Verify
/red:status

```

## Usage

### Start the Onslaught

Target an existing AIDA project and begin the infinite debug loop.

```bash
/red:assault --target=../my-project --intensity=maximum

```

### Specific Infiltration

Run only specific agents.

```bash
/red:infiltrate --agent=shadow --focus="auth_module"

```

## License

MIT (Use responsibly. You are responsible for any destruction caused.)
