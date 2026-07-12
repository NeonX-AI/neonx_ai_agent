#!/bin/sh
set -eu

CONFIG=/home/node/.openclaw/openclaw.json

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found. Keeping container alive."
    exec tail -f /dev/null
fi

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "openclaw binary not found. Keeping container alive."
exec tail -f /dev/null