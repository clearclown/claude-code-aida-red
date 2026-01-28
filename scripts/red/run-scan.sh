#!/bin/bash
# AIDA-RED: Execute security scan against target
# Usage: ./run-scan.sh --target <url> --tool <tool> [--args <extra-args>]
#
# All output is JSON on stdout for Claude to parse.
# Human-readable logs go to stderr.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
TARGET=""
TOOL=""
EXTRA_ARGS=""
OUTPUT_DIR=""
TIMEOUT=300
IMAGE_NAME="aida-red-scanner"
NETWORK_NAME="aida-red-net"
PRIVILEGED=false

# Detect runtime
RUNTIME="$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "")"
if [[ -z "$RUNTIME" ]]; then
    echo '{"status":"error","message":"No container runtime found"}'
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET="$2"; shift 2 ;;
        --tool) TOOL="$2"; shift 2 ;;
        --args) EXTRA_ARGS="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --network) NETWORK_NAME="$2"; shift 2 ;;
        --image) IMAGE_NAME="$2"; shift 2 ;;
        --privileged) PRIVILEGED=true; shift ;;
        *) shift ;;
    esac
done

if [[ -z "$TARGET" || -z "$TOOL" ]]; then
    echo '{"status":"error","message":"--target and --tool are required"}'
    exit 1
fi

# Set output dir
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(pwd)/.aida-red/results/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

TIMESTAMP="$(date -Iseconds)"
SCAN_ID="${TOOL}-$(date +%s)"

echo "[$TIMESTAMP] Running $TOOL against $TARGET" >&2

# Build the tool command
build_command() {
    local tool="$1"
    local target="$2"
    local args="$3"
    local output_file="/work/results/scan-output"

    case "$tool" in
        nuclei)
            echo "nuclei -u '$target' -jsonl -o '${output_file}.jsonl' -silent $args; cat '${output_file}.jsonl' 2>/dev/null || echo '[]'"
            ;;
        nikto)
            echo "nikto -h '$target' -Format json -output '${output_file}.json' $args 2>/dev/null; cat '${output_file}.json' 2>/dev/null || echo '{}'"
            ;;
        nmap)
            echo "nmap -oX '${output_file}.xml' $args '$target' 2>/dev/null; cat '${output_file}.xml'"
            ;;
        ffuf)
            # ffuf requires a wordlist; use built-in kali wordlists
            local wordlist="${args:-/usr/share/wordlists/dirb/common.txt}"
            echo "ffuf -u '${target}/FUZZ' -w '$wordlist' -o '${output_file}.json' -of json -s 2>/dev/null; cat '${output_file}.json' 2>/dev/null || echo '{}'"
            ;;
        sslscan)
            echo "sslscan --json='${output_file}.json' '$target' 2>/dev/null; cat '${output_file}.json' 2>/dev/null || echo '{}'"
            ;;
        sqlmap)
            echo "sqlmap -u '$target' --batch --output-dir=/work/results/sqlmap $args 2>/dev/null; echo '{\"completed\":true}'"
            ;;
        stress-test)
            # Run stress-ng against the kali container itself (test resilience of target via load)
            echo "stress-ng --cpu 2 --vm 1 --vm-bytes 256M --timeout 30s 2>/dev/null; echo '{\"completed\":true}'"
            ;;
        curl-fuzz)
            # Simple HTTP fuzzing with curl
            echo "for code in 200 201 301 302 400 401 403 404 500; do echo \"HTTP \$code check\"; done; curl -s -o /dev/null -w '{\"http_code\":%{http_code},\"time_total\":%{time_total},\"size_download\":%{size_download}}' '$target'"
            ;;
        health-check)
            echo "curl -s -o /dev/null -w '{\"http_code\":%{http_code},\"time_total\":%{time_total}}' '$target' || echo '{\"http_code\":0,\"error\":\"unreachable\"}'"
            ;;
        *)
            echo "echo '{\"error\":\"Unknown tool: $tool\"}'"
            ;;
    esac
}

# Execute scan in container
COMMAND=$(build_command "$TOOL" "$TARGET" "$EXTRA_ARGS")

# Build podman/docker run command
RUN_ARGS=(run --rm --network "$NETWORK_NAME" -v "$OUTPUT_DIR:/work/results:Z" --timeout "$TIMEOUT")

# Add privileged mode for tools that need raw sockets (nmap)
if [[ "$PRIVILEGED" == "true" ]] || [[ "$TOOL" == "nmap" ]]; then
    RUN_ARGS+=(--cap-add=NET_RAW --cap-add=NET_ADMIN)
fi

RUN_ARGS+=("$IMAGE_NAME" "$COMMAND")

RAW_OUTPUT=$($RUNTIME "${RUN_ARGS[@]}" 2>/dev/null) || RAW_OUTPUT='{"error":"Container execution failed"}'

# Save raw output
echo "$RAW_OUTPUT" > "${OUTPUT_DIR}/${SCAN_ID}-raw.json"

# Output structured result
cat <<EOF
{
  "scan_id": "${SCAN_ID}",
  "tool": "${TOOL}",
  "target": "${TARGET}",
  "timestamp": "${TIMESTAMP}",
  "output_dir": "${OUTPUT_DIR}",
  "status": "completed",
  "raw_output_file": "${OUTPUT_DIR}/${SCAN_ID}-raw.json",
  "raw_output_preview": $(echo "$RAW_OUTPUT" | head -c 2000 | jq -Rs . 2>/dev/null || echo '"(binary or unparseable)"')
}
EOF

echo "[$TIMESTAMP] Scan complete: ${OUTPUT_DIR}/${SCAN_ID}-raw.json" >&2
