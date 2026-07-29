#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

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
            # Use rsync to sync directory (handles permission issues better)
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --delete --chmod=u+rwX "$src/" "$dst/" 2>/dev/null || {
                    # Fallback to cp if rsync fails
                    cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
                }
            else
                # Fallback to cp with force
                cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
            fi
            echo "  Updated directory: $item"
        else
            # It's a file
            # Remove existing file first to avoid permission issues
            if [ -e "$dst" ]; then
                rm -f "$dst" 2>/dev/null || true
            fi
            cp "$src" "$dst"
            echo "  Updated file: $item"
        fi
    done
    
    echo "  ✓ Client '$client' updated"
    echo ""
done

echo ">>> All clients updated successfully!"
echo ""
