#!/bin/bash
# 监控 openclaw 主进程是否存活，最多等 30 秒
for i in $(seq 1 30); do
    if ps aux | grep -v grep | grep "openclaw/dist/index.js" | grep -qv grep; then
        echo "openclaw is UP (PID: $(ps aux | grep -v grep | grep 'openclaw/dist/index.js' | awk '{print $2}' | head -1))"
        exit 0
    fi
    sleep 1
    echo "waiting... $i/30"
done
echo "TIMEOUT: openclaw did not restart"
exit 1
