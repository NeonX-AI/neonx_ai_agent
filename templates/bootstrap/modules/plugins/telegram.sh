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
    .channels |= (. // {}) |
    .channels.telegram |= (. // {}) |
    .channels.telegram.accounts |= (. // {}) |
    .channels.telegram.accounts.default |= (. // {}) |
    if .channels.telegram.accounts.default.dmPolicy == null then
        .channels.telegram.accounts.default.dmPolicy = "open" |
        .channels.telegram.accounts.default.allowFrom = ["*"]
    else
        .
    end
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Enabled Telegram plugin (existing dmPolicy is preserved; default is open)"
fi
