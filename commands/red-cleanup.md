---
description: "Clean up AIDA-RED containers, network, and optionally remove images."
argument-hint: "[--all]"
---

# /aida:red-cleanup

Remove AIDA-RED containers and network. Optionally remove built images.

## Usage

```
/aida:red-cleanup
/aida:red-cleanup --all
```

- `--all`: Also remove the scanner image (requires rebuild on next use)

---

## EXECUTION PROTOCOL

### Step 1: Run Cleanup

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/cleanup.sh"
```

Or with `--all`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/cleanup.sh" --all
```

### Step 2: Report

Read the JSON output and report:

```
AIDA-RED Cleanup Complete

Removed: 2 containers, 1 network, 0 images

To reinitialize: /aida:red-init
```
