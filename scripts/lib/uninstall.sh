#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# uninstall.sh — compose down -v, xóa /opt/dataonline/openclaw
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

INSTALL_DIR="/opt/dataonline/openclaw"

do_uninstall() {
    local confirm
    print_header "GỠ BỎ OPENCLAW"
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        print_warning "Không tìm thấy thư mục cài đặt: ${INSTALL_DIR}"
        return 0
    fi

    read_tty -rp "Bạn có chắc muốn gỡ bỏ OpenClaw? Dữ liệu trong ${INSTALL_DIR} sẽ bị xóa. (y/N): " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        print_info "Đã hủy."
        return 0
    fi

    cd "${INSTALL_DIR}"
    docker compose down -v 2>/dev/null || true
    cd /
    rm -rf "${INSTALL_DIR}"
    print_success "Đã gỡ bỏ OpenClaw."
    print_info "Tham gia Group Facebook nếu cần hỗ trợ: https://www.facebook.com/groups/openclawselfhosted"
}
