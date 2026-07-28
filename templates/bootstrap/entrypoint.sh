#!/bin/sh
# OpenClaw Agent Entrypoint
# Loads modular setup scripts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export SCRIPT_DIR

# 1. Install system dependencies
. "$SCRIPT_DIR/nano/install.sh"
. "$SCRIPT_DIR/jq/install.sh"

# 2. Setup restart command
. "$SCRIPT_DIR/restart/setup.sh"

# 3. Initialize config
. "$SCRIPT_DIR/config/init.sh"

# 4. Configure models
. "$SCRIPT_DIR/config/models.sh"

# 5. Setup plugins
. "$SCRIPT_DIR/plugins/telegram.sh"
. "$SCRIPT_DIR/plugins/zalo.sh"
. "$SCRIPT_DIR/plugins/facebook.sh"

# 6. Start gateway
. "$SCRIPT_DIR/gateway/start.sh"