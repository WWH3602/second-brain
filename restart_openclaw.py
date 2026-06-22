#!/usr/bin/env python3
import subprocess, time, sys

# Get old PID
r = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
for line in r.stdout.splitlines():
    if 'openclaw/dist/index.js' in line and 'grep' not in line:
        old_pid = line.split()[1]
        break

print(f'Killing PID {old_pid}')
subprocess.run(['kill', old_pid])

print('Waiting for restart (max 30s)...')
for i in range(30):
    time.sleep(1)
    r = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if 'openclaw/dist/index.js' in line and 'grep' not in line:
            new_pid = line.split()[1]
            if new_pid != old_pid:
                print(f'Restarted! New PID: {new_pid}')
                break
    else:
        print(f'waiting... {i+1}/30')
        continue
    break

time.sleep(3)
print('=== MCP processes ===')
r = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
for line in r.stdout.splitlines():
    if 'mcp-venv' in line:
        print(line)
