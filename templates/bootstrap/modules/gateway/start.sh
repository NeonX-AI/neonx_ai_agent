#!/bin/sh
# Module: gateway startup
# Starts the OpenClaw gateway

if command -v openclaw >/dev/null 2>&1; then
    exec openclaw gateway run
fi

echo "Keeping container alive."
exec tail -f /dev/null
