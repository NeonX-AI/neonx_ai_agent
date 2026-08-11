#!/bin/sh
# Module: Codex App Server plugin setup (openclaw-codex-app-server)
# Bridges OpenClaw <-> Codex App Server protocol so Codex threads can be
# driven from Telegram/Discord conversations (/cas_resume, /cas_status, ...).
# Docs: https://github.com/pwrdrvr/openclaw-codex-app-server
#
# The plugin spawns `codex app-server`, so the Codex CLI must be present.
# OpenClaw flags this plugin as unsafe (process spawn is the whole bridge),
# so install needs the unsafe/force flags, with a manual npm-pack fallback.
#
# Optional env overrides (set in the client .env):
#   CODEX_APP_SERVER_WORKSPACE_DIR  fallback workspace dir (default: agent workspace)
#   CODEX_APP_SERVER_MODEL          default model for new Codex threads
#   CODEX_APP_SERVER_TRANSPORT      stdio (default) | websocket
#   CODEX_APP_SERVER_URL            websocket url (only for transport=websocket)

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
PLUGIN_ID="openclaw-codex-app-server"
PLUGIN_DIR="$CONFIG_PATH/extensions/$PLUGIN_ID"
WORKSPACE_DIR="${CODEX_APP_SERVER_WORKSPACE_DIR:-/home/node/.openclaw/workspace}"
TRANSPORT="${CODEX_APP_SERVER_TRANSPORT:-stdio}"
WS_URL="${CODEX_APP_SERVER_URL:-}"
MODEL="${CODEX_APP_SERVER_MODEL:-}"

# Default model fallback: derive from the primary model in openclaw.json
# (written by config/models.sh), stripping the provider prefix so it matches
# the Codex model id in config.toml (e.g. "neonx/neonx-3.0-plus" -> "neonx-3.0-plus").
if [ -z "$MODEL" ] && command -v jq >/dev/null 2>&1 && [ -f "$CONFIG" ]; then
    primary=$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG" 2>/dev/null)
    if [ -n "$primary" ]; then
        case "$primary" in
            */*) MODEL="${primary#*/}" ;;
            *)   MODEL="$primary" ;;
        esac
    fi
fi

TMP=$(mktemp)

# ---------------------------------------------------------------------------
# 1. Ensure the Codex CLI is available (the plugin spawns `codex app-server`)
# ---------------------------------------------------------------------------
if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI already installed: $(codex --version 2>/dev/null || echo unknown)"
elif command -v npm >/dev/null 2>&1; then
    echo "Installing Codex CLI (@openai/codex)..."
    npm install -g @openai/codex 2>&1 || echo "Warning: failed to install @openai/codex"
    if command -v codex >/dev/null 2>&1; then
        echo "✓ Codex CLI installed"
    else
        echo "✗ Codex CLI not found after install (plugin will retry at runtime)"
    fi
else
    echo "Warning: npm not found, cannot install Codex CLI"
fi

# ---------------------------------------------------------------------------
# 2. Install the plugin
# ---------------------------------------------------------------------------
plugin_known() {
    command -v openclaw >/dev/null 2>&1 && \
        openclaw plugins inspect "$PLUGIN_ID" >/dev/null 2>&1
}

if plugin_known; then
    echo "$PLUGIN_ID plugin already installed"
else
    if ! command -v openclaw >/dev/null 2>&1; then
        echo "Warning: openclaw CLI not found, cannot install $PLUGIN_ID"
    else
        echo "Installing $PLUGIN_ID plugin..."
        # Newer OpenClaw: --dangerously-force-unsafe-install is a deprecated
        # no-op but still accepted; older builds require it. --force covers
        # noninteractive arbitrary-npm installs.
        openclaw plugins install --dangerously-force-unsafe-install "$PLUGIN_ID" 2>&1 || \
            openclaw plugins install --force "$PLUGIN_ID" 2>&1 || \
            echo "Note: CLI install returned non-zero"
    fi

    # Manual fallback (README path): npm pack into the extensions directory.
    if ! plugin_known && [ ! -f "$PLUGIN_DIR/openclaw.plugin.json" ]; then
        echo "Manual install fallback for $PLUGIN_ID..."
        if command -v npm >/dev/null 2>&1; then
            workdir=$(mktemp -d)
            : > "$workdir/empty-npmrc"
            if (cd "$workdir" && npm --userconfig "$workdir/empty-npmrc" pack "$PLUGIN_ID@latest" >/dev/null 2>&1); then
                mkdir -p "$PLUGIN_DIR"
                tar -xzf "$workdir/$PLUGIN_ID"-*.tgz -C "$workdir" 2>/dev/null
                if [ -d "$workdir/package" ]; then
                    cp -R "$workdir/package/." "$PLUGIN_DIR/"
                    # Install runtime deps (e.g. ws) for the manual copy.
                    # --legacy-peer-deps: skip the `openclaw` peer dep; the
                    # plugin resolves the SDK from the host OpenClaw install.
                    (cd "$PLUGIN_DIR" && npm install --omit=dev --legacy-peer-deps --no-audit --no-fund 2>&1) || \
                        echo "Warning: failed to install $PLUGIN_ID dependencies"
                    echo "✓ $PLUGIN_ID unpacked into $PLUGIN_DIR"
                else
                    echo "✗ Unexpected tarball layout for $PLUGIN_ID"
                fi
            else
                echo "✗ Failed to download $PLUGIN_ID package from npm"
            fi
            rm -rf "$workdir"
        else
            echo "Warning: npm not found, cannot install $PLUGIN_ID"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3. Enable + configure the plugin in openclaw.json
#    Only once OpenClaw knows the plugin (or its manifest is on disk), so the
#    gateway never starts with a dangling plugin entry.
# ---------------------------------------------------------------------------
if plugin_known || [ -f "$PLUGIN_DIR/openclaw.plugin.json" ]; then
    if [ -f "$CONFIG" ]; then
        jq --arg pid "$PLUGIN_ID" \
           --arg ws "$WORKSPACE_DIR" \
           --arg transport "$TRANSPORT" \
           --arg url "$WS_URL" \
           --arg model "$MODEL" '
        .plugins.allow = ((.plugins.allow // []) + [$pid] | unique) |
        .plugins.entries = (.plugins.entries // {}) |
        .plugins.entries[$pid] = (.plugins.entries[$pid] // {}) |
        .plugins.entries[$pid].enabled = true |
        .plugins.entries[$pid].config = (
            {enabled: true, transport: $transport, defaultWorkspaceDir: $ws}
            + (if $transport == "stdio" then {command: "codex"} else {} end)
            + (if $transport == "websocket" and $url != "" then {url: $url} else {} end)
            + (if $model != "" then {defaultModel: $model} else {} end)
        )
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "✓ $PLUGIN_ID plugin enabled (transport=$TRANSPORT, workspace=$WORKSPACE_DIR)"
    else
        echo "Warning: $CONFIG not found, cannot enable $PLUGIN_ID"
    fi
else
    echo "✗ $PLUGIN_ID plugin not available; will retry on next start"
fi

rm -f "$TMP"
