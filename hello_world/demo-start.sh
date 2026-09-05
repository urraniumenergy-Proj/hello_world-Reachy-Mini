#!/bin/bash
# Startup script for HuggingFace Spaces demo.
#
# Waits for the daemon to be healthy, wakes it up (transitions from
# not_initialized → ready), then starts the hello_world app.

set -e

DAEMON_URL="http://localhost:8000"
APP_URL="http://localhost:8042"

# ── Wait for daemon health endpoint ──────────────────────────────
echo "[demo] Waiting for daemon to start..."
for i in $(seq 1 60); do
    if curl -sf "${DAEMON_URL}/api/daemon/status" > /dev/null 2>&1; then
        echo "[demo] Daemon is up (took ${i}s)"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "[demo] ERROR: Daemon did not start within 60s"
        exit 1
    fi
    sleep 1
done

# ── Wait for daemon to finish waking up ─────────────────────────
# The daemon auto-wakes in sim mode (wake_up_on_start=True).
# Wait for state to leave "not_initialized" before starting the app.
echo "[demo] Waiting for daemon to be ready..."
for i in $(seq 1 30); do
    STATE=$(curl -sf "${DAEMON_URL}/api/daemon/status" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('state',''))" 2>/dev/null || echo "")
    if [ "$STATE" != "not_initialized" ] && [ -n "$STATE" ]; then
        echo "[demo] Daemon state: ${STATE} (took ${i}s)"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[demo] WARNING: Daemon still not initialized after 30s, proceeding anyway"
    fi
    sleep 1
done

# ── Start the hello_world app ────────────────────────────────────
echo "[demo] Starting Hello World app..."
curl -sf -X POST "${DAEMON_URL}/api/apps/start-app/hello_world" || true

# ── Wait for the app to be serving ────────────────────────────────
echo "[demo] Waiting for app to respond..."
for i in $(seq 1 30); do
    if curl -sf "${APP_URL}/api/settings" > /dev/null 2>&1; then
        echo "[demo] Hello World is live on port 8042"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[demo] WARNING: App did not respond within 30s (may still be starting)"
    fi
    sleep 1
done

echo "[demo] Startup complete."
