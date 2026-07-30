#!/bin/sh
# Module: Plugin configuration
# Sets up plugin framework and ensures openclaw-message-listener is enabled

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
PLUGIN_NAME="openclaw-message-listener"
EXTENSIONS_PATH="$CONFIG_PATH/extensions"
TMP=$(mktemp)

# Ensure openclaw-message-listener plugin is in extensions directory
if [ -d "$EXTENSIONS_PATH/openclaw-message-listener" ]; then
    echo "openclaw-message-listener plugin found in extensions directory"
else
    echo "Warning: openclaw-message-listener plugin not found in extensions directory"
fi

if [ -f "$CONFIG" ]; then
    if ! jq -e '.plugins' "$CONFIG" >/dev/null; then
        jq --arg plugin "$PLUGIN_NAME" '
        .plugins |= (. // {}) |
        .plugins.enabled |= (. // true) |
        .plugins.allow |= (. // [$plugin]) |
        .plugins.deny |= (. // []) |
        .plugins.load |= (. // {}) |
        .plugins.load.paths |= (. // []) |
        .plugins.slots |= (. // {}) |
        .plugins.entries |= (. // {}) |
        .plugins.entries[$plugin] |= (. // {enabled: true})
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Created plugins configuration"
    fi

    # Always ensure openclaw-message-listener plugin is enabled and allowed
    jq --arg plugin "$PLUGIN_NAME" --arg path "$EXTENSIONS_PATH/$PLUGIN_NAME" '
    .plugins.entries[$plugin] = {enabled: true} |
    .plugins.load.paths |= (. + [$path] | unique) |
    .plugins.allow |= (. + [$plugin] | unique)
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Ensured openclaw-message-listener plugin is enabled and allowed"
fi
