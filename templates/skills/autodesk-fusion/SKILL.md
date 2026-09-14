---
name: "autodesk-fusion"
description: "Draw 2D/3D in Autodesk Fusion 360 via MCP: run Python API scripts. Covers sketches, extrude, revolve, holes, fillets, patterns, viewport screenshots."
---

# Autodesk Fusion — Draw 2D/3D via MCP

Use this skill when user requests to **draw, create, edit, or read 2D/3D models in Autodesk Fusion 360**, or **capture viewport screenshots**. Agent controls Fusion by running Python scripts (Fusion API) inside Fusion via MCP server. Client code: copy `scripts/fusion_mcp.py` to workspace then `import fusion_mcp as fm`. Full 2D/3D recipes: `references/recipes.md`.

## 0. OUTPUT RULE — MANDATORY

**After completing any draw/edit/create task: ALWAYS capture viewport screenshot (section 2b) and send the image to user in reply.** Don't just say "done" — user wants to see the result. Call `app.activeViewport.fit()` in script right before capture to fit model in frame; rotate/capture additional angles if needed.

## 1. Prerequisites

- Fusion 360 is open on user's machine, MCP server add-in is running (default `http://localhost:27182`, Streamable HTTP). From container → use `host.docker.internal`.
- Not running: ask user to enable add-in (Utilities → Add-ins), verify with quick read script before concluding it's hung.

## 2. MCP Connection (wrong sequence = errors)

**Connection Details:**
- **URL**: `http://host.docker.internal:27182/mcp`
- **Headers**: 
  - `Host: 127.0.0.1:27182`
  - `Content-Type: application/json`
  - `Accept: application/json, text/event-stream`

**Handshake Sequence:**
1. Send `initialize` request (protocolVersion `2025-03-26`)
2. Extract `Mcp-Session-Id` from response headers
3. Send `notifications/initialized` (NO `id` field - this is a notification)
4. Include session header in all subsequent requests

**Available Tools:**
- `fusion_mcp_execute` - run Python scripts
- `fusion_mcp_read` - read model + **screenshot**
- `fusion_mcp_update` - undo/redo

Use client from `scripts/fusion_mcp.py` (stdlib `urllib` only — container has NO requests/pip).

## 2b. Viewport Screenshot — FASTEST METHOD (verified)

```python
import fusion_mcp as fm
fm.initialize()
fm.screenshot("fusion_viewport.png")   # capture via fusion_mcp_read queryType=screenshot → PNG
```

Send PNG via `message` tool attachment. `queryType: "screenshot"`, optional `antiAliasing` (default true). **DO NOT** use `saveAsImageFile()` + print base64 via stdout — see pitfall 8.

## 3. Fusion Script Rules

- **MANDATORY** entry point: `def run(_context: str):`
- Internal units: **centimeters** (100mm = 10.0), or use `ValueInput.createByString("6 mm")`
- Boilerplate: `app = adsk.core.Application.get()`; `des = adsk.fusion.Design.cast(app.activeProduct)` (NOT `adsk.fusion.FusionDesign`); `root = des.rootComponent`
- Errors returned in `result.content[0].text` with `"success": false` → read to debug, don't guess
- End script: `app.activeViewport.fit()` + print SHORT summary (pitfall 8)

## 4. Pitfalls — learned the hard way, don't repeat

1. **"No target body found to cut or intersect!"** — normal plane is flipped. DO NOT use `setByTangentAtPoint()` on curved surfaces; use `adsk.core.Plane.create(origin_pt, normal_vec)` + `setByPlane(plane)` + explicitly set `participantBodies = [targetBody]`. Fallback: `setDistanceExtent(True,...)` then `(False,...)`.
2. **`setByNormalAtPoint` DOES NOT EXIST.** Need plane with custom normal → `setByPlane(adsk.core.Plane.create(point, normal))`.
3. **Hide auxiliary planes/sketches:** `ConstructionPlane.isVisible` is READ-ONLY → AttributeError. Use `obj.isLightBulbOn = False` (works for both planes and sketches). DO NOT delete planes/sketches that features reference — only hide, hide immediately in loop.
4. **Fusion overload:** hundreds of planes/sketches cause ALL scripts to timeout. Check `root.bRepBodies.count`, `root.sketches.count`, `root.constructionPlanes.count` first; too dirty → ask user to create new design.
5. **Timeout & testing:** client timeout ≥ estimated time (heavy work → 600s). ALWAYS test 3–5 objects before large batch. Quick read script to verify server alive before suspecting hang.
6. **Stale references:** after each feature cut, old `body`/`face` may be stale — re-fetch `root.bRepBodies.item(0)` in loop if strange errors occur.
7. **API names differ between versions:** encountered `addSymmetric` (correct: `addSymmetry`), `sk.dimensions` (correct: `sk.sketchDimensions`), `SketchPolygons` (doesn't exist). Before using new API, check with `dir(obj)` script.
8. **`fusion_mcp_execute` stdout TRUNCATED with large data** (~hundreds of KB): `print(base64 image)` loses all data, response becomes `{"message": "", "success": true}` → b64decode padding error. For viewport images: use `fm.screenshot()` (section 2b), don't go through script.

## 5. Pre-run Checklist

- [ ] Current design is clean? (check bRepBodies/sketches/planes counts)
- [ ] Client timeout large enough (600s for heavy work)
- [ ] Test small (3 objects) before large batch
- [ ] Cut direction fallback (True/False)
- [ ] Hide auxiliary objects (`isLightBulbOn = False`) in loop
- [ ] **Task complete → capture screenshot + send image to user**
