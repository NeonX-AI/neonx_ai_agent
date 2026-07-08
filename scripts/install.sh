#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# install.sh — Entry: menu chính, nạp lib/
# -----------------------------------------------------------------------------

# curl … | bash không set BASH_SOURCE[0] như file: lấy mặc định trước khi bật -u
_raw_install="${BASH_SOURCE[0]:-}"

# -----------------------------------------------------------------------------
# One-liner: chỉ có install.sh trên stdin → tải tarball repo rồi exec bản đầy đủ
# -----------------------------------------------------------------------------
_bootstrap_from_github() {
    local repo branch work root
    repo="${DATAONLINE_INSTALLER_REPO:-dataonlinevn/openclaw_self_hosted_scripts}"
    branch="${DATAONLINE_INSTALLER_BRANCH:-main}"
    work="$(mktemp -d)"
    if ! curl -fsSL "https://codeload.github.com/${repo}/tar.gz/${branch}" | tar -xz -C "${work}"; then
        rm -rf "${work}"
        echo "[LỖI] Không tải được gh:${repo} (nhánh ${branch}). Kiểm tra mạng." >&2
        echo "      Thử: git clone https://github.com/${repo}.git && cd openclaw_self_hosted_scripts && sudo ./scripts/install.sh" >&2
        exit 1
    fi
    root="$(find "${work}" -mindepth 1 -maxdepth 1 -type d | head -1)"
    if [[ -z "${root}" ]] || [[ ! -f "${root}/scripts/lib/utils.sh" ]]; then
        rm -rf "${work}"
        echo "[LỖI] Giải nén thiếu scripts/lib/ (repo ${repo})." >&2
        exit 1
    fi
    # Giữ thư mục tạm sau exec (one-liner); có thể xóa tay trong /tmp nếu cần
    exec bash "${root}/scripts/install.sh" "$@"
}

set -euo pipefail

# -----------------------------------------------------------------------------
# Đường dẫn script (symlink openclaw → …/install.sh; có lib/ cùng thư mục)
# -----------------------------------------------------------------------------
SCRIPT_DIR=""
if [[ -n "${_raw_install}" && -f "${_raw_install}" ]]; then
    SCRIPT_PATH="$(readlink -f "${_raw_install}" 2>/dev/null || realpath "${_raw_install}" 2>/dev/null || echo "${_raw_install}")"
    if [[ -n "${SCRIPT_PATH}" && -f "${SCRIPT_PATH}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
    fi
fi

if [[ -z "${SCRIPT_DIR}" ]] || [[ ! -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    _bootstrap_from_github "$@"
fi

LIB_DIR="${SCRIPT_DIR}/lib"

# -----------------------------------------------------------------------------
# Nạp lib/ (utils → checks → UFW/status/uninstall → cài đặt → CLI)
# -----------------------------------------------------------------------------
# shellcheck source=lib/utils.sh
source "${LIB_DIR}/utils.sh"
# shellcheck source=lib/checks.sh
source "${LIB_DIR}/checks.sh"
# shellcheck source=lib/ufw.sh
source "${LIB_DIR}/ufw.sh"
# shellcheck source=lib/status.sh
source "${LIB_DIR}/status.sh"
# shellcheck source=lib/uninstall.sh
source "${LIB_DIR}/uninstall.sh"
# shellcheck source=lib/install-core.sh
source "${LIB_DIR}/install-core.sh"
# shellcheck source=lib/cli.sh
source "${LIB_DIR}/cli.sh"

# -----------------------------------------------------------------------------
# Menu & luồng chính
# -----------------------------------------------------------------------------
print_main_menu() {
    echo ""
    echo -e "${C_BRAND}═══════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BRAND}  DATAONLINE${C_RESET} ${C_DIM}|${C_RESET} Menu chính"
    echo -e "${C_BRAND}═══════════════════════════════════════════════════${C_RESET}"
    echo ""
    echo "  1) Cài đặt mới"
    echo -e "     ${C_DIM}Cài OpenClaw lần đầu hoặc cài lại (Docker, cổng 18789/18790, UFW)${C_RESET}"
    echo ""
    echo "  2) Kiểm tra trạng thái"
    echo -e "     ${C_DIM}Xem Docker, cổng, RAM, UFW và health — dùng sau khi cài hoặc khi gỡ lỗi${C_RESET}"
    echo ""
    echo "  3) Cấu hình OpenClaw (CLI)"
    echo -e "     ${C_DIM}Onboard, đặt model, kênh chat (Telegram), duyệt pairing, chỉnh config${C_RESET}"
    echo ""
    echo "  4) Gỡ bỏ"
    echo -e "     ${C_DIM}Xóa OpenClaw và toàn bộ dữ liệu tại /opt/dataonline/openclaw (không hoàn tác)${C_RESET}"
    echo ""
    echo "  5) Liên hệ hỗ trợ"
    echo -e "     ${C_DIM}Group Facebook, Telegram, Zalo, Hotline DataOnline${C_RESET}"
    echo ""
    echo "  0) Thoát"
    echo ""
}

print_support_info() {
    print_header "LIÊN HỆ HỖ TRỢ DATAONLINE"
    echo ""
    echo -e "  ${C_BRAND}Group Facebook (Trọng tâm):${C_RESET} https://www.facebook.com/groups/openclawselfhosted"
    echo -e "  ${C_BRAND}Telegram:${C_RESET} https://t.me/DataOnlineVN"
    echo -e "  ${C_BRAND}Zalo:${C_RESET} https://zalo.me/dataonline"
    echo -e "  ${C_BRAND}Hotline:${C_RESET} 0356958688"
    echo ""
    echo -e "  ${C_DIM}Tham gia Group Facebook để nhận hỗ trợ và xây dựng cộng đồng!${C_RESET}"
    echo ""
}

main() {
    local choice
    print_banner
    print_welcome
    check_root
    offer_install_global_command "$SCRIPT_DIR"

    while true; do
        print_main_menu
        read_tty -rp "$(echo -e "${C_BRAND}Chọn tùy chọn [0-5]: ${C_RESET}")" choice
        case "${choice}" in
            1)
                do_install
                ;;
            2)
                do_status
                ;;
            3)
                do_openclaw_cli
                ;;
            4)
                do_uninstall
                ;;
            5)
                print_support_info
                ;;
            0)
                echo -e "${C_BRAND}Cảm ơn bạn đã sử dụng DataOnline OpenClaw Auto-Installer!${C_RESET}"
                exit 0
                ;;
            *)
                print_warning "Lựa chọn không hợp lệ. Vui lòng chọn 0-5."
                ;;
        esac
    done
}

main "$@"
