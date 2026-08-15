---
name: "draw-cad"
description: "Unified CAD drawing orchestrator. Use when the user says use $draw-cad, asks to draw, create, edit, inspect, convert, or render CAD, or needs AutoCAD, Autodesk Fusion, DXF, STEP, STL, 3MF, implicit CAD, or CAD Viewer. Routes the task to the correct installed specialist skill and requires reading that skill before acting."
---

# Draw CAD — Unified CAD Orchestrator

Use this as the single entry point for CAD work. Convert the user's request into a concrete CAD workflow, select the correct installed specialist skill, read its `SKILL.md`, and follow it. Do not invent connection URLs, tool names, file formats, or procedures.

## Capability Contract — Mandatory

You **can directly create and edit CAD** through the installed specialist skills and their MCP connections. Do not answer that you are only a text assistant, cannot access CAD functions, or require the user to draw manually before attempting this workflow.

An explicit request to use `draw-cad` or `$draw-cad` means: read this skill, route to a specialist, check the corresponding MCP connection, and execute the drawing. If the server is unavailable, report the exact failed reachability/handshake check and tell the user which application/add-in to start. Lack of a tool already exposed in the chat context is not proof that CAD is unavailable; follow the specialist skill's client/connection procedure first.

## Invocation

Users may invoke this skill with requests such as:

- `Use $draw-cad to draw this part in AutoCAD.`
- `Use $draw-cad to model this bracket in Fusion.`
- `Use $draw-cad to generate a DXF from these dimensions.`

Treat an explicit `$draw-cad` invocation as a requirement to execute this routing workflow.

## Routing

Choose the primary target from the request and read the corresponding project skill before acting:

| User intent | Required specialist skill ID |
|---|---|
| Draw, edit, inspect, or screenshot 2D geometry directly in AutoCAD | `autocad` |
| Create, edit, inspect, or screenshot a model directly in Autodesk Fusion | `autodesk-fusion` |
| Generate, edit, inspect, or validate a `.dxf` artifact | `dxf` |
| Generate STEP, STL, 3MF, GLB, or general parametric CAD | `cad` |
| Generate code-defined implicit CAD | `implicit-cad` |
| Preview CAD or produce a live visual review | `cad-viewer` |
| Prepare or validate fabrication-specific G-code | `gcode` |
| Find a standard purchasable STEP component | `step-parts` |
| Prepare geometry for SendCutSend | `sendcutsend` |
| Robot descriptions or simulation | `urdf`, `srdf`, or `sdf` |

Resolve `<skill-id>/SKILL.md` from the first existing skill root below, then read it before acting:

1. `skills/` (OpenClaw workspace/runtime)
2. `.agents/skills/` (Codex project discovery)
3. `$CODEX_HOME/skills/` (Codex home)

Do not assume `.agents/skills/` is the only valid root.

## Default Decisions

1. If the user explicitly names AutoCAD or Fusion, use that application skill.
2. If the user requests a file format, route by output format.
3. If the user asks only to “draw CAD” and the target application or format materially affects the result, ask one concise clarification question.
4. If a direct application operation also needs an exported artifact, use the application skill first and then the relevant artifact skill.
5. Use `cad-viewer` after file generation when visual review is useful and the specialist workflow calls for it.

## Known Application Connections

These values are fallback orientation only. The selected specialist skill remains the source of truth.

- AutoCAD MCP from Docker: `http://host.docker.internal:8000/mcp`
- Autodesk Fusion MCP from Docker: resolve and read the `autodesk-fusion` specialist skill for its current endpoint and protocol.

Never claim an application is connected merely because its URL is known. Perform the specialist skill's reachability check and MCP handshake.

## Execution Contract

1. Identify target application and required output.
2. Read every specialist `SKILL.md` needed for the workflow.
3. Confirm dimensions, units, and ambiguous geometry before destructive or expensive work.
4. Discover MCP tools before calling them; tool names can vary.
5. Test a small operation before a large batch when the specialist skill requires it.
6. Validate the produced model or file.
7. Capture or render a final view when supported; for direct AutoCAD/Fusion drawing, follow the specialist screenshot requirement.
8. Report the output path, application used, validation result, and any remaining limitation.

## Prohibitions

- Do not substitute generic shell drawing logic when a matching specialist skill exists.
- Do not guess MCP URLs or hardcode unverified MCP tool names.
- Do not say that no CAD skill exists before checking both `.agents/skills` and `$CODEX_HOME/skills`.
- Do not report success without validating the operation or artifact.
