#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENTS_DIR="$SCRIPT_DIR/clients"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Files/directories to update from templates
UPDATE_ITEMS=(
    "entrypoint.sh"
    "docker-compose.yml"
    "openclaw-message-listener"
)

# Files/directories to NEVER update (user-specific data)
EXCLUDE_ITEMS=(
    "agent_data"
    ".env"
)

if [ ! -d "$CLIENTS_DIR" ]; then
    echo "Error: Clients directory not found: $CLIENTS_DIR"
    exit 1
fi

# Get list of clients
CLIENTS=($(find "$CLIENTS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

if [ ${#CLIENTS[@]} -eq 0 ]; then
    echo "No clients found in $CLIENTS_DIR"
    exit 0
fi

echo "Found ${#CLIENTS[@]} client(s): ${CLIENTS[*]}"
echo ""

# Ask for confirmation
read -rp "Update all clients from templates? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

# Ask if should restart containers
read -rp "Restart docker containers after update? (Y/n) " -n 1 -r
echo
if [[ -z $REPLY ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
    RESTART_CONTAINERS=true
else
    RESTART_CONTAINERS=false
fi

echo ""
echo ">>> Updating clients from templates..."
echo ""

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    echo "Updating client: $client"
    
    for item in "${UPDATE_ITEMS[@]}"; do
        # Skip excluded items (user-specific data)
        for excluded in "${EXCLUDE_ITEMS[@]}"; do
            if [ "$item" = "$excluded" ]; then
                echo "  Skipped: $item (user data)"
                continue 2
            fi
        done
        
        src="$TEMPLATES_DIR/$item"
        dst="$client_dir/$item"
        
        if [ ! -e "$src" ]; then
            echo "  Warning: Source not found: $item"
            continue
        fi
        
        # Backup existing file if it exists
        if [ -e "$dst" ]; then
            backup="$dst.backup-$(date +%Y%m%d-%H%M%S)"
            cp -R "$dst" "$backup"
            echo "  Backed up: $item -> $(basename "$backup")"
            
            # Keep only the 5 most recent backups
            if [ -d "$dst" ]; then
                ls -dt "$dst".backup-* 2>/dev/null | tail -n +6 | xargs rm -rf
            else
                ls -dt "$dst".backup-* 2>/dev/null | tail -n +6 | xargs rm -f
            fi
        fi
        
        # Copy from templates
        if [ -d "$src" ]; then
            # It's a directory
            rm -rf "$dst"
            cp -R "$src" "$dst"
            echo "  Updated directory: $item"
        else
            # It's a file
            cp "$src" "$dst"
            echo "  Updated file: $item"
        fi
    done
    
    echo "  ✓ Client '$client' updated"
    echo ""
done

echo ">>> All clients updated successfully!"
echo ""

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
        if docker compose down && docker compose up -d; then
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
