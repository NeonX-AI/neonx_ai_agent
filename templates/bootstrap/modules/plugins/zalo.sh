#!/bin/sh
# Module: Zalo plugins setup
# Installs openzca npm library and Zalo plugins

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

# Install openzca npm package globally
echo "Installing openzca npm package..."
if command -v npm >/dev/null 2>&1; then
    npm install -g openzca 2>&1 || echo "Warning: Failed to install openzca globally"
else
    echo "Warning: npm not found, cannot install openzca"
fi

# Check if openzca is installed
if command -v openzca >/dev/null 2>&1; then
    echo "✓ openzca installed successfully"
    openzca --version 2>&1 || true
else
    echo "✗ openzca not found in PATH"
fi

# Install Zalo plugins
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
