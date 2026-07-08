#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# ufw.sh — Mở cổng SSH + gateway/bridge, bật UFW nếu cần
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

PORTS=(22 18789 18790)

configure_ufw() {
    if ! command -v ufw &>/dev/null; then
        print_warning "UFW chưa được cài đặt. Đang cài đặt..."
        apt-get update -qq && apt-get install -y -qq ufw
    fi

    for port in "${PORTS[@]}"; do
        if ufw status | grep -q "${port}/"; then
            print_info "Cổng ${port} đã được mở."
        else
            ufw allow "${port}" 2>/dev/null || true
            print_info "Đã mở cổng ${port}"
        fi
    done

    if ufw status | grep -q "Status: active"; then
        print_info "UFW đã active."
    else
        print_info "Đang kích hoạt UFW..."
        ufw --force enable 2>/dev/null || true
    fi
    print_success "UFW đã được cấu hình (cổng: ${PORTS[*]})"
}
