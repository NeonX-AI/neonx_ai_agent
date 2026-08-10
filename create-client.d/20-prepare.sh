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

# Set API protocol (openai-completions | openai-responses | anthropic-messages)
update_or_append "$ENV_FILE" "API" "$API"

echo ">>> Updating openclaw.json with model: $MODEL_NAME"
OPENCLAW_JSON="$CLIENT_DIR/agent_data/openclaw.json"
if [ -f "$OPENCLAW_JSON" ]; then
    # Use the provider from PROVIDER_AND_MODEL (which could be "neonx/model-name" or "qltech/qwen3-coder:30b")
    MODEL_ID="$PROVIDER_AND_MODEL"

    # Update agents.defaults.model.primary
    jq --arg model "$MODEL_ID" '.agents.defaults.model.primary = $model' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"

    # Update provider API protocol (openai-completions | openai-responses | anthropic-messages)
    PROVIDER_PART="${MODEL_ID%%/*}"
    jq --arg provider "$PROVIDER_PART" --arg api "$API" '.models.providers[$provider].api = $api' "$OPENCLAW_JSON" > "$OPENCLAW_JSON.tmp" && mv "$OPENCLAW_JSON.tmp" "$OPENCLAW_JSON"

    echo "  ✓ Model configured: $MODEL_NAME (api: $API)"
fi

# Sync skills to the client.
# Sources:
#   1. extensions/text-to-cad/skills — text-to-cad skill library (earthtojake/text-to-cad)
#   2. templates/skills — extra standalone skills (e.g. autodesk-fusion)
TTC_SKILLS_DIR="$SCRIPT_DIR/extensions/text-to-cad/skills"
EXTRA_SKILLS_DIR="$SCRIPT_DIR/templates/skills"
if [ -d "$TTC_SKILLS_DIR" ] || [ -d "$EXTRA_SKILLS_DIR" ]; then
    echo ">>> Syncing skills to client"
    mkdir -p "$CLIENT_DIR/agent_data/skills"
    for src_dir in "$TTC_SKILLS_DIR" "$EXTRA_SKILLS_DIR"; do
        [ -d "$src_dir" ] || continue
        for d in "$src_dir"/*/; do
            [ -d "$d" ] || continue
            name="$(basename "$d")"
            rm -rf "$CLIENT_DIR/agent_data/skills/$name"
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --chmod=u+rwX "$src_dir/$name/" "$CLIENT_DIR/agent_data/skills/$name/"
            else
                cp -R "$src_dir/$name" "$CLIENT_DIR/agent_data/skills/$name"
            fi
        done
    done
    echo "  ✓ Skills synced"
fi

export CLIENT_DIR ENV_FILE
