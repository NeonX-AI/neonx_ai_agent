# OpenClaw Message Listener — OpenClaw Plugin

Plugin to listen to all messages sent to OpenClaw, log them for monitoring, and block sensitive requests. This middleware captures both incoming user messages and outgoing assistant responses, while filtering out requests related to system internals, models, or security-sensitive topics.

## Features

- **Log Incoming Messages**: Captures all user messages before agent processing
- **Log Outgoing Responses**: Captures all assistant responses after processing
- **Block Sensitive Requests**: Blocks queries about system prompts, models, configs, and other internal details
- **Session Tracking**: Records session keys, user IDs, and agent IDs
- **Message Truncation**: Prevents extremely long messages from overwhelming logs
- **Timestamp Logging**: Records exact timestamps for all messages
- **Multi-language Support**: Provides responses in Vietnamese and English

## Structure

```
openclaw-message-listener/
├── package.json            # OpenClaw plugin metadata
├── openclaw.plugin.json    # Plugin manifest
├── README.md               # Documentation
└── src/
    └── index.js            # Plugin entry + hooks
```

## Installation

### 1. Copy plugin into server

Clone or copy this repository to your OpenClaw server:

```bash
git clone https://github.com/NeonX-AI/neonx_ai_agent.git
```

### 2. Configure OpenClaw

Add to your `openclaw.json` (typically located in `agent_data/openclaw.json` of Docker container):

```json
{
  "plugins": {
    "load": {
      "paths": ["/home/node/.openclaw/workspace/neonx_ai_agent/openclaw-message-listener"]
    }
  }
}
```

Or use a relative path if the workspace is mounted:

```json
{
  "plugins": {
    "load": {
      "paths": ["./openclaw-message-listener"]
    }
  }
}
```

### 3. Restart OpenClaw

```bash
docker compose restart openclaw
```

The plugin will automatically load when OpenClaw starts.

## Hook API

- `before_agent_run` — captures incoming user messages and blocks sensitive requests
- `after_agent_run` — captures outgoing assistant responses

## Blocking Patterns

The plugin blocks messages containing:
- Model names (GPT, Claude, Gemini, etc.)
- Configuration references (openclaw.json, .env, API keys)
- System prompts or instructions
- Execution commands
- Memory/session information
- Backend infrastructure details
- Questions about system architecture

## Log Format

The plugin logs structured information including:
- Timestamp (ISO format)
- Session key
- User ID
- Agent ID
- Message content (truncated to 200 characters)
- Total message count in the conversation

## Use Cases

- Monitoring conversation flow
- Auditing user interactions
- Preventing system probing
- Debugging agent responses
- Collecting analytics on user queries

## License

Private — NeonX AI
