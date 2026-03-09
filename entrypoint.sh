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
if [ -f "$FABRIC_ENV_SRC" ]; then
    mkdir -p /root/.config/fabric
    cp "$FABRIC_ENV_SRC" /root/.config/fabric/.env
    if [ ! -d "/root/.config/fabric/patterns" ] || [ -z "$(ls -A /root/.config/fabric/patterns 2>/dev/null)" ]; then
        fabric -U 2>/dev/null || true
    fi
fi

exec python -m nanobot "$@"
