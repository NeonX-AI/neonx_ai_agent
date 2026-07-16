# Luna Security Middleware — OpenClaw Plugin

Plugin bảo mật cho Luna (nhân viên tư vấn thời trang). Chạy native trong OpenClaw pipeline.

## Tính năng

- **Filter Input**: Chặn câu hỏi về model, AI, config, prompt, tools, memory...
- **Filter Output**: Redact thông tin kỹ thuật từ response (token, session ID, paths...)
- **Bypass**: Owner (user ID `2088229709`) chat thoải mái không bị filter
- **Agent-specific**: Chỉ áp dụng cho Luna agent (`shop-quan-ao`)

## Cấu trúc

```
luna-middleware/
├── package.json            # OpenClaw plugin metadata
├── openclaw.plugin.json    # Plugin manifest
├── README.md               # Tài liệu
└── src/
    └── index.js            # Plugin entry + hooks
```

## Cài đặt

### 1. Copy plugin vào server

Clone repo này lên server production:

```bash
git clone https://github.com/NeonX-AI/neonx_ai_agent.git
```

### 2. Cấu hình OpenClaw

Thêm vào `openclaw.json` (trong `agent_data/openclaw.json` của Docker container):

```json
{
  "plugins": {
    "load": {
      "paths": ["/home/node/.openclaw/workspace/neonx_ai_agent/luna-middleware"]
    }
  }
}
```

Hoặc dùng relative path nếu workspace đã được mount:

```json
{
  "plugins": {
    "load": {
      "paths": ["./luna-middleware"]
    }
  }
}
```

### 3. Restart OpenClaw

```bash
docker compose restart openclaw
```

Plugin tự load khi OpenClaw khởi động.

## Deploy tự động

Plugin nằm trong repo → mỗi lần `git pull` + `docker compose restart` là tự cập nhật.

## Hook API

- `before_agent_run` — chặn input nhạy cảm, trả lời synthetic
- `message_sending` — filter/redact output trước khi gửi

## Patterns chặn

Model/AI, config/openclaw.json/.env, API key/token, system prompt, tools, cron, memory, session ID...

## License

Private — NeonX AI
