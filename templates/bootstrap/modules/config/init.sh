#!/bin/sh
# Module: config initialization
# Orchestrates loading of config sub-modules

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"

# Create default config if not exists
if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Creating default config..."
    mkdir -p "$CONFIG_PATH"
    echo '{"gateway":{"mode":"local"}}' > "$CONFIG"
fi

# Load sub-modules
CONFIG_SCRIPT_DIR="$SCRIPT_DIR/modules/config"

. "$CONFIG_SCRIPT_DIR/gateway.sh"
. "$CONFIG_SCRIPT_DIR/plugins.sh"
. "$CONFIG_SCRIPT_DIR/commands.sh"
# . "$CONFIG_SCRIPT_DIR/security.sh"

# Set session.dmScope to per-channel-peer (each sender on each channel gets own session)
if [ -f "$CONFIG" ]; then
    TMP=$(mktemp)
    if ! jq -e '.agents.defaults.session.dmScope' "$CONFIG" >/dev/null 2>&1; then
        jq '.agents.defaults.session.dmScope = "per-channel-peer"' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set agents.defaults.session.dmScope=per-channel-peer"
    fi
fi
