#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENTS_DIR="$SCRIPT_DIR/clients"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

export SCRIPT_DIR CLIENTS_DIR TEMPLATES_DIR

# Parse arguments
AUTO_YES=false
for arg in "$@"; do
    case $arg in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
    esac
done

export AUTO_YES

# Files/directories to update from templates
UPDATE_ITEMS=(
    "entrypoint.sh"
    "docker-compose.yml"
    ".env.meta"
    "agent_data/extensions/facebook"
    "agent_data/extensions/openclaw-message-listener"
)

# Files/directories to NEVER update (user-specific data)
EXCLUDE_ITEMS=(
    "agent_data"
    ".env"
)

export UPDATE_ITEMS EXCLUDE_ITEMS
