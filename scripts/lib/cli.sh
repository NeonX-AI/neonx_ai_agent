#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer.
#
# cli.sh — Menu điều khiển OpenClaw CLI (onboard, models, pairing, config…)
# -----------------------------------------------------------------------------

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/dataonline/openclaw}"

# -----------------------------------------------------------------------------
# Docker: compose run mặc định xin TTY — thiếu TTY phải dùng -T (tắt pseudo-TTY)
# -----------------------------------------------------------------------------
_run_cli() {
    cd "${INSTALL_DIR}"
    if [[ -t 0 ]] && [[ -t 1 ]]; then
        docker compose exec -it openclaw-gateway node dist/index.js "$@"
    else
        docker compose exec -i -T openclaw-gateway node dist/index.js "$@"
    fi
}

# -----------------------------------------------------------------------------
# Menu CLI (cây con)
# -----------------------------------------------------------------------------
do_openclaw_cli() {
    local choice
    if [[ ! -f "${INSTALL_DIR}/docker-compose.yml" ]]; then
        echo "Chưa cài đặt OpenClaw. Vào menu chính → 1) Cài đặt mới." >&2
        return 1
    fi
    cd "${INSTALL_DIR}"
    if ! docker compose ps -q openclaw-gateway 2>/dev/null | grep -q .; then
        echo "Gateway chưa chạy. Vào menu chính → 1) Cài đặt mới, hoặc chạy: cd ${INSTALL_DIR} && docker compose up -d" >&2
        return 1
    fi

    while true; do
        echo ""
        echo -e "${C_BRAND}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BRAND}  DATAONLINE${C_RESET} ${C_DIM}|${C_RESET} Cấu hình OpenClaw (CLI)"
        echo -e "${C_BRAND}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}1) Onboard${C_RESET}"
        echo -e "     ${C_DIM}Wizard từng bước: API key (Gemini/OpenAI...), model mặc định, kênh chat (Telegram)${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}2) Models${C_RESET}"
        echo -e "     ${C_DIM}Xem model hiện tại, đặt model mặc định, thêm API key${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}3) Pairing${C_RESET}"
        echo -e "     ${C_DIM}Duyệt tin nhắn trực tiếp (DM): user nhắn bot Telegram/Discord lần đầu cần approve${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}4) Devices${C_RESET}"
        echo -e "     ${C_DIM}Duyệt thiết bị trình duyệt kết nối Web UI${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}5) Config${C_RESET}"
        echo -e "     ${C_DIM}Xem/sửa cấu hình (model, kênh, groupPolicy, v.v.)${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}6) Công cụ khác${C_RESET}"
        echo -e "     ${C_DIM}doctor, directory, channels, plugins, logs, khởi động lại gateway, tui, status${C_RESET}"
        echo ""
        echo -e "  ${C_BRAND}0) Quay lại menu chính${C_RESET}"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}Chọn [0-6]: ${C_RESET}")" choice

        case "${choice}" in
            0) return 0 ;;
            1) _cli_onboard ;;
            2) _cli_models ;;
            3) _cli_pairing ;;
            4) _cli_devices ;;
            5) _cli_config ;;
            6) _cli_other ;;
            *) print_warning "Chọn 0-6" ;;
        esac
    done
}

_cli_onboard() {
    echo ""
    echo -e "${C_DIM}Chạy: onboard (wizard cấu hình từng bước)${C_RESET}"
    # Tắt web search trước onboard → giảm RAM (tránh OOM / exit 137)
    (cd "${INSTALL_DIR}" && docker compose exec -T openclaw-gateway node dist/index.js config set tools.web.search.enabled false 2>/dev/null) || true
    # Onboard trong service openclaw-cli — tránh 2 tiến trình Node trong một container gateway
    cd "${INSTALL_DIR}"
    if ! [[ -t 0 ]] || ! [[ -t 1 ]]; then
        print_warning "Thiếu TTY: onboard cần terminal tương tác. SSH: ssh -t user@host hoặc máy ảo/console có TTY."
    fi
    if [[ -t 0 ]] && [[ -t 1 ]]; then
        docker compose run --rm -it openclaw-cli onboard
    else
        # run: không thêm -T → Docker vẫn cấp TTY mặc định → lỗi "not a TTY"
        docker compose run --rm -i -T openclaw-cli onboard
    fi
}

_cli_models() {
    local c m
    while true; do
        echo ""
        echo -e "${C_BRAND}  Models${C_RESET}"
        echo "  ├── 1) status    — Xem model hiện tại, trạng thái auth"
        echo "  ├── 2) list      — Liệt kê model có sẵn"
        echo "  ├── 3) set       — Đặt model mặc định (vd: google/gemini-1.5-flash)"
        echo "  ├── 4) auth      — Thêm/cấu hình API key"
        echo "  └── 0) Quay lại"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}  Chọn [0-4]: ${C_RESET}")" c
        case "${c}" in
            0) break ;;
            1) _run_cli models status ;;
            2) _run_cli models list ;;
            3)
                echo -e "  ${C_DIM}Ví dụ: google/gemini-1.5-flash | openai/gpt-4o | anthropic/claude-sonnet-4-5${C_RESET}"
                read_tty -rp "  Nhập model: " m
                [[ -n "$m" ]] && _run_cli models set "$m"
                ;;
            4) _run_cli models auth add ;;
            *) print_warning "Chọn 0-4" ;;
        esac
    done
}

_cli_pairing() {
    local c ch code
    while true; do
        echo ""
        echo -e "${C_BRAND}  Pairing (DM Telegram, Discord…)${C_RESET}"
        echo "  ├── 1) list      — Xem request DM chờ duyệt"
        echo "  ├── 2) approve   — Duyệt DM (cần kênh + code từ app)"
        echo "  └── 0) Quay lại"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}  Chọn [0-2]: ${C_RESET}")" c
        case "${c}" in
            0) break ;;
            1) _run_cli pairing list ;;
            2)
                read_tty -rp "  Kênh (vd: telegram): " ch
                read_tty -rp "  Mã pairing (từ Telegram/Discord): " code
                if [[ -n "$ch" && -n "$code" ]]; then
                    _run_cli pairing approve "$ch" "$code"
                else
                    print_warning "Cần nhập kênh và mã"
                fi
                ;;
            *) print_warning "Chọn 0-2" ;;
        esac
    done
}

_cli_devices() {
    local c id
    while true; do
        echo ""
        echo -e "${C_BRAND}  Devices (trình duyệt)${C_RESET}"
        echo "  ├── 1) list      — Xem pending + đã ghép"
        echo "  ├── 2) approve   — Duyệt pending (Request ID = UUID ở cột Request, không phải chuỗi Device)"
        echo "  ├── 3) approve   — Duyệt pending mới nhất (--latest)"
        echo "  └── 0) Quay lại"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}  Chọn [0-3]: ${C_RESET}")" c
        case "${c}" in
            0) break ;;
            1) _run_cli devices list ;;
            2)
                echo -e "  ${C_DIM}Ví dụ Request ID: 25042d97-86ac-4fe4-9737-288a8e129f9b (không dùng cột Device).${C_RESET}"
                read_tty -rp "  Request ID: " id
                [[ -n "$id" ]] && _run_cli devices approve "$id"
                ;;
            3) _run_cli devices approve --latest ;;
            *) print_warning "Chọn 0-3" ;;
        esac
    done
}

_cli_config() {
    local c path val
    while true; do
        echo ""
        echo -e "${C_BRAND}  Config${C_RESET}"
        echo "  ├── 1) get       — Xem giá trị (vd: agents.defaults.model.primary)"
        echo "  ├── 2) set       — Gán giá trị (vd: channels.telegram.groupPolicy open)"
        echo "  ├── 3) validate  — Kiểm tra config"
        echo "  └── 0) Quay lại"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}  Chọn [0-3]: ${C_RESET}")" c
        case "${c}" in
            0) break ;;
            1)
                read_tty -rp "  Path (vd: agents.defaults.model.primary): " path
                [[ -n "$path" ]] && _run_cli config get "$path"
                ;;
            2)
                read_tty -rp "  Path: " path
                read_tty -rp "  Giá trị: " val
                if [[ -n "$path" && -n "$val" ]]; then
                    _run_cli config set "$path" "$val"
                fi
                ;;
            3) _run_cli config validate ;;
            *) print_warning "Chọn 0-3" ;;
        esac
    done
}

_cli_other() {
    local c ch plug
    while true; do
        echo ""
        echo -e "${C_BRAND}  Công cụ khác${C_RESET}"
        echo "  ├──  1) doctor             — Chẩn đoán và cảnh báo cấu hình"
        echo "  ├──  2) directory self     — Lấy Chat ID (nhắn bot Telegram rồi chạy lệnh này)"
        echo "  ├──  3) channels status    — Trạng thái kênh (Telegram, zalouser...)"
        echo "  ├──  4) channels login     — Đăng nhập kênh (vd: zalouser cần quét QR)"
        echo "  ├──  5) plugins list       — Liệt kê plugin đã cài"
        echo "  ├──  6) plugins install     — Cài plugin (vd: @openclaw/zalouser)"
        echo "  ├──  7) logs --follow       — Xem log gateway theo thời gian thực"
        echo "  ├──  8) gateway restart    — Khởi động lại gateway (áp dụng thay đổi config)"
        echo "  ├──  9) tui                — Chat với agent trong terminal"
        echo "  ├── 10) status             — Trạng thái gateway"
        echo "  └──  0) Quay lại"
        echo ""
        read_tty -rp "$(echo -e "${C_BRAND}  Chọn [0-10]: ${C_RESET}")" c
        case "${c}" in
            0) break ;;
            1) _run_cli doctor ;;
            2) _run_cli directory self --channel telegram ;;
            3) _run_cli channels status ;;
            4)
                read_tty -rp "  Kênh (vd: zalouser, telegram): " ch
                [[ -n "$ch" ]] && _run_cli channels login --channel "$ch"
                ;;
            5) _run_cli plugins list ;;
            6)
                read_tty -rp "  Plugin (vd: @openclaw/zalouser): " plug
                [[ -n "$plug" ]] && _run_cli plugins install "$plug"
                ;;
            7) _run_cli logs --follow ;;
            8)
                echo -e "  ${C_DIM}Đang khởi động lại gateway...${C_RESET}"
                (cd "${INSTALL_DIR}" && docker compose restart openclaw-gateway)
                print_success "Gateway đã khởi động lại."
                ;;
            9) _run_cli tui ;;
            10) _run_cli status ;;
            *) print_warning "Chọn 0-10" ;;
        esac
    done
}
