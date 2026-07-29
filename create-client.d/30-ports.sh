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
    python3 - "$CLIENT_DIR/docker-compose.yml" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
old = '    ports:\n      - "${HOST_PORT_18789:-18789}:18789"\n      - "${HOST_PORT_8001:-8001}:8001" # For download files from the agent\n'
new = '    ports: []\n'
if old in text:
    text = text.replace(old, new)
else:
    text = text.replace('    ports:\n', '    ports: []\n')
path.write_text(text)
PY
    echo ">>> Ports will not be exposed to the host"
fi
