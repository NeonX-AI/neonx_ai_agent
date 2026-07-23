# !/bin/sh

if ! command -v nano >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "nano not found. Installing nano..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y nano
    else
        echo "nano not found and apt-get is unavailable."
    fi
fi

if ! command -v jq >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "jq not found. Installing jq..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y jq
    elif command -v apk >/dev/null 2>&1; then
        echo "jq not found. Installing jq..."
        apk add --no-cache jq
    else
        echo "jq not available and package manager not recognized. Skipping automatic plugin configuration"
        JQ_AVAILABLE=false
    fi
else
    JQ_AVAILABLE=true
fi

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
# OPENCLAW_MESSAGE_LISTENER_PATH="/app/extensions/openclaw-message-listener"
PLUGIN_NAME="openclaw-message-listener"

TMP=$(mktemp)

# Create default config if not exists
if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Creating default config..."
    mkdir -p "$CONFIG_PATH"
    echo '{"gateway":{"mode":"local"}}' > "$CONFIG"
fi

if [ -f "$CONFIG" ]; then
    if ! jq -e '.gateway.mode' "$CONFIG" >/dev/null; then
        jq '.gateway.mode = "local"' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.mode=local"
    fi
    if ! jq -e '.gateway.bind' "$CONFIG" >/dev/null; then
        jq '.gateway.bind = "lan"' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.bind=lan"
    fi
    if ! jq -e '.gateway.controlUi' "$CONFIG" >/dev/null; then
        jq '.gateway.controlUi = {
            "allowedOrigins": ["*"],
            "dangerouslyAllowHostHeaderOriginFallback": true,
            "allowInsecureAuth": true,
            "dangerouslyDisableDeviceAuth": true
        }' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Set gateway.controlUi configuration"
    fi
    if ! jq -e '.commands.plugins' "$CONFIG" >/dev/null; then
        jq ".commands.plugins = true" "$CONFIG" > /tmp/openclaw.json && mv /tmp/openclaw.json "$CONFIG"
        echo "Created commands configuration"
    fi
    if ! jq -e '.plugins' "$CONFIG" >/dev/null; then
        jq --arg plugin "$PLUGIN_NAME" '
        .plugins |= (. // {}) |
        .plugins.enabled |= (. // true) |
        .plugins.allow |= (. // [$plugin]) |
        .plugins.deny |= (. // []) |
        .plugins.load |= (. // {}) |
        .plugins.load.paths |= (. // []) |
        .plugins.slots |= (. // {}) |
        .plugins.entries |= (. // {}) |

        # thêm vào nếu chưa có
        .plugins.entries[$plugin] |= (. // {enabled: true})
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Created plugins configuration"
    fi

    # Always ensure openclaw-message-listener plugin is enabled and allowed
    jq --arg plugin "$PLUGIN_NAME" '
    .plugins.entries[$plugin] = {enabled: true} |
    .plugins.allow |= (. + [$plugin] | unique)
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Ensured openclaw-message-listener plugin is enabled and allowed"
fi

# Update BASE_URL and API_KEY from environment variables
if [ -n "${BASE_URL:-}" ]; then
    jq --arg baseUrl "$BASE_URL" '.models.providers.neonx.baseUrl = $baseUrl' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Updated models.providers.neonx.baseUrl from BASE_URL"
fi

if [ -n "${API_KEY:-}" ]; then
    jq --arg apiKey "$API_KEY" '.models.providers.neonx.apiKey = $apiKey' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Updated models.providers.neonx.apiKey from API_KEY"
fi

# Enable Telegram plugin if TELEGRAM_BOT_TOKEN is provided
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    jq '
    .plugins.allow |= (. + ["telegram"] | unique) |
    .plugins.entries.telegram = {enabled: true} |
    .channels.telegram.accounts.default.dmPolicy = "open" |
    .channels.telegram.accounts.default.allowFrom = ["*"]
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Enabled Telegram plugin with open DM policy"
fi

# Install and enable Zalo plugins
ZALO_PLUGINS="@openclaw/zalo @openclaw/zalouser"
for plugin in $ZALO_PLUGINS; do
    plugin_id=$(echo "$plugin" | sed 's/@openclaw\///')
    
    # Check if plugin is already enabled
    if ! jq -e ".plugins.entries.\"$plugin_id\".enabled == true" "$CONFIG" >/dev/null 2>&1; then
        echo "Installing plugin: $plugin"
        if command -v openclaw >/dev/null 2>&1; then
            openclaw plugins install "$plugin" || echo "Warning: Failed to install $plugin"
        fi
        
        # Enable plugin in config
        jq --arg pid "$plugin_id" '
        .plugins.allow |= (. + [$pid] | unique) |
        .plugins.entries[$pid] = {enabled: true}
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Enabled plugin: $plugin_id"
    else
        echo "Plugin already enabled: $plugin_id"
    fi
done

# Install and enable Facebook plugin
FACEBOOK_PLUGIN="@agntdata/openclaw-facebook"
FACEBOOK_PLUGIN_ID="openclaw-facebook"

if ! jq -e ".plugins.entries.\"$FACEBOOK_PLUGIN_ID\".enabled == true" "$CONFIG" >/dev/null 2>&1; then
    echo "Installing plugin: $FACEBOOK_PLUGIN"
    if command -v openclaw >/dev/null 2>&1; then
        openclaw plugins install "$FACEBOOK_PLUGIN" || echo "Warning: Failed to install $FACEBOOK_PLUGIN"
    fi
    
    # Enable plugin in config
    jq --arg pid "$FACEBOOK_PLUGIN_ID" '
    .plugins.allow |= (. + [$pid] | unique) |
    .plugins.entries[$pid] = {enabled: true}
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Enabled plugin: $FACEBOOK_PLUGIN_ID"
else
    echo "Plugin already enabled: $FACEBOOK_PLUGIN_ID"
fi

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "Keeping container alive."
exec tail -f /dev/null