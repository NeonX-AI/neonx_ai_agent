#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: Neither 'docker-compose' nor 'docker compose' found"
    exit 1
fi

export SCRIPT_DIR COMPOSE_CMD

update_or_append() {
    local env_file="$1"
    local key="$2"
    local value="$3"

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        # Cross-platform sed in-place edit
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$env_file"
        else
            sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
        fi
    else
        echo "${key}=${value}" >> "$env_file"
    fi
}

find_available_port() {
    local start_port="$1"
    local port="$start_port"

    # Detect available Python command (python3 on macOS/Linux, python on Windows)
    local py_cmd=""
    if command -v python3 >/dev/null 2>&1; then
        py_cmd="python3"
    elif command -v python >/dev/null 2>&1; then
        py_cmd="python"
    fi

    while :; do
        # Check if port is available using netcat or Python
        if command -v nc >/dev/null 2>&1; then
            # Use netcat to check if port is in use
            if ! nc -z localhost "$port" >/dev/null 2>&1; then
                echo "$port"
                return 0
            fi
        elif [ -n "$py_cmd" ]; then
            # Fallback to Python if available
            if $py_cmd -c "import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(('0.0.0.0', $port)); s.close()" 2>/dev/null; then
                echo "$port"
                return 0
            fi
        else
            # Last resort: assume port is available
            echo "$port"
            return 0
        fi

        port=$((port + 1))
        if [ "$port" -gt 65535 ]; then
            echo "Error: Could not find a free port starting from $start_port" >&2
            exit 1
        fi
    done
}
