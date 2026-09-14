#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/create-client.d/00-common.sh"

# --- Step 5: Optional host port exposure ---
read -rp "Expose ports to host? [y/N]: " PUBLISH_PORTS
PUBLISH_PORTS="${PUBLISH_PORTS:-N}"

if [[ "$PUBLISH_PORTS" =~ ^[Yy]$ ]]; then
    read -rp "Host port for 18789 [18789]: " HOST_PORT_18789
    HOST_PORT_18789="${HOST_PORT_18789:-18789}"

    read -rp "Host port for 8001 [8001]: " HOST_PORT_8001
    HOST_PORT_8001="${HOST_PORT_8001:-8001}"

    update_or_append "$ENV_FILE" "HOST_PORT_18789" "$HOST_PORT_18789"
    update_or_append "$ENV_FILE" "HOST_PORT_8001" "$HOST_PORT_8001"
    echo ">>> Ports will be exposed on host: 18789->$HOST_PORT_18789, 8001->$HOST_PORT_8001"
else
    update_or_append "$ENV_FILE" "HOST_PORT_18789" ""
    update_or_append "$ENV_FILE" "HOST_PORT_8001" ""
    # Use awk to remove ports section (cross-platform, no Python needed)
    awk '
    /^    ports:/ {
        print "    ports: []"
        skip=1
        next
    }
    skip && /^      - / { next }
    skip && !/^      - / { skip=0 }
    { print }
    ' "$CLIENT_DIR/docker-compose.yml" > "$CLIENT_DIR/docker-compose.yml.tmp" && mv "$CLIENT_DIR/docker-compose.yml.tmp" "$CLIENT_DIR/docker-compose.yml"
    echo ">>> Ports will not be exposed to the host"
fi
