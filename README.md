# Cài one-click trên Windows (không cần Docker Desktop)

Yêu cầu: Windows 10 22H2 hoặc Windows 11, CPU virtualization được bật trong BIOS/UEFI và có Internet.

1. Tải hoặc clone toàn bộ repository vào ổ đĩa Windows cục bộ.
2. Nhấp đúp `install-windows-wsl.bat` và chấp nhận quyền Administrator.
3. Nếu được yêu cầu restart Windows, restart rồi chạy lại file trên.
4. Bộ cài sẽ tự bật WSL2, cài Ubuntu 24.04, cài Docker Engine + Compose bên trong WSL, copy project vào `/opt/neonx-ai-agent`, kiểm tra Docker và mở trình tạo client.

Docker Desktop không được cài và không cần thiết. Có thể chạy lại file để nâng cấp an toàn:

- Nếu Docker đang hoạt động, bộ cài giữ nguyên phiên bản Docker thay vì tự nâng cấp.
- Trước khi đồng bộ, `clients/` và `.env.meta` được backup vào `/var/backups/neonx-ai-agent`.
- Khi nâng cấp, dữ liệu client và credentials trong WSL không bị xóa hoặc ghi đè.
- Source/script/template vẫn được đồng bộ có kiểm soát; các backup cũ hơn 30 ngày được tự dọn.
- Nếu đã có client, bộ cài không ép tạo client mới và không tự restart container. Chạy `./update-clients.sh` khi chủ động muốn áp dụng template mới.

Dữ liệu Linux nằm trong WSL; không unregister/xóa distro Ubuntu nếu muốn giữ dữ liệu container. Nên sao lưu distro WSL hoặc thư mục backup trước một nâng cấp lớn.

Sau khi cài, mở hệ thống thủ công bằng PowerShell hoặc Command Prompt:

```powershell
wsl -d Ubuntu-24.04 -u root -- bash -lc "cd /opt/neonx-ai-agent && ./create-client.sh"
```

> Endpoint mặc định `http://ai_gateway:20128/v1` chỉ hoạt động khi có container `ai_gateway` trên network `neonx-network`. Nếu không có gateway nội bộ, nhập URL API thực tế khi trình cài hỏi.

# Create new client trên Linux/macOS
sudo ./create-client.sh

# Update clients
sudo ./update-clients.sh

# Api Type
## Api env chấp nhận 3 giá trị:
openai-completions (OpenAI-compatible)
openai-responses
anthropic-messages (Claude)

# Docker iptables - Chặn port sau khi config xong

---

# 1. Kiểm tra Docker đang dùng iptables

Docker mặc định dùng iptables để quản lý traffic.

Kiểm tra:

```bash
sudo iptables -L DOCKER-USER -n
```

Nếu có chain `DOCKER-USER` thì sử dụng chain này để firewall container.

---

# 2. Chặn tất cả IP khác truy cập port

```bash
sudo iptables -A DOCKER-USER -p tcp --dport 18789 -j DROP
```

---

# 3. Mở lại port (1 là số thứ tự của port muốn mở lại)

```bash
sudo iptables -L DOCKER-USER -n --line-numbers
sudo iptables -D DOCKER-USER 1
```

---

# 3. Lưu rule sau khi reboot

Cài iptables persistent:

```bash
sudo apt install iptables-persistent -y
```

Lưu:

```bash
sudo netfilter-persistent save
```

Kiểm tra:

```bash
sudo iptables-save | grep 18789
```