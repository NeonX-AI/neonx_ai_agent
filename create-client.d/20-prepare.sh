#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/create-client.d/00-common.sh"

CLIENT_DIR="$SCRIPT_DIR/clients/$CLIENT_NAME"

if [ -d "$CLIENT_DIR" ]; then
    echo "Error: Client directory '$CLIENT_DIR' already exists."
    exit 1
fi

echo ">>> Creating client directory: $CLIENT_DIR"
mkdir -p "$CLIENT_DIR"

echo ">>> Copying templates to $CLIENT_DIR"
cp -R "$SCRIPT_DIR/templates/"* "$CLIENT_DIR/"

echo ">>> Updating .env file"
ENV_FILE="$CLIENT_DIR/.env"

update_or_append "$ENV_FILE" "STACK_NAME" "$CLIENT_NAME"
update_or_append "$ENV_FILE" "BASE_URL" "$BASE_URL"
update_or_append "$ENV_FILE" "API_KEY" "$API_KEY"

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    update_or_append "$ENV_FILE" "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
fi

if [ -n "$FACEBOOK_PAGE_ID" ]; then
    update_or_append "$ENV_FILE" "FACEBOOK_PAGE_ID" "$FACEBOOK_PAGE_ID"
    update_or_append "$ENV_FILE" "FACEBOOK_PAGE_ACCESS_TOKEN" "$FACEBOOK_PAGE_ACCESS_TOKEN"
fi

echo ">>> Updating openclaw.json with model: $MODEL_NAME"
OPENCLAW_JSON="$CLIENT_DIR/agent_data/openclaw.json"
if [ -f "$OPENCLAW_JSON" ]; then
    # Provider is hardcoded as "neonx"
    PROVIDER="neonx"
    MODEL_ID="$PROVIDER/$MODEL_NAME"
    
    # Update agents.defaults.model.primary
    jq --arg model "$MODEL_ID" '.agents.defaults.model.primary = $model' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"
    
    # Update agents.defaults.models
    jq --arg model "$MODEL_ID" --arg alias "$MODEL_NAME" '.agents.defaults.models = {($model): {"alias": $alias}}' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"
    
    echo "  ✓ Model configured: $MODEL_NAME"
fi

export CLIENT_DIR ENV_FILE
