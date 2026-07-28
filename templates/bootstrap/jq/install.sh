#!/bin/sh
# Module: jq installation
# Installs jq if not available

if ! command -v jq >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "jq not found. Installing jq..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y jq
    elif command -v apk >/dev/null 2>&1; then
        echo "jq not found. Installing jq..."
        apk add --no-cache jq
    else
        echo "jq not available and package manager not recognized. Skipping automatic plugin configuration"
        JQ_AVAILABLE=false
    fi
else
    JQ_AVAILABLE=true
fi
