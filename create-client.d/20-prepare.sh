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

# Set MODEL in format provider/model (e.g., qltech/qwen3-coder:30b)
update_or_append "$ENV_FILE" "MODEL" "$PROVIDER_AND_MODEL"

echo ">>> Updating openclaw.json with model: $MODEL_NAME"
OPENCLAW_JSON="$CLIENT_DIR/agent_data/openclaw.json"
if [ -f "$OPENCLAW_JSON" ]; then
    # Use the provider from PROVIDER_AND_MODEL (which could be "neonx/model-name" or "qltech/qwen3-coder:30b")
    MODEL_ID="$PROVIDER_AND_MODEL"
    
    # Extract just the model name part for alias
    MODEL_NAME_PART="${MODEL_ID##*/}"
    
    # Update agents.defaults.model.primary
    jq --arg model "$MODEL_ID" '.agents.defaults.model.primary = $model' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"
    
    # Update agents.defaults.models
    jq --arg model "$MODEL_ID" --arg alias "$MODEL_NAME_PART" '.agents.defaults.models = {($model): {"alias": $alias}}' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"
    
    echo "  ✓ Model configured: $MODEL_NAME"
fi

# Sync skills from templates
SKILLS_DIR="$SCRIPT_DIR/templates/skills"
if [ -d "$SKILLS_DIR" ]; then
    echo ">>> Syncing skills to client"
    mkdir -p "$CLIENT_DIR/agent_data/skills"
    cp -R "$SKILLS_DIR/"* "$CLIENT_DIR/agent_data/skills/" 2>/dev/null || true
    echo "  ✓ Skills synced"
fi

export CLIENT_DIR ENV_FILE
