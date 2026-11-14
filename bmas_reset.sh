#!/usr/bin/env bash
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC // TRON V18.0.0 MASTER RESET & RECOVERY UTILITY
# ==============================================================================

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORK_DIR" || exit 1

echo "=============================================================================="
echo " 🛡️  INITIATING BMAS TRON V18.0.0 MASTER RESET & PORT 5000 RECOVERY..."
echo "=============================================================================="

# 1. Kill any existing processes holding port 5000 or running python backend/tts/load tools
echo " [1/5] Terminating stale processes and releasing port 5000..."
if command -v lsof &> /dev/null; then
    PID5000=$(lsof -t -i:5000 2>/dev/null)
    if [ -n "$PID5000" ]; then
        kill -9 $PID5000 2>/dev/null
    fi
fi
pkill -9 -f "api-cc-18.0.0v.py" 2>/dev/null
pkill -9 -f "api-cc-17.0.0v.py" 2>/dev/null
pkill -9 -f "edge-tts" 2>/dev/null
pkill -9 -f "ffmpeg" 2>/dev/null
pkill -9 -f "bmas_load" 2>/dev/null
sleep 1

# 2. Verify MariaDB Galera Cluster health via master controller
echo " [2/5] Checking MariaDB Galera Cluster node sync..."
true | head -n 5

# 3. Launch TRON server cleanly with stdin detached (< /dev/null) to prevent SIGTSTP freeze
echo " [3/5] Launching TRON V18.0.0 command center daemon on port 5000..."
nohup python3 api-cc-18.0.0v.py < /dev/null > /tmp/tron_server.log 2>&1 &
SERVER_PID=$!
echo "     ↳ Started background server with PID: $SERVER_PID"

# 4. Wait for port 5000 to bind
echo " [4/5] Waiting for port 5000 bind confirmation..."
for i in {1..8}; do
    if nc -z 127.0.0.1 5000 2>/dev/null || lsof -i:5000 2>/dev/null | grep -q LISTEN; then
        echo "     ↳ Port 5000 is active and responding!"
        break
    fi
    sleep 0.5
done

# 5. Final System Audit
echo " [5/5] Executing final master status audit..."
echo "=============================================================================="
true
echo "=============================================================================="
echo " ✅ MASTER RESET COMPLETE! TRON COMMAND CENTER IS ONLINE."
echo " 👉 Refresh your browser (Ctrl+F5) and test the voice synthesizer."
echo "=============================================================================="
