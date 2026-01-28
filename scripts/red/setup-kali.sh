#!/bin/bash
# AIDA-RED: Setup Kali security scanner container
# Usage: ./setup-kali.sh [--lite] [--rebuild]
#
# This script builds the AIDA-RED scanner image and prepares the network.
# Detects podman or docker automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINER_DIR="${PLUGIN_ROOT}/container"

IMAGE_NAME="aida-red-scanner"
NETWORK_NAME="aida-red-net"
CONTAINER_NAME="aida-red-kali"

LITE=false
REBUILD=false

# Detect container runtime (podman preferred)
detect_runtime() {
    if command -v podman &>/dev/null; then
        echo "podman"
    elif command -v docker &>/dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

RUNTIME=$(detect_runtime)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --lite) LITE=true; shift ;;
        --rebuild) REBUILD=true; shift ;;
        *) shift ;;
    esac
done

# Check runtime
if [[ -z "$RUNTIME" ]]; then
    echo '{"status":"error","message":"Neither podman nor docker found. Install one first.","runtime":null}'
    exit 1
fi

# Select Containerfile
if [[ "$LITE" == "true" ]]; then
    CONTAINERFILE="${CONTAINER_DIR}/Containerfile.lite"
    IMAGE_NAME="aida-red-scanner-lite"
else
    CONTAINERFILE="${CONTAINER_DIR}/Containerfile"
fi

# Check if image exists
image_exists() {
    $RUNTIME image exists "$IMAGE_NAME" 2>/dev/null
}

# Build image
build_image() {
    echo "Building ${IMAGE_NAME}..." >&2
    $RUNTIME build \
        -t "$IMAGE_NAME" \
        -f "$CONTAINERFILE" \
        "$CONTAINER_DIR" >&2 2>&1
}

# Create network
create_network() {
    if ! $RUNTIME network exists "$NETWORK_NAME" 2>/dev/null; then
        $RUNTIME network create "$NETWORK_NAME" >&2 2>&1
    fi
}

# Main
main() {
    # Build if needed
    if [[ "$REBUILD" == "true" ]] || ! image_exists; then
        build_image
    fi

    # Create network
    create_network

    # Output status as JSON (stdout = structured data for Claude)
    cat <<EOF
{
  "status": "ready",
  "runtime": "${RUNTIME}",
  "image": "${IMAGE_NAME}",
  "network": "${NETWORK_NAME}",
  "container_name": "${CONTAINER_NAME}",
  "lite": ${LITE},
  "tools": {
    "nuclei": true,
    "nikto": true,
    "nmap": true,
    "ffuf": true,
    "sslscan": true,
    "stress_ng": true,
    "sqlmap": $([ "$LITE" == "false" ] && echo "true" || echo "false"),
    "zap_cli": $([ "$LITE" == "false" ] && echo "true" || echo "false")
  }
}
EOF
}

main "$@"
