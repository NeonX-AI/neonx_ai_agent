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
PLUGIN_PATH="/home/node/.openclaw/workspace/luna-middleware"
if [ -d "$PLUGIN_PATH" ]; then
    echo "Luna middleware found — auto-configuring plugin..."
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
if '$PLUGIN_PATH' not in cfg['plugins']['load']['paths']:
    cfg['plugins']['load']['paths'].append('$PLUGIN_PATH')
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