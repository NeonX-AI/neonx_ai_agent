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
    echo ">>> Preparing OpenClaw upgrade..."
    echo ""

    # OpenClaw migrations must run while the gateway is stopped. Stop every
    # client before touching any state database.
    # This prevents one client from continuing to use a database while another
    # client is being migrated during a batch upgrade.
    stopped_clients=()

    echo ">>> Stopping all client gateways..."
    for client in "${CLIENTS[@]}"; do
        client_dir="$CLIENTS_DIR/$client"
        [ -f "$client_dir/docker-compose.yml" ] || continue

        echo "Stopping client: $client"
        if (cd "$client_dir" && "${COMPOSE_CMD[@]}" down); then
            echo "  ✓ Stopped"
            stopped_clients+=("$client")
        else
            echo "  ✗ Failed to stop; skipping migration for safety"
        fi
    done

    echo ""
    echo ">>> Migrating OpenClaw state databases..."
    for client in "${stopped_clients[@]}"; do
        client_dir="$CLIENTS_DIR/$client"
        [ -f "$client_dir/docker-compose.yml" ] || continue

        echo "Migrating client: $client"
        rm -f "$client_dir/.openclaw-migration-failed"
        # Restore any persisted Zalo setup before doctor validates plugins. The
        # OpenClaw image upgrade removes global npm packages such as `openzca`,
        # while the Zalo extension/config lives under agent_data.
        # The module is a no-op for clients without an existing Zalo setup.
        # The persistent message-listener plugin is also validated before
        # OpenClaw applies every pending migration (including audit-events-v2).
        if (cd "$client_dir" && "${COMPOSE_CMD[@]}" run --rm --no-deps --entrypoint /bin/sh ai_agent -c \
            '. /bootstrap/modules/plugins/openclaw-message-listener.sh && . /bootstrap/modules/plugins/zalo.sh && openclaw doctor --fix'); then
            echo "  ✓ State database migrated"
        else
            echo "  ✗ Migration failed; this client will not be started automatically"
            touch "$client_dir/.openclaw-migration-failed"
        fi

        echo ""
    done

    echo ">>> Starting docker containers..."
    for client in "${stopped_clients[@]}"; do
        client_dir="$CLIENTS_DIR/$client"
        [ -f "$client_dir/docker-compose.yml" ] || continue

        if [ -e "$client_dir/.openclaw-migration-failed" ]; then
            echo "  ! Client '$client' left stopped because its migration failed"
            continue
        fi

        echo "Starting client: $client"
        if (cd "$client_dir" && "${COMPOSE_CMD[@]}" up -d); then
            echo "  ✓ Client '$client' started successfully"
        else
            echo "  ✗ Failed to start client '$client'"
        fi
        echo ""
    done

    cd "$SCRIPT_DIR"
    echo ">>> Batch update completed."
else
    echo "To apply changes, restart each client manually:"
    echo "  cd clients/<client-name> && docker compose up -d"
fi
