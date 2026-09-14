#!/bin/sh
# Module: Manually install Codex CLI and the packaged openclaw-codex-app-server.

CONFIG="/home/node/.openclaw/openclaw.json"
PLUGIN_ID="openclaw-codex-app-server"
PACKAGE="$PLUGIN_ID@latest"
WORK_DIR="/tmp/openclaw-cas"
EXTENSION_DIR="/home/node/.openclaw/extensions/$PLUGIN_ID"
DEFAULT_WORKSPACE_DIR="/home/node/.openclaw/projects"

if openclaw plugins inspect "$PLUGIN_ID" >/dev/null 2>&1; then
    echo "$PLUGIN_ID is already installed; skipping download"
else
    cd /tmp || exit 1
    rm -f "$PLUGIN_ID"-*.tgz
    TARBALL=$(npm --userconfig /tmp/empty-npmrc pack "$PACKAGE") || exit 1

    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    tar -xzf "/tmp/$TARBALL" -C "$WORK_DIR" || exit 1

    rm -rf "$EXTENSION_DIR"
    mkdir -p "$EXTENSION_DIR"
    cp -R "$WORK_DIR/package"/. "$EXTENSION_DIR"/

    # The npm tarball excludes node_modules; install only runtime dependencies
    # such as ws, without dev dependencies or the OpenClaw peer dependency.
    npm --prefix "$EXTENSION_DIR" install --omit=dev --omit=peer --ignore-scripts || exit 1

    rm -f "/tmp/$TARBALL"
    rm -rf "$WORK_DIR"
fi

if [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; then
    TMP=$(mktemp)
    jq --arg plugin "$PLUGIN_ID" '
        .plugins = (.plugins // {}) |
        .plugins.allow = ((.plugins.allow // []) + [$plugin] | unique) |
        .plugins.entries = (.plugins.entries // {}) |
        .plugins.entries[$plugin] = ((.plugins.entries[$plugin] // {}) + {enabled: true})
    ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    rm -f "$TMP"
fi

openclaw plugins inspect "$PLUGIN_ID"
