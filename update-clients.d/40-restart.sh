#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

# Create external network if it doesn't exist
if ! "${DOCKER_CMD[@]}" network inspect neonx-network >/dev/null 2>&1; then
    echo ">>> Creating external network: neonx-network"
    if "${DOCKER_CMD[@]}" network create neonx-network; then
        echo "  ✓ Network created"
    else
        echo "  ✗ Failed to create network"
        exit 1
    fi
fi

if [ "$RESTART_CONTAINERS" = true ]; then
    echo ">>> Restarting docker containers..."
    echo ""
    
    for client in "${CLIENTS[@]}"; do
        client_dir="$CLIENTS_DIR/$client"
        echo "Restarting client: $client"
        
        cd "$client_dir"
        
        # Check if docker-compose.yml exists
        if [ ! -f "docker-compose.yml" ]; then
            echo "  Warning: docker-compose.yml not found, skipping restart"
            continue
        fi
        
        # Restart containers
        if "${COMPOSE_CMD[@]}" down && "${COMPOSE_CMD[@]}" up -d; then
            echo "  ✓ Client '$client' restarted successfully"
        else
            echo "  ✗ Failed to restart client '$client'"
        fi
        
        echo ""
    done
    
    cd "$SCRIPT_DIR"
    echo ">>> All clients restarted!"
else
    echo "To apply changes, restart each client manually:"
    echo "  cd clients/<client-name> && docker compose down && docker compose up -d"
fi
