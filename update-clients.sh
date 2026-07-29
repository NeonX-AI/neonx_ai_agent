#!/usr/bin/env bash
# Update Clients Script
# Loads modular setup scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# 1. Discover clients and confirm update
. "$SCRIPT_DIR/update-clients.d/10-discover.sh"

# 2. Restore plugins from git if needed
. "$SCRIPT_DIR/update-clients.d/20-restore.sh"

# 3. Update clients from templates
. "$SCRIPT_DIR/update-clients.d/30-update.sh"

# 4. Restart containers
. "$SCRIPT_DIR/update-clients.d/40-restart.sh"
