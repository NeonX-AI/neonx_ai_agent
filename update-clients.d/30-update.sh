#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

BACKUPS_DIR="$CLIENTS_DIR/backups"

echo ""
echo ">>> Updating clients from templates..."
echo ""

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    echo "Updating client: $client"

    # --- Full directory backup (zip) ---
    backup_dir="$BACKUPS_DIR/$client"
    backup_name="$(date +%Y%m%d-%H%M%S)"
    backup_zip="$backup_dir/$backup_name.zip"

    mkdir -p "$backup_dir"

    # Try zip first, fallback to tar.gz if zip is not available
    if command -v zip >/dev/null 2>&1; then
        if (cd "$client_dir" && zip -r -q "$backup_zip" . -x "backups/*" -x "*/node_modules/*") 2>/dev/null; then
            echo "  ✓ Full backup: $backup_zip"
        else
            echo "  ✗ Failed to create backup, skipping update for safety"
            rm -f "$backup_zip"
            continue
        fi
    else
        # Fallback to tar.gz
        backup_zip="$backup_dir/$backup_name.tar.gz"
        if (cd "$client_dir" && tar -czf "$backup_zip" --exclude='backups' --exclude='*/node_modules' .) 2>/dev/null; then
            echo "  ✓ Full backup: $backup_zip"
        else
            echo "  ✗ Failed to create backup, skipping update for safety"
            rm -f "$backup_zip"
            continue
        fi
    fi

    # Keep only the 10 most recent backups
    ls -dt "$backup_dir"/*.zip 2>/dev/null | tail -n +11 | xargs rm -f

    # --- Update from templates ---
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

        # Copy from templates
        if [ -d "$src" ]; then
            parent_dir=$(dirname "$dst")
            if [ ! -d "$parent_dir" ]; then
                mkdir -p "$parent_dir"
            fi
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --delete --chmod=u+rwX "$src/" "$dst/" 2>/dev/null || {
                    cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
                }
            else
                cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
            fi
            echo "  Updated directory: $item"
        else
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
