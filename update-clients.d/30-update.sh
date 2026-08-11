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

    # --- Backup: update items + important runtime data (agent_data, .env) ---
    # agent_data holds config, identity, state and skills, so it must be backed
    # up. We skip only the heavy, regenerable parts (logs, npm cache, media,
    # the separately-mounted projects dir, attestations, node_modules).
    backup_dir="$BACKUPS_DIR/$client"
    backup_name="$(date +%Y%m%d-%H%M%S)"
    backup_zip="$backup_dir/$backup_name.zip"

    mkdir -p "$backup_dir"

    # Items that get overwritten by the update
    backup_targets=()
    for item in "${UPDATE_ITEMS[@]}"; do
        skip=false
        for excluded in "${EXCLUDE_ITEMS[@]}"; do
            if [ "$item" = "$excluded" ]; then
                skip=true
                break
            fi
        done
        if [ "$skip" = false ] && [ -e "$client_dir/$item" ]; then
            backup_targets+=("$item")
        fi
    done

    # Important user data (not overwritten by the update, but must be backed up)
    for item in agent_data .env; do
        if [ -e "$client_dir/$item" ]; then
            backup_targets+=("$item")
        fi
    done

    # Heavy / regenerable paths to skip inside the archive
    backup_excludes=(
        "*/node_modules/*"
        "agent_data/logs/*"
        "agent_data/npm/*"
        "agent_data/media/*"
        "agent_data/projects/*"
        "agent_data/workspace-attestations/*"
    )

    if [ "${#backup_targets[@]}" -eq 0 ]; then
        echo "  Nothing to back up for '$client'"
    # Try zip first, fallback to tar.gz if zip is not available
    elif command -v zip >/dev/null 2>&1; then
        zip_excludes=()
        for ex in "${backup_excludes[@]}"; do
            zip_excludes+=(-x "$ex")
        done
        if (cd "$client_dir" && zip -r -q "$backup_zip" "${backup_targets[@]}" "${zip_excludes[@]}") 2>/dev/null; then
            echo "  ✓ Backup (${#backup_targets[@]} item(s)): $backup_zip"
        else
            echo "  ✗ Failed to create backup, skipping update for safety"
            rm -f "$backup_zip"
            continue
        fi
    else
        # Fallback to tar.gz
        backup_zip="$backup_dir/$backup_name.tar.gz"
        tar_excludes=()
        for ex in "${backup_excludes[@]}"; do
            tar_excludes+=(--exclude="$ex")
        done
        if (cd "$client_dir" && tar -czf "$backup_zip" "${tar_excludes[@]}" "${backup_targets[@]}") 2>/dev/null; then
            echo "  ✓ Backup (${#backup_targets[@]} item(s)): $backup_zip"
        else
            echo "  ✗ Failed to create backup, skipping update for safety"
            rm -f "$backup_zip"
            continue
        fi
    fi

    # Keep only the 10 most recent backups (both .zip and .tar.gz)
    ls -dt "$backup_dir"/*.zip "$backup_dir"/*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f 2>/dev/null || true

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
                    rm -rf "$dst" 2>/dev/null || true
                    cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
                }
            else
                rm -rf "$dst" 2>/dev/null || true
                cp -Rf "$src" "$dst" 2>/dev/null || cp -R "$src" "$dst"
            fi
            echo "  Updated directory: $item"
        else
            # Create parent directory if it doesn't exist
            parent_dir=$(dirname "$dst")
            if [ ! -d "$parent_dir" ]; then
                mkdir -p "$parent_dir"
            fi
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
