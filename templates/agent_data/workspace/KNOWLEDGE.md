# Knowledge Base

**INSTRUCTIONS FOR AGENT**: This file contains a list of available skills and knowledge. When the user requests a specific task:
1. Check the skills list below
2. If a matching skill exists → Read `skills/<skill-name>/SKILL.md` before proceeding
3. Follow the instructions in the skill file (connection, API, pitfalls, etc.)

## Skills (Special Capabilities)

**IMPORTANT**: Always check this list before performing any task.

### Available Skills:

- **autodesk-fusion**: Draw 2D/3D in Autodesk Fusion 360 via MCP
  - File: `skills/autodesk-fusion/SKILL.md`
  - When to use: User requests drawing, creating, or modifying 2D/3D models in Fusion 360
  - **QUICK CONNECTION INFO**:
    - **YOU CAN CONNECT** using `curl` command from within this container
    - URL: `http://host.docker.internal:27182/mcp`
    - Headers: `Host: 127.0.0.1:27182`, `Content-Type: application/json`, `Accept: application/json, text/event-stream`
    - Handshake: POST `initialize` → Extract `Mcp-Session-Id` from response headers → POST `notifications/initialized` (no `id` field)
    - Tools: `fusion_mcp_execute` (run Python), `fusion_mcp_read` (query info), `fusion_mcp_update` (modify params)
  - **EXAMPLE**: To initialize MCP connection:
    ```bash
    curl -X POST http://host.docker.internal:27182/mcp \
      -H "Host: 127.0.0.1:27182" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json, text/event-stream" \
      -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"openclaw","version":"1.0.0"}}}'
    ```
  - **READ NOW**: `skills/autodesk-fusion/SKILL.md` for complete connection and usage details

### How to Use Skills:

1. **When user requests a task**: Check the skills list above
2. **If a matching skill exists**: Read `skills/<skill-name>/SKILL.md` before proceeding
3. **Follow the instructions**: The skill will show how to connect, use APIs, and avoid pitfalls

## Instructions (Detailed Guides)

- **Autodesk Fusion 360 API**: `instructions/fusion-api-guide.md`
  - Connect to MCP server at `http://host.docker.internal:27182`
  - JSON-RPC protocol with session management
  - How to call `fusion_mcp_execute` tool with Python scripts

## How to Use

When user asks about a tool/API/integration:

1. Check if a corresponding skill exists in the list above
2. If yes → Read `skills/<skill-name>/SKILL.md`
3. If no → Check `instructions/` for information
4. Apply the knowledge to answer or perform the task

## Adding New Knowledge

To add new knowledge:

1. Create a `.md` file in `default-knowledge/instructions/` (on host)
2. Run `./update-clients.sh` or `./sync-knowledge.sh`
3. The file will be copied to `agent_data/instructions/` of all clients
