#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

if [ ! -d "$CLIENTS_DIR" ]; then
    echo "Clients directory not found: $CLIENTS_DIR — skipping update."
    exit 0
fi

# Get list of clients (only directories, skip files like .env.meta and backups/)
CLIENTS=($(find "$CLIENTS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -not -name 'backups' -exec basename {} \;))

if [ ${#CLIENTS[@]} -eq 0 ]; then
    echo "No clients found in $CLIENTS_DIR"
    exit 0
fi

echo "Found ${#CLIENTS[@]} client(s): ${CLIENTS[*]}"
echo ""

# Ask for confirmation
if [ "$AUTO_YES" = true ]; then
    echo "Auto-confirming update (flag -y)"
else
    read -rp "Update all clients from templates? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
fi

# Ask if should restart containers
if [ "$AUTO_YES" = true ]; then
    RESTART_CONTAINERS=true
    echo "Auto-confirming restart containers (flag -y)"
else
    read -rp "Restart docker containers after update? (Y/n) " -n 1 -r
    echo
    if [[ -z $REPLY ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
        RESTART_CONTAINERS=true
    else
        RESTART_CONTAINERS=false
    fi
fi

export CLIENTS RESTART_CONTAINERS
