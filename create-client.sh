#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"

usage() {
  cat <<EOF
Cách dùng:
  ./create-isolated-container.sh [--name TEN_CONTAINER] [--network TEN_NETWORK]

Ví dụ:
  ./create-isolated-container.sh --name my-ai-agent --network my-ai-agent-net
EOF
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker chưa được cài đặt hoặc chưa có trong PATH."
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  compose_cmd=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose_cmd=(docker-compose)
else
  echo "Không tìm thấy docker compose."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="docker-compose.yml"
cd "$SCRIPT_DIR"

container_name=""
network_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      container_name="${2:-}"
      shift 2
      ;;
    --network)
      network_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Tham số không hợp lệ: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -z "$container_name" ]]; then
  read -rp "Nhập tên container: " container_name
fi

if [[ -z "$container_name" ]]; then
  echo "Tên container không được để trống."
  exit 1
fi

if [[ ! "$container_name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
  echo "Tên container chỉ được chứa chữ, số, dấu chấm, gạch dưới và gạch nối."
  exit 1
fi

if [[ -z "$network_name" ]]; then
  network_name="${container_name}-net"
fi

if [[ ! "$network_name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
  echo "Tên network chỉ được chứa chữ, số, dấu chấm, gạch dưới và gạch nối."
  exit 1
fi

cat > "$ENV_FILE" <<EOF
CONTAINER_NAME=$container_name
NETWORK_NAME=$network_name
EOF

if ! docker network inspect "$network_name" >/dev/null 2>&1; then
  docker network create --driver bridge --internal "$network_name" >/dev/null
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Không tìm thấy file compose: $COMPOSE_FILE"
  exit 1
fi

"${compose_cmd[@]}" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --force-recreate ai_agent >/dev/null

echo "Đã tạo container '$container_name' bằng Docker Compose dựa trên file '$COMPOSE_FILE' và network riêng '$network_name'."
echo "Xem trạng thái: ${compose_cmd[*]} ps"
