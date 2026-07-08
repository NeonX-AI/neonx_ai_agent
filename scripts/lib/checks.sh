#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# checks.sh — Tiền điều kiện: Ubuntu, RAM, port, mạng, Docker
# -----------------------------------------------------------------------------

[[ -z "${OPENCLAW_GATEWAY_PORT+x}" ]] && OPENCLAW_GATEWAY_PORT=18789
[[ -z "${OPENCLAW_BRIDGE_PORT+x}" ]] && OPENCLAW_BRIDGE_PORT=18790

# -----------------------------------------------------------------------------
# Hệ điều hành & kiến trúc
# -----------------------------------------------------------------------------
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Không xác định được hệ điều hành."
        return 1
    fi
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "Script chỉ hỗ trợ Ubuntu. Phát hiện: $ID"
        return 1
    fi
    local ver="${VERSION_ID:-0}"
    if [[ "$ver" != "22.04" && "$ver" != "24.04" ]]; then
        log_warn "Phiên bản Ubuntu $ver có thể chưa được kiểm thử. Khuyến nghị: 22.04 hoặc 24.04."
        confirm "Tiếp tục cài đặt?" || return 1
    fi
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]]; then
        log_error "Chỉ hỗ trợ kiến trúc x86_64. Phát hiện: $arch"
        return 1
    fi
    log_success "Hệ điều hành: $PRETTY_NAME ($arch)"
    return 0
}

# -----------------------------------------------------------------------------
# Bộ nhớ
# -----------------------------------------------------------------------------
get_ram_mb() {
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    echo $((mem_kb / 1024))
}

check_ram() {
    local ram_mb
    ram_mb=$(get_ram_mb)
    if [[ -z "$ram_mb" || "$ram_mb" -lt 512 ]]; then
        log_error "RAM không đủ (< 512MB). Không thể cài đặt."
        return 1
    fi
    if [[ "$ram_mb" -lt 2048 ]]; then
        echo -e "${C_ERROR}[CẢNH BÁO] RAM hiện tại: ${ram_mb}MB (< 2GB).${C_RESET}"
        echo -e "  OpenClaw khuyến nghị tối thiểu 2GB. VPS có thể bị OOM (exit 137)."
        confirm "Bạn vẫn muốn tiếp tục?" || return 1
        return 0
    fi
    log_success "RAM: ${ram_mb}MB"
    return 0
}

# -----------------------------------------------------------------------------
# Cổng dịch vụ
# -----------------------------------------------------------------------------
is_port_in_use() {
    local port=$1
    ss -tuln 2>/dev/null | grep -q ":$port " || \
    netstat -tuln 2>/dev/null | grep -q ":$port "
}

check_ports() {
    local failed=0
    if is_port_in_use "$OPENCLAW_GATEWAY_PORT"; then
        log_error "Cổng $OPENCLAW_GATEWAY_PORT đang được sử dụng."
        failed=1
    else
        log_success "Cổng $OPENCLAW_GATEWAY_PORT: Trống"
    fi
    if is_port_in_use "$OPENCLAW_BRIDGE_PORT"; then
        log_error "Cổng $OPENCLAW_BRIDGE_PORT đang được sử dụng."
        failed=1
    else
        log_success "Cổng $OPENCLAW_BRIDGE_PORT: Trống"
    fi
    return $failed
}

# -----------------------------------------------------------------------------
# Mạng (upstream / registry)
# -----------------------------------------------------------------------------
check_network() {
    log_info "Đang kiểm tra kết nối mạng..."
    if ! curl -fsS --connect-timeout 5 -o /dev/null https://github.com 2>/dev/null; then
        log_error "Không thể kết nối đến github.com. Kiểm tra mạng/VPN."
        return 1
    fi
    if ! curl -fsS --connect-timeout 5 -o /dev/null https://ghcr.io 2>/dev/null; then
        log_warn "Không thể kết nối đến ghcr.io (Container Registry). Pull image có thể thất bại."
        confirm "Tiếp tục thử?" || return 1
    fi
    log_success "Kết nối mạng OK"
    return 0
}

# -----------------------------------------------------------------------------
# Docker & Compose
# -----------------------------------------------------------------------------
check_docker() {
    if command -v docker &>/dev/null; then
        local ver
        ver=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "?")
        log_success "Docker đã cài: $ver"
        return 0
    fi
    log_info "Docker chưa được cài đặt. Script sẽ tự động cài."
    return 1
}

check_docker_compose() {
    if docker compose version &>/dev/null 2>&1; then
        log_success "Docker Compose: Đã có"
        return 0
    fi
    if command -v docker-compose &>/dev/null; then
        log_success "Docker Compose (standalone): Đã có"
        return 0
    fi
    log_info "Docker Compose chưa có. Sẽ được cài kèm Docker."
    return 1
}

check_ubuntu_version() { check_os "$@"; }

# -----------------------------------------------------------------------------
# Gói kiểm tra trước cài (nếu gọi từ module khác)
# -----------------------------------------------------------------------------
run_preinstall_checks() {
    check_os || return 1
    echo ""
    check_ram || return 1
    check_ports || return 1
    check_network || return 1
    check_docker
    check_docker_compose
    echo ""
    return 0
}
