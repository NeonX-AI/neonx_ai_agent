#!/bin/sh
# Module: nano installation
# Installs nano editor if not available

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
