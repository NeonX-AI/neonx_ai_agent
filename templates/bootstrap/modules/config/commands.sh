#!/bin/sh
# Module: Commands configuration
# Enables plugin commands

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

if [ -f "$CONFIG" ]; then
    if ! jq -e '.commands.plugins' "$CONFIG" >/dev/null; then
        jq ".commands.plugins = true" "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Created commands configuration"
    fi
fi
