#!/bin/sh
# Module: semantic-memory configuration
#
# OpenClaw's default semantic recall provider is OpenAI. Our clients normally
# use the NeonX model provider instead, so leave semantic recall disabled
# unless it is explicitly requested and a real OPENAI_API_KEY is available.

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
MEMORY_SEARCH_VALUE=$(printf '%s' "${MEMORY_SEARCH_ENABLED:-false}" | tr '[:upper:]' '[:lower:]')

case "$MEMORY_SEARCH_VALUE" in
    true|1|yes|on)
        if [ -n "${OPENAI_API_KEY:-}" ]; then
            enabled=true
        else
            enabled=false
            echo "memory: MEMORY_SEARCH_ENABLED requested but OPENAI_API_KEY is missing; semantic recall disabled"
        fi
        ;;
    *)
        enabled=false
        ;;
esac

if [ -f "$CONFIG" ]; then
    TMP=$(mktemp)
    jq --argjson enabled "$enabled" '
    .memory |= (. // {}) |
    .memory.search |= (. // {}) |
    .memory.search.enabled = $enabled
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"

    if [ "$enabled" = true ]; then
        echo "memory: semantic recall enabled (OpenAI)"
    else
        echo "memory: semantic recall disabled"
    fi
fi
