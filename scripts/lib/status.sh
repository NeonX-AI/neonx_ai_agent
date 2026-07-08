#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# status.sh — Báo cáo OS, RAM, Docker, stack, port, health, UFW
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

INSTALL_DIR="/opt/dataonline/openclaw"
GATEWAY_PORT=18789
BRIDGE_PORT=18790

print_section() {
    echo ""
    print_header "$1"
}

# -----------------------------------------------------------------------------
# Tài nguyên & hệ điều hành
# -----------------------------------------------------------------------------
check_ram_status() {
    local mem_kb mem_gb
    mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    mem_gb=$(echo "scale=2; ${mem_kb:-0}/1024/1024" | bc 2>/dev/null || echo "N/A")
    if [[ "${mem_gb}" == "N/A" ]]; then
        print_info "RAM: không đọc được"
    elif [[ -n "${mem_gb}" ]] && awk -v gb="${mem_gb}" 'BEGIN{exit (gb<2)?0:1}' 2>/dev/null; then
        print_warning "RAM: ${mem_gb} GB (khuyến nghị >= 2GB)"
    else
        print_success "RAM: ${mem_gb} GB"
    fi
}

check_disk_status() {
    local pct
    read -r _ _ pct _ < <(df -BM "${INSTALL_DIR:-/}" 2>/dev/null | tail -1) || true
    if [[ -n "${pct}" ]]; then
        print_info "Disk: ${pct} đã sử dụng"
    else
        df -h / 2>/dev/null | tail -1 || print_warning "Không đọc được thông tin Disk"
    fi
}

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
check_docker_status() {
    if command -v docker &>/dev/null; then
        print_success "Docker: $(docker --version)"
        if docker compose version &>/dev/null; then
            print_success "Docker Compose: $(docker compose version --short 2>/dev/null || echo 'OK')"
        else
            print_warning "Docker Compose: chưa cài"
        fi
    else
        print_error "Docker: chưa cài đặt"
    fi
}

# -----------------------------------------------------------------------------
# Stack OpenClaw (compose, container, image)
# -----------------------------------------------------------------------------
check_openclaw_status() {
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        print_warning "OpenClaw: chưa cài đặt (không tìm thấy ${INSTALL_DIR})"
        return
    fi

    print_info "Thư mục cài đặt: ${INSTALL_DIR}"
    if [[ -f "${INSTALL_DIR}/.env" ]]; then
        print_success "File .env: có"
    else
        print_warning "File .env: không có"
    fi
    if [[ -f "${INSTALL_DIR}/docker-compose.yml" ]]; then
        print_success "docker-compose.yml: có"
    else
        print_warning "docker-compose.yml: không có"
    fi

    cd "${INSTALL_DIR}" 2>/dev/null || return
    local gateway_status cli_status
    gateway_status=$(docker compose ps openclaw-gateway --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    cli_status=$(docker compose ps -a openclaw-cli --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

    if [[ "${gateway_status}" == "running" ]]; then
        print_success "Container openclaw-gateway: đang chạy"
    else
        print_warning "Container openclaw-gateway: ${gateway_status}"
    fi
    if [[ "${cli_status}" == "running" ]] || [[ "${cli_status}" == "exited" ]]; then
        print_info "Container openclaw-cli: ${cli_status}"
    else
        print_warning "Container openclaw-cli: ${cli_status}"
    fi

    local img
    img=$(docker compose images -q openclaw-gateway 2>/dev/null || true)
    if [[ -n "${img}" ]]; then
        local repo_tag
        repo_tag=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -E 'openclaw|ghcr.io' | head -1 || true)
        print_success "Image: ${repo_tag:-ghcr.io/openclaw/openclaw:latest (đã tải)}"
    fi
}

# -----------------------------------------------------------------------------
# Lắng nghe cổng & healthz
# -----------------------------------------------------------------------------
check_port_status() {
    for port in "${GATEWAY_PORT}" "${BRIDGE_PORT}"; do
        if ss -tlnp 2>/dev/null | grep -q ":${port} " || netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
            print_success "Port ${port}: đang lắng nghe"
        else
            print_warning "Port ${port}: không lắng nghe"
        fi
    done
}

check_health_status() {
    if curl -sf "http://127.0.0.1:${GATEWAY_PORT}/healthz" &>/dev/null; then
        print_success "Health check: Gateway phản hồi OK"
    else
        print_warning "Health check: Gateway không phản hồi"
    fi
}

# -----------------------------------------------------------------------------
# UFW
# -----------------------------------------------------------------------------
check_ufw_status() {
    if command -v ufw &>/dev/null; then
        local status
        status=$(ufw status 2>/dev/null | head -1)
        print_info "UFW: ${status}"
        for port in 22 "${GATEWAY_PORT}" "${BRIDGE_PORT}"; do
            if ufw status | grep -qE "^${port}\s|^${port}\s|${port}\s+ALLOW"; then
                print_success "  Cổng ${port}: allowed"
            else
                print_warning "  Cổng ${port}: chưa mở"
            fi
        done
    else
        print_warning "UFW: chưa cài đặt"
    fi
}

check_os_status() {
    if [[ -f /etc/os-release ]]; then
        local name version
        name=$(grep ^NAME= /etc/os-release | cut -d'"' -f2)
        version=$(grep ^VERSION= /etc/os-release | cut -d'"' -f2)
        print_info "Hệ điều hành: ${name} ${version}"
    fi
}

# -----------------------------------------------------------------------------
# URL đầy đủ + token (chạy trên máy chủ; không ghi log công khai token)
# -----------------------------------------------------------------------------
check_access_info() {
    if [[ ! -f "${INSTALL_DIR}/.env" ]]; then
        return 0
    fi
    local token ip
    token=$(grep -m1 '^OPENCLAW_GATEWAY_TOKEN=' "${INSTALL_DIR}/.env" | cut -d= -f2-)
    token=$(printf '%s' "$token" | tr -d '\r')
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -z "${token}" ]]; then
        print_warning "Gateway Token: không đọc được từ .env"
        return 0
    fi
    print_info "Gateway URL (LAN):     http://${ip:-?}:${GATEWAY_PORT}"
    print_info "Gateway URL (localhost): http://127.0.0.1:${GATEWAY_PORT}"
    echo -e "  ${C_DIM}Control UI / WebSocket: ưu tiên mở bằng localhost hoặc HTTPS (tránh lỗi device identity trên IP LAN).${C_RESET}"
    print_info "Cổng bridge (nội bộ):  ${BRIDGE_PORT} (cùng host với gateway trong Compose)"
    echo ""
    print_info "Gateway Token (đầy đủ):"
    echo -e "  ${C_SUCCESS}${token}${C_RESET}"
    echo -e "  ${C_DIM}Không chia sẻ token; đổi token nếu lộ — sửa OPENCLAW_GATEWAY_TOKEN trong .env rồi restart gateway.${C_RESET}"
}

# -----------------------------------------------------------------------------
# Entry: in từng khối
# -----------------------------------------------------------------------------
do_status() {
    print_section "TỔNG QUAN HỆ THỐNG"
    check_os_status
    check_ram_status
    check_disk_status

    print_section "DOCKER"
    check_docker_status

    print_section "OPENCLAW"
    check_openclaw_status

    print_section "MẠNG & CỔNG"
    check_port_status
    check_health_status

    print_section "BẢO MẬT (UFW)"
    check_ufw_status

    print_section "THÔNG TIN TRUY CẬP"
    check_access_info

    echo ""
}
