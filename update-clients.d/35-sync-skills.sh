#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

SKILLS_DIR="$SCRIPT_DIR/templates/skills"

echo ""
echo ">>> Syncing skills to clients..."
echo ""

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
    echo "  Warning: Skills directory not found: $SKILLS_DIR"
    echo "  Skipping skills sync"
    echo ""
    exit 0
fi

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    agent_data_dir="$client_dir/agent_data"
    skills_dst="$agent_data_dir/skills"
    
    echo "Syncing skills to client: $client"
    
    if [ ! -d "$agent_data_dir" ]; then
        echo "  Warning: Agent data directory not found for client '$client', skipping..."
        continue
    fi
    
    # Create skills directory if it doesn't exist
    mkdir -p "$skills_dst"
    
    # Copy all skills from templates, overwriting existing ones
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete --chmod=u+rwX "$SKILLS_DIR/" "$skills_dst/" 2>/dev/null || \
            cp -Rf "$SKILLS_DIR/"* "$skills_dst/" 2>/dev/null || true
    else
        # Remove existing skills and copy new ones
        rm -rf "$skills_dst"/* 2>/dev/null || true
        cp -Rf "$SKILLS_DIR/"* "$skills_dst/" 2>/dev/null || true
    fi
    
    echo "  ✓ Skills synced to client '$client'"
    echo ""
done

echo ">>> All clients skills synced successfully!"
echo ""
