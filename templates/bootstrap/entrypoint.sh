#!/bin/sh
# OpenClaw Agent Entrypoint
# Loads modular setup scripts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export SCRIPT_DIR

# 1. Install system dependencies
. "$SCRIPT_DIR/modules/nano/install.sh"
. "$SCRIPT_DIR/modules/jq/install.sh"

# 2. Setup restart command
# Disabled for now to prevent auto restart tooling
# . "$SCRIPT_DIR/modules/restart/setup.sh"

# 3. Setup plugins (before config init so plugins are available)
. "$SCRIPT_DIR/modules/plugins/openclaw-message-listener.sh"
. "$SCRIPT_DIR/modules/plugins/facebook.sh"

# 4. Initialize config
. "$SCRIPT_DIR/modules/config/init.sh"

# 5. Configure models
. "$SCRIPT_DIR/modules/config/models.sh"

# 5b. Chatbot mode (CHAT_BOT=true -> hide skills + stub KNOWLEDGE.md for speed)
. "$SCRIPT_DIR/modules/config/chatbot.sh"

# 6. Setup other plugins
. "$SCRIPT_DIR/modules/plugins/telegram.sh"
. "$SCRIPT_DIR/modules/plugins/zalo.sh"
# . "$SCRIPT_DIR/modules/plugins/codex.sh"
# . "$SCRIPT_DIR/modules/plugins/codex-skills.sh"
# . "$SCRIPT_DIR/modules/plugins/codex-provider.sh"
# . "$SCRIPT_DIR/modules/plugins/codex-app-server.sh"

# 7. Start gateway
. "$SCRIPT_DIR/modules/gateway/start.sh"