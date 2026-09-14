#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

# Skill sources (mirrored into each client's agent_data/skills/):
#   1. templates/skills/text-to-cad/skills — the text-to-cad skill library
#   2. templates/skills — standalone skills that contain a direct SKILL.md
TTC_SKILLS_DIR="$SCRIPT_DIR/templates/skills/text-to-cad/skills"
EXTRA_SKILLS_DIR="$SCRIPT_DIR/templates/skills"

echo ""
echo ">>> Syncing skills to clients..."
echo ""

if [ ! -d "$TTC_SKILLS_DIR" ] && [ ! -d "$EXTRA_SKILLS_DIR" ]; then
    echo "  Warning: No skill sources found:"
    echo "    - $TTC_SKILLS_DIR"
    echo "    - $EXTRA_SKILLS_DIR"
    echo "  Skipping skills sync"
    echo ""
    exit 0
fi

sync_skill() {
    local src="$1" dst="$2" name="$3"
    rm -rf "$dst/$name"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --chmod=u+rwX "$src/$name/" "$dst/$name/"
    else
        cp -R "$src/$name" "$dst/$name"
    fi
}

for client in "${CLIENTS[@]}"; do
    client_dir="$CLIENTS_DIR/$client"
    agent_data_dir="$client_dir/agent_data"
    skills_dst="$agent_data_dir/skills"

    echo "Syncing skills to client: $client"

    if [ ! -d "$agent_data_dir" ]; then
        echo "  Warning: Agent data directory not found for client '$client', skipping..."
        continue
    fi

    mkdir -p "$skills_dst"

    # Remove the legacy full text-to-cad repo clone (with .git, ~130MB).
    # Skills are synced individually from templates/skills/text-to-cad/skills.
    if [ -d "$skills_dst/text-to-cad" ]; then
        echo "  Removing legacy text-to-cad repo clone..."
        rm -rf "$skills_dst/text-to-cad"
    fi

    # Mirror semantics: drop client skills that no longer exist in any source
    for d in "$skills_dst"/*/; do
        [ -d "$d" ] || continue
        name="$(basename "$d")"
        if [ ! -d "$TTC_SKILLS_DIR/$name" ] && [ ! -d "$EXTRA_SKILLS_DIR/$name" ]; then
            echo "  Removing stale skill: $name"
            rm -rf "$skills_dst/$name"
        fi
    done

    synced=0
    if [ -d "$TTC_SKILLS_DIR" ]; then
        for d in "$TTC_SKILLS_DIR"/*/; do
            [ -d "$d" ] || continue
            [ -f "$d/SKILL.md" ] || continue
            name="$(basename "$d")"
            sync_skill "$TTC_SKILLS_DIR" "$skills_dst" "$name"
            synced=$((synced + 1))
        done
    fi
    if [ -d "$EXTRA_SKILLS_DIR" ]; then
        for d in "$EXTRA_SKILLS_DIR"/*/; do
            [ -d "$d" ] || continue
            [ -f "$d/SKILL.md" ] || continue
            name="$(basename "$d")"
            sync_skill "$EXTRA_SKILLS_DIR" "$skills_dst" "$name"
            synced=$((synced + 1))
        done
    fi

    echo "  ✓ Synced $synced skills to client '$client'"
    echo ""
done

echo ">>> All clients skills synced successfully!"
echo ""
