#!/usr/bin/env bash
# Codex Interactive Terminal - cross-platform launcher (macOS / Linux / Windows Git Bash)
# Picks a running OpenClaw client container and starts an isolated Codex session in it.

set -u

WORKSPACE="/home/node/.openclaw/projects"
# Keep terminal Codex threads separate from OpenClaw's Telegram/App Server state.
# This path is inside the persistent OpenClaw mount.
CODEX_HOME="/home/node/.openclaw/codex-interactive"

echo "========================================"
echo "  Codex Interactive Terminal"
echo "========================================"
echo

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker was not found in PATH."
    echo "Install or start Docker Desktop, then try again."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "[ERROR] Docker daemon is not running."
    exit 1
fi

# Collect running OpenClaw client containers (compose service: ai_agent)
CONTAINERS=()
CLIENTS=()
while IFS= read -r name; do
    [ -z "$name" ] && continue
    project=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$name" 2>/dev/null)
    [ -z "$project" ] && project="$name"
    CONTAINERS+=("$name")
    CLIENTS+=("$project")
done < <(docker ps --filter "label=com.docker.compose.service=ai_agent" --format '{{.Names}}')

COUNT=${#CONTAINERS[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "[ERROR] No running OpenClaw client containers were found."
    echo "Start a client first, then try again."
    exit 1
fi

if [ "$COUNT" -eq 1 ]; then
    SELECTION=1
else
    echo "Available OpenClaw clients:"
    echo
    for i in $(seq 1 "$COUNT"); do
        echo "  $i. ${CLIENTS[$((i - 1))]}  [${CONTAINERS[$((i - 1))]}]"
    done
    echo
    read -r -p "Enter client number: " SELECTION
fi

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$COUNT" ]; then
    echo "[ERROR] Invalid client number: $SELECTION"
    exit 1
fi

CONTAINER="${CONTAINERS[$((SELECTION - 1))]}"
CLIENT="${CLIENTS[$((SELECTION - 1))]}"

echo
echo "Selected client : $CLIENT"
echo "Container       : $CONTAINER"
echo "Workspace       : $WORKSPACE"
echo "Codex state     : $CODEX_HOME"
echo

if ! docker exec "$CONTAINER" sh -lc "command -v codex >/dev/null 2>&1"; then
    echo "[ERROR] Codex CLI is not installed in this client yet."
    echo "Wait for container bootstrap to finish, then try again."
    exit 1
fi

if ! docker exec "$CONTAINER" sh -lc "mkdir -p '$CODEX_HOME' && if [ ! -f '$CODEX_HOME/config.toml' ] && [ -f /root/.codex/config.toml ]; then cp /root/.codex/config.toml '$CODEX_HOME/config.toml'; chmod 600 '$CODEX_HOME/config.toml'; fi"; then
    echo "[ERROR] Could not prepare the isolated Codex state directory."
    exit 1
fi

echo "Starting isolated Codex session. Type /help for help, or Ctrl+C to exit."
echo

docker exec -it -e "CODEX_HOME=$CODEX_HOME" -w "$WORKSPACE" "$CONTAINER" \
    codex --sandbox danger-full-access --ask-for-approval never --no-alt-screen
EXIT_CODE=$?

echo
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "Codex exited with code $EXIT_CODE."
fi
echo "Codex session closed."
exit "$EXIT_CODE"
