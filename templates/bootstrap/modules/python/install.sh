#!/bin/sh
# Module: Python venv installation
# Kept in bootstrap so the stock OpenClaw image can be used without a custom
# Dockerfile. The installed package remains available while the container
# exists; it is installed again only after a container is recreated.

# `python3.11 -m venv --help` succeeds even when Debian's ensurepip module is
# absent, so test the module itself rather than the command help text.
if ! python3.11 -c 'import ensurepip' >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "python3.11-venv not found. Installing python3.11-venv..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends python3.11-venv
        rm -rf /var/lib/apt/lists/*
    else
        echo "python3.11-venv not found and apt-get is unavailable."
    fi
fi
