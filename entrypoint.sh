#!/bin/sh
# Nanobot entrypoint — configures tools before starting

SECRETS="/root/.nanobot/workspace/secrets"

# ── gws (Google Workspace CLI) ──────────────────────────────────────────────
GWS_CREDS_SRC="$SECRETS/gws-auth-user.json"
if [ -f "$GWS_CREDS_SRC" ]; then
    mkdir -p /root/.config/gws
    cp "$GWS_CREDS_SRC" /root/.config/gws/credentials.json
    export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/root/.config/gws/credentials.json
fi

# ── Fabric (AI augmentation patterns) ───────────────────────────────────────
FABRIC_ENV_SRC="$SECRETS/fabric.env"
FABRIC_PATTERNS_SRC="/root/.nanobot/workspace/skills/fabric/patterns"
FABRIC_PATTERNS_DEST="/root/.config/fabric/patterns"

mkdir -p /root/.config/fabric

# Copy API key
if [ -f "$FABRIC_ENV_SRC" ]; then
    cp "$FABRIC_ENV_SRC" /root/.config/fabric/.env
fi

# Copy custom patterns from persistence volume (if they exist)
# Standard patterns are baked into the image
if [ -d "$FABRIC_PATTERNS_SRC" ]; then
    for pattern_dir in "$FABRIC_PATTERNS_SRC"/*; do
        if [ -d "$pattern_dir" ]; then
            pattern_name=$(basename "$pattern_dir")
            mkdir -p "$FABRIC_PATTERNS_DEST/$pattern_name"
            cp -r "$pattern_dir"/* "$FABRIC_PATTERNS_DEST/$pattern_name/" 2>/dev/null || true
        fi
    done
fi

# Check for pattern updates from GitHub (quick if already current)
# Runs in background to not block startup, logs to /tmp/fabric-update.log
if [ -f "/root/.config/fabric/.env" ]; then
    (fabric -U > /tmp/fabric-update.log 2>&1 &) || true
fi

# ── Vault Watchdog (Nextcloud sync) ─────────────────────────────────────────
WATCHDOG_SCRIPT="/root/.nanobot/workspace/scripts/vault-watchdog.py"
if [ -f "$WATCHDOG_SCRIPT" ]; then
    python3 "$WATCHDOG_SCRIPT" > /dev/null 2>&1 &
fi

# ── PinchTab Browser Automation ─────────────────────────────────────────────
# PinchTab requires PINCHTAB_CHROME_NO_SANDBOX=1 in container/non-root environments
export PINCHTAB_CHROME_NO_SANDBOX=1
PINCHTAB_SERVICE="/root/.nanobot/workspace/scripts/pinchtab-service.sh"
if [ -f "$PINCHTAB_SERVICE" ]; then
    "$PINCHTAB_SERVICE" start > /dev/null 2>&1 &
fi

# ── James Blinds Platform (dev environment) ──────────────────────────────────
JBP_DIR="/root/.nanobot/workspace/james-blinds-platform"
JBP_DATA="$JBP_DIR/postgres-data"

if [ -d "$JBP_DIR" ] && [ -d "$JBP_DATA" ]; then
    # Start PostgreSQL if not already running
    if ! pg_isready -q 2>/dev/null; then
        if pg_lsclusters 2>/dev/null | grep -q "17 main"; then
            pg_ctlcluster 17 main start > /dev/null 2>&1 || true
        else
            pg_createcluster 17 main --datadir="$JBP_DATA" > /dev/null 2>&1 || true
            pg_ctlcluster 17 main start > /dev/null 2>&1 || true
        fi

        # Wait for PostgreSQL to be ready
        for i in $(seq 1 30); do
            pg_isready -q 2>/dev/null && break
            sleep 1
        done
    fi

    # Start Next.js dev server on port 8501
    if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8501/ | grep -q "200"; then
        cd "$JBP_DIR"
        nohup bash -c "PORT=8501 npm run dev" > /tmp/jbp-dev.log 2>&1 &
        echo $! > /tmp/jbp.pid
    fi
fi

exec python -m nanobot "$@"
