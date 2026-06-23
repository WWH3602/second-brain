import json, urllib.request

# Get token from openclaw.json
with open('/home/wwh/.openclaw/openclaw.json', encoding='utf-8') as f:
    cfg = json.load(f)
token = cfg['gateway']['auth']['token']

url = 'http://127.0.0.1:18789/v1/mcp/tools'
req = urllib.request.Request(url)
req.add_header('Authorization', f'Bearer {token}')
req.add_header('Content-Type', 'application/json')

try:
    resp = urllib.request.urlopen(req, timeout=5)
    data = json.loads(resp.read())
    for tool in data.get('tools', []):
        print(f"  {tool['name']}: {tool.get('description','')}")
except Exception as e:
    print(f"Error: {e}")
