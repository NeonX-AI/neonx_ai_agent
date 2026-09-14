#!/bin/sh
# Module: Telegram plugin setup
# Enables Telegram plugin if TELEGRAM_BOT_TOKEN is provided

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    jq '
    .plugins.allow |= (. + ["telegram"] | unique) |
    .plugins.entries.telegram = {enabled: true} |
    .channels.telegram.accounts.default.dmPolicy = "open" |
    .channels.telegram.accounts.default.allowFrom = ["*"]
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Enabled Telegram plugin with open DM policy"
fi
