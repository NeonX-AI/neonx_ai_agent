"""Fusion MCP client toi gian — chi dung stdlib (container khong co requests).
Dung: copy file nay vao thu muc lam viec, `import fusion_mcp as fm`,
fm.initialize(), fm.run_script(script), fm.screenshot(...)."""
import json, urllib.request

BASE_URL = "http://host.docker.internal:27182"
HEADERS = {"Host": "127.0.0.1:27182", "Content-Type": "application/json",
           "Accept": "application/json, text/event-stream"}
_session_id, _req_id = None, 0

def _post(payload, timeout):
    global _session_id
    h = dict(HEADERS)
    if _session_id: h["Mcp-Session-Id"] = _session_id
    req = urllib.request.Request(f"{BASE_URL}/mcp", data=json.dumps(payload).encode(),
                                 headers=h, method="POST")
    r = urllib.request.urlopen(req, timeout=timeout)
    if r.headers.get("Mcp-Session-Id"): _session_id = r.headers["Mcp-Session-Id"]
    return r.read().decode()

def _parse(body):
    for line in body.splitlines():          # phong server tra SSE
        if line.startswith("data:"):
            try: return json.loads(line[5:].strip())
            except Exception: pass
    try: return json.loads(body)
    except Exception: return {"raw": body[:500]}

def initialize():
    global _req_id
    _req_id += 1
    body = _post({"jsonrpc": "2.0", "id": _req_id, "method": "initialize",
                  "params": {"protocolVersion": "2025-03-26", "capabilities": {},
                             "clientInfo": {"name": "agent", "version": "1.0"}}}, 60)
    j = _parse(body)
    if isinstance(j, dict) and "result" in j:
        _post({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}, 10)
    return j

def run_script(script, timeout=600):
    """Script PHAI co: def run(_context: str):"""
    global _req_id
    _req_id += 1
    body = _post({"jsonrpc": "2.0", "id": _req_id, "method": "tools/call",
                  "params": {"name": "fusion_mcp_execute",
                             "arguments": {"featureType": "script", "object": {"script": script}}}},
                 timeout)
    j = _parse(body)
    try: return json.loads(j["result"]["content"][0]["text"])
    except Exception: return j

def screenshot(out_path="fusion_viewport.png", timeout=120):
    """Chup viewport qua fusion_mcp_read queryType=screenshot. Tra so bytes da ghi."""
    import base64
    global _req_id
    _req_id += 1
    body = _post({"jsonrpc": "2.0", "id": _req_id, "method": "tools/call",
                  "params": {"name": "fusion_mcp_read",
                             "arguments": {"queryType": "screenshot"}}}, timeout)
    j = _parse(body)
    img = base64.b64decode(j["result"]["content"][0]["data"])   # PNG
    assert img[:4] == b"\x89PNG", "khong phai PNG"
    with open(out_path, "wb") as f:
        f.write(img)
    return len(img)
