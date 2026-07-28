#!/bin/sh
# Module: Zalo plugins setup
# Installs and enables Zalo plugins

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

ZALO_PLUGINS="@openclaw/zalo @openclaw/zalouser"
for plugin in $ZALO_PLUGINS; do
    plugin_id=$(echo "$plugin" | sed 's/@openclaw\///')
    
    # Check if plugin is already enabled
    if ! jq -e ".plugins.entries.\"$plugin_id\".enabled == true" "$CONFIG" >/dev/null 2>&1; then
        echo "Installing plugin: $plugin"
        if command -v openclaw >/dev/null 2>&1; then
            openclaw plugins install "$plugin" || echo "Warning: Failed to install $plugin"
        fi
        
        # Enable plugin in config
        jq --arg pid "$plugin_id" '
        .plugins.allow |= (. + [$pid] | unique) |
        .plugins.entries[$pid] = {enabled: true}
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Enabled plugin: $plugin_id"
    else
        echo "Plugin already enabled: $plugin_id"
    fi
done
