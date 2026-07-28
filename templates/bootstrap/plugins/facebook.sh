#!/bin/sh
# Module: Facebook plugin setup
# Installs and configures Facebook Messenger plugin

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)
FACEBOOK_PLUGIN="git:github.com/Dj-Shortcut/openclaw-facebook"
FACEBOOK_PLUGIN_ID="facebook"
PLUGIN_DIR="$CONFIG_PATH/npm/projects"

# Remove stale plugin entries (old plugin names)
for stale_id in "openclaw-facebook" "agntdata-facebook"; do
    if jq -e ".plugins.entries[\"$stale_id\"]" "$CONFIG" >/dev/null 2>&1; then
        jq --arg sid "$stale_id" 'del(.plugins.entries[$sid]) | .plugins.allow |= map(select(. != $sid))' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Removed stale $stale_id config"
    fi
done

# Remove old agntdata plugin if exists
if [ -d "$PLUGIN_DIR" ]; then
    for old_dir in "$PLUGIN_DIR"/agntdata-openclaw-facebook-*; do
        if [ -d "$old_dir" ]; then
            echo "Removing old agntdata-openclaw-facebook plugin"
            rm -rf "$old_dir"
        fi
    done
fi

# Check if NEW plugin is actually installed on disk
FACEBOOK_INSTALLED=false
# Check in extensions directory (where openclaw plugins install puts it)
if [ -d "$CONFIG_PATH/extensions/facebook" ]; then
    FACEBOOK_INSTALLED=true
    # Install dependencies if node_modules is missing
    if [ ! -d "$CONFIG_PATH/extensions/facebook/node_modules" ]; then
        echo "Installing Facebook plugin dependencies..."
        cd "$CONFIG_PATH/extensions/facebook"
        if npm install --production >/dev/null 2>&1; then
            echo "✓ Facebook plugin dependencies installed"
        else
            echo "✗ Failed to install Facebook plugin dependencies"
        fi
        cd "$SCRIPT_DIR" 2>/dev/null || cd /
    fi
fi
# Also check in npm/projects directory
if [ "$FACEBOOK_INSTALLED" = false ] && [ -d "$PLUGIN_DIR" ]; then
    for dir in "$PLUGIN_DIR"/dj-shortcut-facebook-* "$PLUGIN_DIR"/openclaw-facebook-*; do
        if [ -d "$dir" ]; then
            FACEBOOK_INSTALLED=true
            break
        fi
    done
fi

# Install plugin if not found on disk
if [ "$FACEBOOK_INSTALLED" = false ]; then
    echo "Facebook plugin not found, attempting installation..."
    
    # Try ClawHub first
    if command -v openclaw >/dev/null 2>&1; then
        echo "Trying to install from ClawHub..."
        if openclaw plugins install @dj-shortcut/facebook --force 2>/dev/null; then
            echo "✓ Successfully installed Facebook plugin from ClawHub"
            FACEBOOK_INSTALLED=true
        fi
    fi
    
    # Fallback to GitHub if ClawHub failed
    if [ "$FACEBOOK_INSTALLED" = false ]; then
        echo "ClawHub installation failed, trying GitHub..."
        if command -v git >/dev/null 2>&1; then
            CLONE_DIR="/tmp/openclaw-facebook"
            rm -rf "$CLONE_DIR"
            
            if git clone --depth 1 https://github.com/Dj-Shortcut/openclaw-facebook.git "$CLONE_DIR"; then
                cd "$CLONE_DIR"
                
                # Install dependencies and build
                if npm install --include=dev --ignore-scripts >/dev/null 2>&1; then
                    if npx -p typescript tsc -p tsconfig.json >/dev/null 2>&1; then
                        rm -rf "$CLONE_DIR/.git"
                        
                        if command -v openclaw >/dev/null 2>&1; then
                            if openclaw plugins install "$CLONE_DIR" --force; then
                                echo "✓ Successfully installed Facebook plugin from GitHub"
                                FACEBOOK_INSTALLED=true
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
    
    if [ "$FACEBOOK_INSTALLED" = false ]; then
        echo "✗ Failed to install Facebook plugin"
    fi
fi

# Always ensure plugin is enabled in config
jq --arg pid "$FACEBOOK_PLUGIN_ID" '
.plugins.allow |= (. + [$pid] | unique) |
.plugins.entries[$pid] = {enabled: true}
' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
echo "Ensured plugin $FACEBOOK_PLUGIN_ID is enabled"

# Configure Facebook channel from environment variables (injected from .env.meta)
if [ -n "${FACEBOOK_PAGE_ID:-}" ] && [ -n "${FACEBOOK_PAGE_ACCESS_TOKEN:-}" ]; then
    jq \
        --arg pageId "$FACEBOOK_PAGE_ID" \
        --arg pageAccessToken "$FACEBOOK_PAGE_ACCESS_TOKEN" \
        --arg appSecret "${FACEBOOK_APP_SECRET:-}" \
        --arg verifyToken "${FACEBOOK_VERIFY_TOKEN:-}" \
        '
        .channels.facebook = {
            enabled: true,
            pageId: $pageId,
            pageAccessToken: $pageAccessToken,
            appSecret: $appSecret,
            verifyToken: $verifyToken,
            dmPolicy: "open",
            allowFrom: ["*"]
        }
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Configured Facebook channel from environment variables"
    
    # Remove sensitive environment variables after use
    unset FACEBOOK_APP_SECRET FACEBOOK_VERIFY_TOKEN FACEBOOK_PAGE_ID FACEBOOK_PAGE_ACCESS_TOKEN
    echo "Removed sensitive environment variables"
fi
