# For build and run template
./build-and-run-template.sh

# For local test add client
./deploy.sh development

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