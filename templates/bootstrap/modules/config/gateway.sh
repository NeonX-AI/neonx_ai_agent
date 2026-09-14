#!/bin/sh
# Module: Gateway configuration
# Sets up gateway mode, bind, and control UI settings

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

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
fi
