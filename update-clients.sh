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
    "openclaw-message-listener"
    ".env.meta"
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

# Merge Meta credentials into each client's openclaw.json
echo ">>> Merging Meta credentials into client configs..."

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    config_file="$client_dir/agent_data/openclaw.json"
    client_env_file="$client_dir/.env"
    client_meta_file="$client_dir/.env.meta"
    
    if [ -f "$config_file" ] && [ -f "$client_env_file" ] && [ -f "$client_meta_file" ]; then
        # Read Meta credentials from client's .env.meta
        FACEBOOK_APP_SECRET=$(grep "^FACEBOOK_APP_SECRET=" "$client_meta_file" | cut -d'=' -f2-)
        FACEBOOK_VERIFY_TOKEN=$(grep "^FACEBOOK_VERIFY_TOKEN=" "$client_meta_file" | cut -d'=' -f2-)
        
        if [ -n "$FACEBOOK_APP_SECRET" ] || [ -n "$FACEBOOK_VERIFY_TOKEN" ]; then
            # Check if client has Facebook credentials
            FACEBOOK_PAGE_ID=$(grep "^FACEBOOK_PAGE_ID=" "$client_env_file" 2>/dev/null | cut -d'=' -f2-)
            FACEBOOK_PAGE_ACCESS_TOKEN=$(grep "^FACEBOOK_PAGE_ACCESS_TOKEN=" "$client_env_file" 2>/dev/null | cut -d'=' -f2-)
            
            if [ -n "$FACEBOOK_PAGE_ID" ] && [ -n "$FACEBOOK_PAGE_ACCESS_TOKEN" ]; then
                # Backup config
                cp "$config_file" "$config_file.backup-$(date +%Y%m%d-%H%M%S)"
                
                # Create or update Facebook channel config with all credentials
                if command -v jq >/dev/null 2>&1; then
                    jq --arg pageId "$FACEBOOK_PAGE_ID" \
                       --arg pageAccessToken "$FACEBOOK_PAGE_ACCESS_TOKEN" \
                       --arg appSecret "$FACEBOOK_APP_SECRET" \
                       --arg verifyToken "$FACEBOOK_VERIFY_TOKEN" \
                       '.channels.facebook = {
                           enabled: true,
                           pageId: $pageId,
                           pageAccessToken: $pageAccessToken,
                           appSecret: $appSecret,
                           verifyToken: $verifyToken,
                           dmPolicy: "open",
                           allowFrom: ["*"]
                       }' \
                       "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
                    echo "  ✓ Configured Facebook channel for: $client"
                else
                    echo "  ⚠ jq not found, skipping credential merge for: $client"
                fi
            else
                echo "  ⚠ No Facebook credentials found for: $client"
            fi
        else
            echo "  ⚠ No Meta credentials found in $client/.env.meta"
        fi
    else
        echo "  ⚠ Missing required files for: $client"
    fi
done

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
