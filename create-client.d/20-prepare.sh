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

export CLIENT_DIR ENV_FILE
