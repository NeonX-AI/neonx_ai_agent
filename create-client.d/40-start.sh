#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/create-client.d/00-common.sh"

# --- Step 6: Start services ---
echo ">>> Starting services for client: $CLIENT_NAME"
cd "$CLIENT_DIR"

# Create external network if it doesn't exist
if ! docker network inspect neonx-network >/dev/null 2>&1; then
    echo ">>> Creating external network: neonx-network"
    if docker network create neonx-network 2>/dev/null; then
        echo "  ✓ Network created"
    else
        echo "  ! Failed to create network. You may need to run manually:"
        echo "    docker network create neonx-network"
    fi
fi

STACK_NAME="$CLIENT_NAME" API_KEY="$API_KEY" BASE_URL="$BASE_URL" $COMPOSE_CMD up -d --force-recreate

echo ">>> Done! Client '$CLIENT_NAME' is running."
$COMPOSE_CMD ps
