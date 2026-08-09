---
name: "autocad"
description: "Draw 2D in AutoCAD via MCP: run AutoLISP/commands. Covers lines, circles, arcs, rectangles, polylines, hatch, dimensions, layers, blocks, viewport screenshots."
---

# AutoCAD — Draw 2D via MCP

Use this skill when user requests to **draw, create, edit, or read 2D models in AutoCAD**, or **capture viewport screenshots**. Agent controls AutoCAD by running AutoLISP / commands inside AutoCAD via MCP server. Client code: copy `scripts/autocad_mcp.py` to workspace then `import autocad_mcp as am`. Common 2D recipes: `references/recipes.md`.

## 0. OUTPUT RULE — MANDATORY

**After completing any draw/edit/create task: ALWAYS capture a viewport screenshot and send the image to user in reply.** Don't just say "done" — user wants to see the result. Zoom extents (or zoom to the drawn region) right before capture so the model fits the frame; capture additional views if needed.

## 1. Prerequisites

- AutoCAD is open on user's machine and the MCP server add-in is running (default `http://localhost:8000`, Streamable HTTP). From container → use `host.docker.internal`.
- Not running: ask user to start the AutoCAD MCP add-in, then verify with a quick read/`tools/list` call before concluding it's hung.
- Quick reachability check from host: `lsof -nP -iTCP:8000 -sTCP:LISTEN`. From container: `curl -s -m5 -o /dev/null -w '%{http_code}' http://host.docker.internal:8000/mcp`.

## 2. MCP Connection (wrong sequence = errors)

**Connection Details:**
- **URL**: `http://host.docker.internal:8000/mcp`
- **Headers**:
  - `Host: 127.0.0.1:8000`
  - `Content-Type: application/json`
  - `Accept: application/json, text/event-stream`

**Handshake Sequence:**
1. Send `initialize` request (protocolVersion `2025-03-26`)
2. Extract `Mcp-Session-Id` from response headers
3. Send `notifications/initialized` (NO `id` field - this is a notification)
4. Include session header in all subsequent requests

**DISCOVER TOOLS FIRST — server tool names are not fixed.** Before drawing, call `tools/list` (client: `am.list_tools()`) to see exactly which tools this server exposes and their `inputSchema`. Then call the right tool by name. Typical roles to look for:
- an **execute/run** tool → run AutoLISP or send commands (this is how you draw)
- a **read/inspect** tool → read entities, layers, extents, and **screenshot**
- an **update** tool → undo/redo

Use client from `scripts/autocad_mcp.py` (stdlib `urllib` only — container has NO requests/pip). It auto-discovers the execute tool + argument name via `am.run_lisp(code)`, but prefer explicit `am.call_tool(name, args)` once you've read `tools/list`.

## 2b. Viewport Screenshot — MANDATORY AFTER DRAWING

Find the screenshot/read tool via `tools/list`, then capture to a PNG and send it as a message attachment. Zoom extents first so the drawing fits the frame. If the server has no screenshot tool, ask the user for an image or describe the result precisely — never claim success without showing it.

## 3. AutoCAD Drawing Rules

- **Units are drawing units** — AutoCAD has no fixed unit; confirm the drawing's unit (mm/cm/m) with the user or `INSUNITS` before assuming dimensions. Default to the user's stated unit.
- Prefer **AutoLISP** (`command`/`entmake`) for drawing; it is the most portable way to drive AutoCAD through MCP.
- Common entry: `(command "_.LINE" "0,0" "100,0" "")` style, or `entmake` for precise entities.
- Errors come back in the tool result — read them to debug, don't guess.
- End each script by zooming to the result (e.g. `(command "_.ZOOM" "_E")`) and print a SHORT summary.

## 4. Pitfalls — learned the hard way, don't repeat

1. **Tool names vary per server.** Never hardcode a tool name you haven't confirmed with `tools/list`. The Fusion skill's `fusion_mcp_execute` does NOT exist here.
2. **Units ambiguity.** AutoCAD drawing units are unitless; a "100" could be mm or m. Confirm `INSUNITS` / ask the user before drawing dimensioned geometry.
3. **Coordinate system.** WCS vs UCS: `command` uses current UCS. For absolute placement, work in WCS or set UCS first.
4. **Command echoes & prompts.** Some servers wait for command-line input; terminate commands with an empty string `""` or `nil`/`ENTER` to avoid hangs.
5. **Timeout & testing:** client timeout ≥ estimated time (heavy regen → 600s). ALWAYS test 3–5 entities before a large batch.
6. **Stale selection sets:** after edits, re-select entities instead of reusing old handles/entity names.
7. **Large output truncation:** don't print huge entity dumps through the execute tool's stdout — query selectively. For images use the screenshot/read tool, not stdout base64.
8. **Regen for display:** after drawing, run `REGEN`/`REGENALL` (and zoom) so the screenshot reflects the new geometry.

## 5. Pre-run Checklist

- [ ] Server reachable (`tools/list` returns tools)?
- [ ] Confirmed drawing unit (mm/cm/m) with user or `INSUNITS`?
- [ ] Discovered the execute tool + its argument name?
- [ ] Client timeout large enough (600s for heavy work)?
- [ ] Test small (3 entities) before large batch?
- [ ] Terminate commands with `""` to avoid prompt hangs?
- [ ] Regen + zoom extents before screenshot?
- [ ] **Task complete → capture screenshot + send image to user**
