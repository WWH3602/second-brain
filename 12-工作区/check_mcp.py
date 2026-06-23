import json
with open('/home/wwh/.openclaw/openclaw.json', encoding='utf-8') as f:
    c = json.load(f)
mcp = c.get('mcp', {})
print('=== mcp servers ===')
for name, cfg in mcp.get('servers', {}).items():
    print(f'  {name}: {cfg}')
print()
print('=== second-brain present ===')
print('second-brain' in mcp.get('servers', {}))
