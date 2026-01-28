---
description: "Initialize AIDA-RED security scanner. Build Kali container and setup network."
argument-hint: "[--lite]"
---

# /aida:red-init

Initialize the AIDA-RED defensive security testing environment.

## Usage

```
/aida:red-init
/aida:red-init --lite
```

- `--lite`: Build lightweight image (faster, fewer tools)

---

## MANDATORY EXECUTION PROTOCOL

**Execute these steps in order. Do NOT skip any step.**

### Step 1: Detect Container Runtime

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/setup-kali.sh"
```

Read the JSON output. If `status` is `"error"`, inform the user they need to install podman or docker.

If the user passed `--lite`, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/setup-kali.sh" --lite
```

### Step 2: Create Local Directories

```bash
mkdir -p .aida-red/results .aida-red/reports .aida-red/config
```

### Step 3: Write Configuration

Create `.aida-red/config/scanner.json`:

```json
{
  "initialized_at": "<ISO8601>",
  "runtime": "<from step 1 output>",
  "image": "<from step 1 output>",
  "network": "aida-red-net",
  "default_tools": ["nuclei", "nikto", "nmap", "ffuf", "sslscan"],
  "lite_mode": false
}
```

### Step 4: Verify

Run a quick health check to verify the container works:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/red/run-scan.sh" \
  --tool health-check \
  --target https://httpbin.org/get \
  --network host
```

### Step 5: Report

```
AIDA-RED Initialized

Runtime: podman (or docker)
Image: aida-red-scanner
Network: aida-red-net

Available Tools:
  - nuclei    (vulnerability scanner)
  - nikto     (web server scanner)
  - nmap      (port scanner)
  - ffuf      (fuzzer)
  - sslscan   (SSL/TLS analyzer)
  - sqlmap    (SQL injection detection)    [full mode only]
  - zap-cli   (OWASP ZAP)                 [full mode only]

Next: /aida:red-assault --target <url>
```

---

## Error Handling

| Error | Action |
|-------|--------|
| No podman/docker | Tell user to install: `sudo apt install podman` or `sudo apt install docker.io` |
| Build fails | Show build output, suggest `--lite` for faster build |
| Network exists | Skip network creation (idempotent) |
| Image exists | Skip build (use `--rebuild` to force) |
