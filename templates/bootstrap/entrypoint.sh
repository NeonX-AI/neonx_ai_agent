#!/bin/sh
# OpenClaw Agent Entrypoint
# Loads modular setup scripts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export SCRIPT_DIR

# 1. Install system dependencies
# . "$SCRIPT_DIR/modules/nano/install.sh"
. "$SCRIPT_DIR/modules/jq/install.sh"

# 2. Setup restart command
. "$SCRIPT_DIR/modules/restart/setup.sh"

# 3. Initialize config
. "$SCRIPT_DIR/modules/config/init.sh"

# 4. Configure models
. "$SCRIPT_DIR/modules/config/models.sh"

# 5. Setup plugins
. "$SCRIPT_DIR/modules/plugins/telegram.sh"
. "$SCRIPT_DIR/modules/plugins/zalo.sh"
. "$SCRIPT_DIR/modules/plugins/facebook.sh"

# 6. Start gateway
. "$SCRIPT_DIR/modules/gateway/start.sh"