#!/bin/sh
set -eu

CONFIG=/home/node/.openclaw/openclaw.json
DATA_DIR=/home/node/.openclaw

mkdir -p "$DATA_DIR"
chown -R 1000:1000 "$DATA_DIR" 2>/dev/null || true
chmod -R u+rwX,g+rwX,o-rwx "$DATA_DIR" 2>/dev/null || true

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Keeping container alive."
    exec tail -f /dev/null
fi

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "openclaw binary not found. Keeping container alive."
exec tail -f /dev/null