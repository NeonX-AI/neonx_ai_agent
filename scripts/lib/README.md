# Lib — module Bash

<!-- SPDX-License-Identifier: MIT -->
<!-- Copyright (c) 2026 DataOnline. DataOnline OpenClaw Auto-Installer. -->

Các file trong **`scripts/lib/`** được `source` từ **`scripts/install.sh`**. Không gọi trực tiếp từng file (trừ khi bạn biết rõ thứ tự `source` và phụ thuộc).

**Liên kết:** [Scripts](../README.md) · [README gốc](../../README.md)

---

## Bảng module

| File | Vai trò |
|------|---------|
| `utils.sh` | ANSI, banner, `log_*` / `print_*`, `check_root`, `confirm`, cài `openclaw` |
| `checks.sh` | `check_os`, `check_ram`, `check_ports`, `check_network`, `check_docker`, `run_preinstall_checks` |
| `install-core.sh` | `install_docker`, `setup_install_dir`, `setup_docker_compose`, `start_openclaw`, **`do_install`** |
| `ufw.sh` | `configure_ufw` — cổng 22, 18789, 18790 |
| `cli.sh` | **`do_openclaw_cli`** — menu lệnh trong container |
| `status.sh` | **`do_status`** — tổng hợp trạng thái |
| `uninstall.sh` | **`do_uninstall`** — gỡ `/opt/dataonline/openclaw` |

## Quy ước đặt tên

| Tiền tố | Ý nghĩa | Ví dụ |
|---------|---------|--------|
| `do_` | Hành động menu / luồng chính | `do_install`, `do_status` |
| `check_` | Kiểm tra điều kiện | `check_ram`, `check_os` |

Hằng số, màu và đường dẫn dùng chung: **`utils.sh`**.
