#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# utils.sh — Banner, màu ANSI, logging, root, lệnh global openclaw
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Màu ANSI — biến idempotent (source nhiều lần không ghi đè)
# -----------------------------------------------------------------------------
[[ -z "${C_RESET+x}" ]] && C_RESET='\033[0m'
[[ -z "${C_BRAND+x}" ]] && C_BRAND='\033[94m'   # Xanh dương nhạt - DataOnline
[[ -z "${C_SUCCESS+x}" ]] && C_SUCCESS='\033[92m'  # Xanh lá
[[ -z "${C_WARNING+x}" ]] && C_WARNING='\033[93m'  # Vàng
[[ -z "${C_ERROR+x}" ]] && C_ERROR='\033[91m'   # Đỏ
[[ -z "${C_DIM+x}" ]] && C_DIM='\033[2m'

# -----------------------------------------------------------------------------
# Giao diện terminal
# -----------------------------------------------------------------------------
print_banner() {
    echo -e "${C_BRAND}"
    cat << 'BANNER'
█████   ██   █████  ██    ██   █   █ █      ██   █   █ █████
█   █  █  █    █   █  █  █  █  ██  █ █       █   ██  █ █                
█   █  ████    █   ████  █  █  █ █ █ █       █   █ █ █ ████
█   █  █  █    █   █  █  █  █  █  ██ █       █   █  ██ █    
█████  █  █    █   █  █   ██   █   █ █████  ███  █   █ █████
BANNER
    echo -e "${C_RESET}"
    echo -e "${C_BRAND}  DataOnline${C_RESET} ${C_DIM}·${C_RESET} OpenClaw Auto-Installer"
    echo -e "${C_DIM}  VPS • Hosting • Server tại Việt Nam${C_RESET}"
    echo ""
}

print_welcome() {
    echo -e "${C_BRAND}Chào mừng bạn đến với DataOnline OpenClaw Auto-Installer!${C_RESET}"
    echo ""
    echo -e "  ${C_BRAND}DataOnline${C_RESET} — VPS, Hosting, Server tại Việt Nam"
    echo -e "  Tham gia cộng đồng nhận hỗ trợ: ${C_BRAND}facebook.com/groups/openclawselfhosted${C_RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# Đọc từ terminal điều khiển (stdin có thể là pipe khi: curl … | sudo bash)
# -----------------------------------------------------------------------------
read_tty() {
    if [[ -r /dev/tty ]] && [[ -c /dev/tty ]]; then
        read -r "$@" < /dev/tty
    else
        read -r "$@"
    fi
}

# -----------------------------------------------------------------------------
# Quyền & xác nhận
# -----------------------------------------------------------------------------
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${C_ERROR}[LỖI] Script cần chạy với quyền root (sudo).${C_RESET}"
        echo -e "  Ví dụ: sudo $0"
        exit 1
    fi
}

# Logging — print_* là alias dùng trong các module lib/
log_info()    { echo -e "${C_BRAND}[INFO]${C_RESET} $*"; }
log_success() { echo -e "${C_SUCCESS}[OK]${C_RESET} $*"; }
log_warn()    { echo -e "${C_WARNING}[CẢNH BÁO]${C_RESET} $*"; }
log_error()   { echo -e "${C_ERROR}[LỖI]${C_RESET} $*"; }

# Aliases (dùng trong lib)
print_info()    { log_info "$@"; }
print_success() { log_success "$@"; }
print_warning() { log_warn "$@"; }
print_error()   { log_error "$@"; }
print_header()  { echo ""; echo -e "${C_BRAND}=== $* ===${C_RESET}"; }

confirm() {
    local prompt="${1:-Bạn có muốn tiếp tục?}"
    local default="${2:-y}"
    local reply
    if [[ "$default" == "y" ]]; then
        read_tty -r -p "$(echo -e "${C_BRAND}$prompt [Y/n]: ${C_RESET}")" reply
        reply="${reply:-y}"
    else
        read_tty -r -p "$(echo -e "${C_BRAND}$prompt [y/N]: ${C_RESET}")" reply
        reply="${reply:-n}"
    fi
    [[ "$reply" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# Cài symlink /usr/local/bin/openclaw → bản trong /opt/dataonline/...
# -----------------------------------------------------------------------------
OPENCLAW_INSTALLER_DIR="${OPENCLAW_INSTALLER_DIR:-/opt/dataonline/openclaw-installer}"
OPENCLAW_GLOBAL_CMD="${OPENCLAW_GLOBAL_CMD:-openclaw}"
OPENCLAW_GLOBAL_CMD_PATH="${OPENCLAW_GLOBAL_CMD_PATH:-}"

offer_install_global_command() {
    local script_dir="${1:?}"
    local installer_dir="${OPENCLAW_INSTALLER_DIR}"
    local cmd_name="${OPENCLAW_GLOBAL_CMD}"
    local link_path="${OPENCLAW_GLOBAL_CMD_PATH:-/usr/local/bin/${cmd_name}}"

    # Fallback: script_dir thiếu install.sh/lib → thử BASH_SOURCE[1]
    if [[ ! -f "${script_dir}/install.sh" ]] || [[ ! -d "${script_dir}/lib" ]]; then
        if [[ -n "${BASH_SOURCE[1]:-}" ]] && [[ -f "${BASH_SOURCE[1]}" ]]; then
            script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[1]}" 2>/dev/null || echo "${BASH_SOURCE[1]}")")"
        fi
    fi

    # Đã chạy từ bản trong installer_dir hoặc symlink đúng → thoát
    if [[ "$(realpath "$script_dir" 2>/dev/null || echo "$script_dir")" == "$(realpath "$installer_dir" 2>/dev/null || echo "$installer_dir")" ]]; then
        return 0
    fi
    if [[ -L "$link_path" ]] && [[ "$(readlink -f "$link_path" 2>/dev/null)" == "$(readlink -f "$installer_dir/install.sh" 2>/dev/null)" ]]; then
        return 0
    fi

    # Chỉ copy khi đủ install.sh + lib/ (vd. clone repo)
    if [[ ! -f "${script_dir}/install.sh" ]] || [[ ! -d "${script_dir}/lib" ]]; then
        return 0
    fi

    mkdir -p "$installer_dir"
    if ! cp "${script_dir}/install.sh" "$installer_dir/" || ! cp -r "${script_dir}/lib" "$installer_dir/"; then
        log_error "Không thể copy script vào ${installer_dir}."
        return 1
    fi
    if ! ln -sf "${installer_dir}/install.sh" "$link_path"; then
        log_error "Không thể tạo lệnh ${link_path}."
        return 1
    fi
}
