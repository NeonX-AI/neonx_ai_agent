#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

WORKSPACE_SRC="$SCRIPT_DIR/templates/agent_data/workspace"

echo ""
echo ">>> Syncing workspace files to clients..."
echo ""

# Check if workspace source exists
if [ ! -d "$WORKSPACE_SRC" ]; then
    echo "  Warning: Workspace source directory not found: $WORKSPACE_SRC"
    echo "  Skipping workspace sync"
    echo ""
    exit 0
fi

# Files to sync (only files that should be updated, not user-customized files)
WORKSPACE_FILES=(
    "KNOWLEDGE.md"
)

# Files to copy only if they don't exist (preserve user customizations)
WORKSPACE_FILES_IF_NOT_EXISTS=(
    "AGENTS.md"
)

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    workspace_dst="$client_dir/agent_data/workspace"
    
    echo "Syncing workspace to client: $client"
    
    if [ ! -d "$client_dir" ]; then
        echo "  Warning: Client directory not found, skipping..."
        continue
    fi
    
    # Create workspace directory if it doesn't exist
    mkdir -p "$workspace_dst"
    
    # Sync specific workspace files (always overwrite)
    for file in "${WORKSPACE_FILES[@]}"; do
        src_file="$WORKSPACE_SRC/$file"
        dst_file="$workspace_dst/$file"
        
        if [ -f "$src_file" ]; then
            cp "$src_file" "$dst_file"
            echo "  ✓ Synced: $file"
        else
            echo "  ! Warning: Source file not found: $file"
        fi
    done
    
    # Copy files only if they don't exist (preserve user customizations)
    for file in "${WORKSPACE_FILES_IF_NOT_EXISTS[@]}"; do
        src_file="$WORKSPACE_SRC/$file"
        dst_file="$workspace_dst/$file"
        
        if [ -f "$src_file" ]; then
            if [ ! -f "$dst_file" ]; then
                cp "$src_file" "$dst_file"
                echo "  ✓ Created: $file (new)"
            else
                echo "  ⚠ Skipped: $file (already exists, preserving user customizations)"
            fi
        else
            echo "  ! Warning: Source file not found: $file"
        fi
    done
    
    echo ""
done

echo ">>> All clients workspace synced successfully!"
echo ""
