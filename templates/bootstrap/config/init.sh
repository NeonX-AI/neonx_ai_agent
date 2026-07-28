#!/bin/sh
# Module: config initialization
# Sets up default config, gateway settings, and plugin framework

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

# Create default config if not exists
if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Creating default config..."
    mkdir -p "$CONFIG_PATH"
    echo '{"gateway":{"mode":"local"}}' > "$CONFIG"
fi

if [ -f "$CONFIG" ]; then
    if ! jq -e '.gateway.mode' "$CONFIG" >/dev/null; then
        jq '.gateway.mode = "local"' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.mode=local"
    fi
    if ! jq -e '.gateway.bind' "$CONFIG" >/dev/null; then
        jq '.gateway.bind = "lan"' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.bind=lan"
    fi
    if ! jq -e '.gateway.controlUi' "$CONFIG" >/dev/null; then
        jq '.gateway.controlUi = {
            "allowedOrigins": ["*"],
            "dangerouslyAllowHostHeaderOriginFallback": true,
            "allowInsecureAuth": true,
            "dangerouslyDisableDeviceAuth": true
        }' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.controlUi configuration"
    fi
    if ! jq -e '.commands.plugins' "$CONFIG" >/dev/null; then
        jq ".commands.plugins = true" "$CONFIG" > /tmp/openclaw.json && mv /tmp/openclaw.json "$CONFIG"
        echo "Created commands configuration"
    fi
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

        # thêm vào nếu chưa có
        .plugins.entries[$plugin] |= (. // {enabled: true})
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Created plugins configuration"
    fi

    # Always ensure openclaw-message-listener plugin is enabled and allowed
    jq --arg plugin "$PLUGIN_NAME" '
    .plugins.entries[$plugin] = {enabled: true} |
    .plugins.allow |= (. + [$plugin] | unique)
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Ensured openclaw-message-listener plugin is enabled and allowed"
fi
