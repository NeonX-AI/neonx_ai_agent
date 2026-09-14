#!/usr/bin/env bash
# Create Client Script
# Loads modular setup scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# 1. Input and validate client configuration
. "$SCRIPT_DIR/create-client.d/10-input.sh"

# 2. Prepare client directory and environment
. "$SCRIPT_DIR/create-client.d/20-prepare.sh"

# 3. Configure port exposure
. "$SCRIPT_DIR/create-client.d/30-ports.sh"

# 4. Start services
. "$SCRIPT_DIR/create-client.d/40-start.sh"
