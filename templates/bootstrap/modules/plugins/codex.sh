#!/bin/sh
# Module: Codex plugin setup
# Installs and enables the official Codex plugin (@openclaw/codex)
# Docs: https://docs.openclaw.ai/plugins/reference/codex

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
CODEX_PLUGIN_ID="codex"
CODEX_PACKAGE="@openclaw/codex"

TMP=$(mktemp)

# Skip if plugin is already enabled
if jq -e ".plugins.entries.\"$CODEX_PLUGIN_ID\".enabled == true" "$CONFIG" >/dev/null 2>&1; then
    echo "Codex plugin already enabled"
else
    echo "Installing Codex plugin ($CODEX_PACKAGE)..."
    if command -v openclaw >/dev/null 2>&1; then
        # Official OpenClaw catalog package (trusted source, no --force needed).
        # On repeat startups this reports "already installed", which is fine.
        openclaw plugins install "$CODEX_PACKAGE" 2>&1 || \
            echo "Note: install returned non-zero (plugin may already be installed)"

        # Only enable in config if OpenClaw actually knows the plugin,
        # so the gateway never starts with a dangling plugin entry.
        if openclaw plugins inspect "$CODEX_PLUGIN_ID" >/dev/null 2>&1; then
            jq --arg pid "$CODEX_PLUGIN_ID" '
            .plugins.allow |= (. + [$pid] | unique) |
            .plugins.entries[$pid] = {enabled: true}
            ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
            echo "✓ Codex plugin installed and enabled"
        else
            echo "✗ Codex plugin not found after install; will retry on next start"
        fi
    else
        echo "Warning: openclaw CLI not found, cannot install Codex plugin"
    fi
fi

rm -f "$TMP"
