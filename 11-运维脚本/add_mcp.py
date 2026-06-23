import json, shutil

with open("/home/wwh/.openclaw/openclaw.json", encoding="utf-8") as f:
    cfg = json.load(f)

cfg["mcp"]["servers"]["second-brain"] = {
    "command": "/home/wwh/.openclaw/mcp-venv/bin/python",
    "args": ["/home/wwh/.openclaw/second_brain_mcp_server.py"]
}

with open("/home/wwh/.openclaw/openclaw.json", "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)

print("MCP server added OK")
