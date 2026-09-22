#!/bin/sh
# Module: Zalo plugin recovery and setup
#
# OpenClaw extensions live in the persistent OpenClaw home, but `openzca` is
# installed globally in the container image. A base-image upgrade therefore
# removes it. Only run this module for clients that were already configured for
# Zalo so updating other clients does not add Zalo unexpectedly.

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
EXTENSIONS_PATH="$CONFIG_PATH/extensions"

has_existing_zalo_setup() {
    if [ -d "$EXTENSIONS_PATH/zalo" ] || [ -d "$EXTENSIONS_PATH/zalouser" ]; then
        return 0
    fi

    [ -f "$CONFIG" ] || return 1
    jq -e '
        (.plugins.entries.zalo? != null) or
        (.plugins.entries.zalouser? != null) or
        ((.plugins.allow? // []) | index("zalo") != null) or
        ((.plugins.allow? // []) | index("zalouser") != null) or
        (.channels.zalo? != null) or
        (.channels.zalouser? != null)
    ' "$CONFIG" >/dev/null 2>&1
}

if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found, cannot check for existing Zalo setup"
    return 0
fi

if ! has_existing_zalo_setup; then
    echo "No existing Zalo setup found; skipping Zalo recovery"
    return 0
fi

# `openzca` is not in the mounted OpenClaw home. Restore it after a base-image
# replacement, but do not reinstall it on images that already provide it.
if command -v openzca >/dev/null 2>&1; then
    echo "openzca is already available"
else
    echo "Restoring openzca npm package..."
    if command -v npm >/dev/null 2>&1; then
        npm install -g openzca 2>&1 || echo "Warning: Failed to install openzca globally"
    else
        echo "Warning: npm not found, cannot restore openzca"
    fi
fi

# Ensure the persisted Zalo plugin entries remain enabled. Plugin files are
# preserved in agent_data; if either is absent, OpenClaw installs it again.
ZALO_PLUGINS="@openclaw/zalo @openclaw/zalouser"
for plugin in $ZALO_PLUGINS; do
    plugin_id=$(echo "$plugin" | sed 's/@openclaw\///')

    if [ ! -d "$EXTENSIONS_PATH/$plugin_id" ]; then
        echo "Restoring plugin: $plugin"
        if command -v openclaw >/dev/null 2>&1; then
            openclaw plugins install "$plugin" || echo "Warning: Failed to install $plugin"
        fi
    fi

    TMP=$(mktemp)
    jq --arg pid "$plugin_id" '
        .plugins.allow |= (. + [$pid] | unique) |
        .plugins.entries[$pid] = ((.plugins.entries[$pid] // {}) + {enabled: true})
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Ensured plugin is enabled: $plugin_id"
done
