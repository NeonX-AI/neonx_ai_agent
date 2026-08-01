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

# Update model from MODEL_NAME env var (if set)
if [ -n "${MODEL_NAME:-}" ]; then
    PROVIDER="neonx"
    MODEL_ID="$PROVIDER/$MODEL_NAME"
    TMP=$(mktemp)
    jq --arg model "$MODEL_ID" --arg alias "$MODEL_NAME" \
        '.agents.defaults.model.primary = $model | .agents.defaults.models = {($model): {"alias": $alias}}' \
        "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Updated model to: $MODEL_NAME"
fi
