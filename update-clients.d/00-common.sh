#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENTS_DIR="$SCRIPT_DIR/clients"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Use Docker directly on Docker Desktop; fall back to sudo on Linux only.
DOCKER_CMD=(docker)
if ! docker info >/dev/null 2>&1; then
    if [[ "${OSTYPE:-}" == linux* ]] && command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
        DOCKER_CMD=(sudo docker)
        echo "Info: Docker requires elevated privileges; using sudo."
    else
        echo "Error: Cannot connect to the Docker daemon."
        echo "On Ubuntu, run: sudo usermod -aG docker \$USER"
        echo "Then log out and back in, or run 'sudo -v' before this script."
        exit 1
    fi
fi
COMPOSE_CMD=("${DOCKER_CMD[@]}" compose)

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
    "bootstrap/entrypoint.sh"
    "bootstrap/modules"
    "docker-compose.yml"
)

# Files/directories to NEVER update (user-specific data)
EXCLUDE_ITEMS=(
    "agent_data"
    ".env"
)

export UPDATE_ITEMS EXCLUDE_ITEMS
