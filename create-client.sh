#!/usr/bin/env bash
set -euo pipefail

# Cross-platform compose command detection
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: Neither 'docker-compose' nor 'docker compose' found"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Step 1: Input and validate client name ---
read -rp "Enter client name: " CLIENT_NAME

if [ -z "$CLIENT_NAME" ]; then
    echo "Error: Client name cannot be empty."
    exit 1
fi

# Check for spaces
if [[ "$CLIENT_NAME" =~ [[:space:]] ]]; then
    echo "Error: Client name must not contain spaces."
    exit 1
fi

# Check for diacritics (Vietnamese and other Unicode characters)
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
        cat > "$META_ENV_FILE" << EOF
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

# --- Step 3: Create client directory and copy templates ---
CLIENT_DIR="$SCRIPT_DIR/clients/$CLIENT_NAME"

if [ -d "$CLIENT_DIR" ]; then
    echo "Error: Client directory '$CLIENT_DIR' already exists."
    exit 1
fi

echo ">>> Creating client directory: $CLIENT_DIR"
mkdir -p "$CLIENT_DIR"

echo ">>> Copying templates to $CLIENT_DIR"
cp -R "$SCRIPT_DIR/templates/"* "$CLIENT_DIR/"

# --- Step 4: Update .env file ---
echo ">>> Updating .env file"
ENV_FILE="$CLIENT_DIR/.env"

update_or_append() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

update_or_append "STACK_NAME" "$CLIENT_NAME"
update_or_append "BASE_URL" "$BASE_URL"
update_or_append "API_KEY" "$API_KEY"

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    update_or_append "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
fi

if [ -n "$FACEBOOK_PAGE_ID" ]; then
    update_or_append "FACEBOOK_PAGE_ID" "$FACEBOOK_PAGE_ID"
    update_or_append "FACEBOOK_PAGE_ACCESS_TOKEN" "$FACEBOOK_PAGE_ACCESS_TOKEN"
fi

# --- Step 5: Start services ---
echo ">>> Starting services for client: $CLIENT_NAME"
cd "$CLIENT_DIR"

# Create external network if it doesn't exist
if ! docker network inspect neonx-network >/dev/null 2>&1; then
    echo ">>> Creating external network: neonx-network"
    sudo docker network create neonx-network
fi

STACK_NAME="$CLIENT_NAME" API_KEY="$API_KEY" BASE_URL="$BASE_URL" $COMPOSE_CMD up -d --force-recreate

echo ">>> Done! Client '$CLIENT_NAME' is running."
$COMPOSE_CMD ps
