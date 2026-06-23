#!/bin/bash
echo "=== Current openclaw PID ==="
OLD_PID=$(ps aux | grep -v grep | grep 'openclaw/dist/index.js' | awk '{print $2}' | head -1)
echo "PID: $OLD_PID"

echo "=== Killing openclaw (PID $OLD_PID) ==="
kill $OLD_PID

echo "=== Waiting for restart (up to 30s) ==="
for i in $(seq 1 30); do
    NEW_PID=$(ps aux | grep -v grep | grep 'openclaw/dist/index.js' | awk '{print $2}' | head -1)
    if [ -n "$NEW_PID" ] && [ "$NEW_PID" != "$OLD_PID" ]; then
        echo "RESTARTED: new PID = $NEW_PID"
        break
    fi
    sleep 1
    echo "waiting... $i/30"
done

echo "=== Checking MCP processes after restart ==="
sleep 3
ps aux | grep 'mcp-venv/bin/python' | grep -v grep
