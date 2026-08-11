"""AutoCAD MCP client toi gian — chi dung stdlib (container khong co requests).
Dung: copy file nay vao thu muc lam viec, `import autocad_mcp as am`,
am.initialize(), am.list_tools(), am.call_tool(name, args), am.run_lisp(code).

KHONG biet truoc ten tool cua server -> LUON goi am.list_tools() truoc de
xem server nay cung cap nhung tool gi, roi moi goi dung tool do.
"""
import json, urllib.request

BASE_URL = "http://host.docker.internal:8000"
HEADERS = {"Host": "127.0.0.1:8000", "Content-Type": "application/json",
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

def list_tools():
    """Bac 1: hoi server co nhung tool gi. Tra ve list [{name, description, inputSchema}]."""
    global _req_id
    _req_id += 1
    body = _post({"jsonrpc": "2.0", "id": _req_id, "method": "tools/list", "params": {}}, 60)
    j = _parse(body)
    try: return j["result"]["tools"]
    except Exception: return j

def call_tool(name, arguments, timeout=600):
    """Goi mot tool bat ky theo ten + arguments (da biet tu list_tools)."""
    global _req_id
    _req_id += 1
    body = _post({"jsonrpc": "2.0", "id": _req_id, "method": "tools/call",
                  "params": {"name": name, "arguments": arguments}}, timeout)
    j = _parse(body)
    # nhieu server tra ket qua nhu JSON string trong content[0].text
    try:
        txt = j["result"]["content"][0]["text"]
        try: return json.loads(txt)
        except Exception: return txt
    except Exception: return j

def find_exec_tool():
    """Tim tool dung de chay script/lenh AutoCAD (AutoLISP/command). Tra ve ten tool."""
    tools = list_tools()
    if not isinstance(tools, list): return None
    keys = ("lisp", "script", "execute", "command", "eval", "run", "autolisp", "send")
    for t in tools:
        n = (t.get("name") or "").lower()
        if any(k in n for k in keys):
            return t.get("name")
    return tools[0].get("name") if tools else None

def run_lisp(code, timeout=600, tool=None, arg_key=None):
    """Chay doan AutoLISP/command trong AutoCAD.
    Tu dong doan tool + ten tham so (vi moi server dat ten khac nhau).
    Neu biet chinh xac, truyen tool=... va arg_key=... de chay nhanh hon."""
    tools = list_tools() if tool is None else None
    if tool is None:
        tool = find_exec_tool()
    if tool is None:
        return {"error": "khong tim thay tool de chay lenh; xem list_tools()"}
    # doan ten tham so chua script/command
    if arg_key is None and isinstance(tools, list):
        for t in tools:
            if t.get("name") == tool:
                props = (t.get("inputSchema") or {}).get("properties") or {}
                for cand in ("script", "code", "lisp", "command", "expression", "input", "text"):
                    if cand in props:
                        arg_key = cand
                        break
                if arg_key is None and props:
                    arg_key = next(iter(props))
                break
    arg_key = arg_key or "script"
    return call_tool(tool, {arg_key: code}, timeout)
