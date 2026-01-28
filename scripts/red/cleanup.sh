#!/bin/bash
# AIDA-RED: Cleanup containers and network
# Usage: ./cleanup.sh [--all]
#
# --all: Also remove the scanner image

set -euo pipefail

RUNTIME="$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "")"
if [[ -z "$RUNTIME" ]]; then
    echo '{"status":"error","message":"No container runtime found"}'
    exit 1
fi

REMOVE_IMAGE=false
[[ "${1:-}" == "--all" ]] && REMOVE_IMAGE=true

removed_containers=0
removed_networks=0
removed_images=0

# Stop and remove AIDA-RED containers
for container in $($RUNTIME ps -a --filter "name=aida-red" --format "{{.Names}}" 2>/dev/null); do
    echo "Removing container: $container" >&2
    $RUNTIME rm -f "$container" >/dev/null 2>&1 || true
    ((removed_containers++))
done

# Remove network
if $RUNTIME network exists aida-red-net 2>/dev/null; then
    echo "Removing network: aida-red-net" >&2
    $RUNTIME network rm aida-red-net >/dev/null 2>&1 || true
    ((removed_networks++))
fi

# Remove images if --all
if [[ "$REMOVE_IMAGE" == "true" ]]; then
    for image in aida-red-scanner aida-red-scanner-lite; do
        if $RUNTIME image exists "$image" 2>/dev/null; then
            echo "Removing image: $image" >&2
            $RUNTIME rmi "$image" >/dev/null 2>&1 || true
            ((removed_images++))
        fi
    done
fi

cat <<EOF
{
  "status": "cleaned",
  "removed_containers": ${removed_containers},
  "removed_networks": ${removed_networks},
  "removed_images": ${removed_images}
}
EOF
