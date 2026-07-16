#!/bin/sh
set -eu

CONFIG=/home/node/.openclaw/openclaw.json

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

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Keeping container alive."
    exec tail -f /dev/null
fi

# Auto-configure Luna Security Middleware plugin
# Copy plugin from repo to workspace (so ownership becomes root)
PLUGIN_SRC="/home/node/.openclaw/workspace/neonx_ai_agent/luna-middleware"
PLUGIN_DST="/home/node/.openclaw/workspace/luna-middleware"
PLUGIN_ID="luna-security-middleware"

if [ -d "$PLUGIN_SRC" ]; then
    echo "Luna middleware source found — preparing workspace copy..."
    if [ -d "$PLUGIN_DST" ]; then
        echo "Plugin destination already exists; reusing mounted files."
    else
        mkdir -p "$(dirname "$PLUGIN_DST")"
        cp -r "$PLUGIN_SRC" "$PLUGIN_DST"
    fi
    mkdir -p "$(dirname "$PLUGIN_DST")"
    chown -R root:root "$PLUGIN_DST" 2>/dev/null || true
    chown root:root "$(dirname "$PLUGIN_DST")" 2>/dev/null || true
    chmod -R u+rwX,go+rX "$PLUGIN_DST" 2>/dev/null || true
    echo "Plugin ready at $PLUGIN_DST."
fi

if [ -d "$PLUGIN_DST" ]; then
    echo "Luna middleware installed — auto-configuring plugin..."
    python3 -c "
import json, sys
with open('$CONFIG', 'r') as f:
    cfg = json.load(f)
if 'plugins' not in cfg:
    cfg['plugins'] = {}
if 'load' not in cfg['plugins']:
    cfg['plugins']['load'] = {}
if 'paths' not in cfg['plugins']['load']:
    cfg['plugins']['load']['paths'] = []
if '$PLUGIN_DST' not in cfg['plugins']['load']['paths']:
    cfg['plugins']['load']['paths'].append('$PLUGIN_DST')
if 'allow' not in cfg['plugins']:
    cfg['plugins']['allow'] = []
if '$PLUGIN_ID' not in cfg['plugins']['allow']:
    cfg['plugins']['allow'].append('$PLUGIN_ID')
if 'entries' not in cfg['plugins']:
    cfg['plugins']['entries'] = {}
if '$PLUGIN_ID' not in cfg['plugins']['entries']:
    cfg['plugins']['entries']['$PLUGIN_ID'] = {}
if 'hooks' not in cfg['plugins']['entries']['$PLUGIN_ID']:
    cfg['plugins']['entries']['$PLUGIN_ID']['hooks'] = {}
cfg['plugins']['entries']['$PLUGIN_ID']['hooks']['allowConversationAccess'] = True
with open('$CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
print('Plugin config injected.')
" 2>/dev/null || echo "Failed to inject plugin config (python3 not available)"
else
    echo "Luna middleware not found — skipping plugin auto-config"
fi

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "Keeping container alive."
exec tail -f /dev/null