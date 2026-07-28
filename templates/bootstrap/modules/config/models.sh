#!/bin/sh
# Module: models configuration
# Updates BASE_URL and API_KEY from environment variables

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)

if [ -n "${BASE_URL:-}" ]; then
    jq --arg baseUrl "$BASE_URL" '.models.providers.neonx.baseUrl = $baseUrl' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Updated models.providers.neonx.baseUrl from BASE_URL"
fi

if [ -n "${API_KEY:-}" ]; then
    jq --arg apiKey "$API_KEY" '.models.providers.neonx.apiKey = $apiKey' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Updated models.providers.neonx.apiKey from API_KEY"
fi
