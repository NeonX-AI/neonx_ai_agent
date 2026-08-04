#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/create-client.d/00-common.sh"

# --- Step 1: Input and validate client name ---
read -rp "Enter client name: " CLIENT_NAME

if [ -z "$CLIENT_NAME" ]; then
    echo "Error: Client name cannot be empty."
    exit 1
fi

if [[ "$CLIENT_NAME" =~ [[:space:]] ]]; then
    echo "Error: Client name must not contain spaces."
    exit 1
fi

if [[ "$CLIENT_NAME" =~ [^a-zA-Z0-9._-] ]]; then
    echo "Error: Client name must not contain special characters or diacritics."
    echo "       Only alphanumeric characters (a-z, A-Z, 0-9), dots (.), hyphens (-), and underscores (_) are allowed."
    exit 1
fi

echo "Client name: $CLIENT_NAME"

# --- Step 2: Input BASE_URL, API_KEY and TELEGRAM_BOT_TOKEN ---
read -rp "Enter BASE_URL [http://ai_gateway:20128/v1]: " BASE_URL
BASE_URL="${BASE_URL:-http://ai_gateway:20128/v1}"

read -rp "Enter API_KEY: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "Error: API_KEY cannot be empty."
    exit 1
fi

read -rp "Enter TELEGRAM_BOT_TOKEN (leave empty to skip): " TELEGRAM_BOT_TOKEN

# Check if Meta App credentials exist
META_ENV_FILE="$SCRIPT_DIR/.env.meta"
if [ -f "$META_ENV_FILE" ]; then
    echo "Using existing Meta Platform credentials from .env.meta"
    source "$META_ENV_FILE"
    FACEBOOK_APP_SECRET="${FACEBOOK_APP_SECRET:-}"
    FACEBOOK_VERIFY_TOKEN="${FACEBOOK_VERIFY_TOKEN:-}"
else
    echo "Meta Platform credentials not found. Creating .env.meta..."
    read -rp "Enter FACEBOOK_APP_SECRET (Meta App secret): " FACEBOOK_APP_SECRET
    read -rp "Enter FACEBOOK_VERIFY_TOKEN (webhook verify token): " FACEBOOK_VERIFY_TOKEN

    if [ -n "$FACEBOOK_APP_SECRET" ] || [ -n "$FACEBOOK_VERIFY_TOKEN" ]; then
        cat > "$META_ENV_FILE" <<EOF
# Meta Platform (Facebook) App Credentials
# Shared across all clients
FACEBOOK_APP_SECRET=${FACEBOOK_APP_SECRET}
FACEBOOK_VERIFY_TOKEN=${FACEBOOK_VERIFY_TOKEN}
EOF
        echo "Created .env.meta with Meta Platform credentials"
    fi
fi

read -rp "Enter FACEBOOK_PAGE_ID (leave empty to skip): " FACEBOOK_PAGE_ID
read -rp "Enter FACEBOOK_PAGE_ACCESS_TOKEN (leave empty to skip): " FACEBOOK_PAGE_ACCESS_TOKEN

read -rp "Enter MODEL_NAME [neonx/neonx-3.0-coder]: " MODEL_NAME
MODEL_NAME="${MODEL_NAME:-neonx/neonx-3.0-coder}"

# Check if the model name contains a provider (has a slash)
if [[ "$MODEL_NAME" == */* ]]; then
    # Model name already includes provider, use it as-is
    PROVIDER_AND_MODEL="$MODEL_NAME"
    echo "Using specified provider/model: $PROVIDER_AND_MODEL"
else
    # No provider specified, ask user for provider or use default
    read -rp "Enter PROVIDER [neonx]: " PROVIDER
    PROVIDER="${PROVIDER:-neonx}"
    PROVIDER_AND_MODEL="$PROVIDER/$MODEL_NAME"
    echo "Using provider/model: $PROVIDER_AND_MODEL"
fi

export CLIENT_NAME BASE_URL API_KEY TELEGRAM_BOT_TOKEN FACEBOOK_APP_SECRET FACEBOOK_VERIFY_TOKEN FACEBOOK_PAGE_ID FACEBOOK_PAGE_ACCESS_TOKEN MODEL_NAME PROVIDER_AND_MODEL
