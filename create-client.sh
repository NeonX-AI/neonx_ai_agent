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

# --- Step 2: Input BASE_URL and API_KEY ---
read -rp "Enter BASE_URL [http://ai_gateway:20128/v1]: " BASE_URL
BASE_URL="${BASE_URL:-http://ai_gateway:20128/v1}"

read -rp "Enter API_KEY: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "Error: API_KEY cannot be empty."
    exit 1
fi

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

# --- Step 5: Start services ---
echo ">>> Starting services for client: $CLIENT_NAME"
cd "$CLIENT_DIR"

STACK_NAME="$CLIENT_NAME" API_KEY="$API_KEY" BASE_URL="$BASE_URL" $COMPOSE_CMD up -d --force-recreate

echo ">>> Done! Client '$CLIENT_NAME' is running."
$COMPOSE_CMD ps
