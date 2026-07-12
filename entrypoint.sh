#!/bin/sh
set -eu

CONFIG=/home/node/.openclaw/openclaw.json
DATA_DIR=/home/node

mkdir -p "$DATA_DIR"
chmod 755 "$DATA_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Keeping container alive."
    exec tail -f /dev/null
fi

if command -v openclaw >/dev/null 2>&1; then
    export OPENCLAW_HOME="$DATA_DIR"
    exec openclaw gateway run
fi

echo "openclaw binary not found. Keeping container alive."
exec tail -f /dev/null