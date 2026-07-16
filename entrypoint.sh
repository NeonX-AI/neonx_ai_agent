#!/bin/sh
set -eu

CONFIG=/home/node/.openclaw/openclaw.json
PLUGIN_ID="luna-security-middleware"
PLUGIN_SRC="/home/node/.openclaw/workspace/luna-middleware"
PLUGIN_FALLBACK="/home/node/.openclaw/workspace/neonx_ai_agent/luna-middleware"
PLUGIN_DST="/home/node/.openclaw/workspace/luna-middleware"

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

if [ -d "$PLUGIN_SRC" ]; then
    echo "Found Luna middleware at $PLUGIN_SRC"
elif [ -d "$PLUGIN_FALLBACK" ]; then
    PLUGIN_SRC="$PLUGIN_FALLBACK"
    echo "Found Luna middleware at $PLUGIN_FALLBACK"
else
    echo "Luna middleware not found; skipping plugin auto-load"
fi

if [ -d "$PLUGIN_SRC" ]; then
    echo "Preparing plugin in workspace..."
    rm -rf "$PLUGIN_DST"
    mkdir -p "$PLUGIN_DST"
    cp -r "$PLUGIN_SRC"/. "$PLUGIN_DST"/
    chown -R root:root "$PLUGIN_DST" 2>/dev/null || true
    chmod -R u+rwX,go+rX "$PLUGIN_DST" 2>/dev/null || true

    python3 - "$CONFIG" "$PLUGIN_DST" "$PLUGIN_ID" <<'PY'
import json, sys
config_path, plugin_path, plugin_id = sys.argv[1:]
with open(config_path, "r") as fh:
    cfg = json.load(fh)

cfg.setdefault("plugins", {})
cfg["plugins"].setdefault("load", {})
cfg["plugins"]["load"].setdefault("paths", [])
if plugin_path not in cfg["plugins"]["load"]["paths"]:
    cfg["plugins"]["load"]["paths"].append(plugin_path)

cfg["plugins"].setdefault("allow", [])
if plugin_id not in cfg["plugins"]["allow"]:
    cfg["plugins"]["allow"].append(plugin_id)

cfg["plugins"].setdefault("entries", {})
cfg["plugins"]["entries"].setdefault(plugin_id, {})
cfg["plugins"]["entries"][plugin_id].setdefault("hooks", {})
cfg["plugins"]["entries"][plugin_id]["hooks"]["allowConversationAccess"] = True

with open(config_path, "w") as fh:
    json.dump(cfg, fh, indent=2)
PY

    echo "Plugin config injected."
fi

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "Keeping container alive."
exec tail -f /dev/null