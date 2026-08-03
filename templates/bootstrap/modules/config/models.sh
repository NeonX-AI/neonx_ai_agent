#!/bin/sh
# Module: models configuration
# Updates model from MODEL environment variable

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"

# Check if MODEL env var exists
if [ -n "${MODEL:-}" ]; then
    case "$MODEL" in
        */*)
            # Split MODEL into PROVIDER and MODEL_NAME
            PROVIDER="${MODEL%%/*}"
            MODEL_NAME="${MODEL#*/}"
            ;;
        *)
            # Fallback to default provider when only model name is given
            PROVIDER="${MODEL_PROVIDER:-neonx}"
            MODEL_NAME="$MODEL"
            MODEL="$PROVIDER/$MODEL_NAME"
            ;;
    esac

    echo "Updating model from env: $MODEL (provider: $PROVIDER, model: $MODEL_NAME)"

    TMP=$(mktemp)

    # Update openclaw.json
    jq --arg provider "$PROVIDER" \
       --arg modelId "$MODEL" \
       --arg modelName "$MODEL_NAME" \
       --arg baseUrl "${BASE_URL:-http://ai_gateway:20128/v1}" \
       --arg apiKey "${API_KEY:-}" \
       '
       .agents.defaults.model.primary = $modelId |
       .agents.defaults.models = {($modelId): {"alias": $modelName}} |
       .models.providers[$provider].baseUrl = $baseUrl |
       .models.providers[$provider].apiKey = $apiKey |
       .models.providers[$provider].models = [{
           "id": $modelName,
           "name": ($modelName + " (Custom Provider)"),
           "contextWindow": 128000,
           "maxTokens": 4096,
           "input": ["text", "image"],
           "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
           "reasoning": false
       }]
       ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"

    echo "Model updated successfully"
fi
