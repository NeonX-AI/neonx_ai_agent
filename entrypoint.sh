#!/bin/sh
set -e

CONFIG=/home/node/.openclaw/openclaw.json

if [ ! -f "$CONFIG" ]; then
    echo "First startup, creating config..."
    exec tail -f /dev/null
fi

exec openclaw gateway run