#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENTS_DIR="$SCRIPT_DIR/clients"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Parse arguments
AUTO_YES=false
for arg in "$@"; do
    case $arg in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
    esac
done

# Files/directories to update from templates
UPDATE_ITEMS=(
    "entrypoint.sh"
    "docker-compose.yml"
    ".env.meta"
    "agent_data/extensions/facebook"
    "agent_data/extensions/openclaw-message-listener"
)

# Files/directories to NEVER update (user-specific data)
EXCLUDE_ITEMS=(
    "agent_data"
    ".env"
)

if [ ! -d "$CLIENTS_DIR" ]; then
    echo "Clients directory not found: $CLIENTS_DIR — skipping update."
    exit 0
fi

# Get list of clients (only directories, skip files like .env.meta)
CLIENTS=($(find "$CLIENTS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -exec basename {} \;))

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

# Ensure Facebook plugin dist/ directory is restored from git (macOS filesystem issue)
FACEBOOK_DIST_DIR="$TEMPLATES_DIR/agent_data/extensions/facebook/dist"
if [ ! -d "$FACEBOOK_DIST_DIR" ] || [ -z "$(ls -A "$FACEBOOK_DIST_DIR" 2>/dev/null)" ]; then
    echo ">>> Restoring Facebook plugin dist/ from git..."
    mkdir -p "$FACEBOOK_DIST_DIR"
    if git archive HEAD:templates/agent_data/extensions/facebook/dist 2>/dev/null | tar -x -C "$FACEBOOK_DIST_DIR" 2>/dev/null; then
        echo "  ✓ Facebook plugin dist/ restored ($(find "$FACEBOOK_DIST_DIR" -type f | wc -l) files)"
    else
        echo "  ✗ Failed to restore Facebook plugin dist/ from git"
    fi
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
            if cp -R "$dst" "$backup" 2>/dev/null; then
                echo "  Backed up: $item -> $(basename "$backup")"
                
                # Keep only the 5 most recent backups
                if [ -d "$dst" ]; then
                    ls -dt "$dst".backup-* 2>/dev/null | tail -n +6 | xargs rm -rf
                else
                    ls -dt "$dst".backup-* 2>/dev/null | tail -n +6 | xargs rm -f
                fi
            else
                echo "  Warning: Cannot backup $item (permission denied), skipping backup"
            fi
        fi
        
        # Copy from templates
        if [ -d "$src" ]; then
            # It's a directory
            # Create parent directory if it doesn't exist
            parent_dir=$(dirname "$dst")
            if [ ! -d "$parent_dir" ]; then
                mkdir -p "$parent_dir"
            fi
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
        if sudo docker compose down && sudo docker compose up -d; then
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
