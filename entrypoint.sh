#!/bin/sh
# Nanobot entrypoint — configures tools before starting

# Configure Fabric from mounted workspace secrets
FABRIC_ENV_SRC="/root/.nanobot/workspace/secrets/fabric.env"
FABRIC_ENV_DEST="/root/.config/fabric/.env"

if [ -f "$FABRIC_ENV_SRC" ]; then
    mkdir -p /root/.config/fabric
    cp "$FABRIC_ENV_SRC" "$FABRIC_ENV_DEST"
    # Download patterns if not already present
    if [ ! -d "/root/.config/fabric/patterns" ] || [ -z "$(ls -A /root/.config/fabric/patterns 2>/dev/null)" ]; then
        fabric -U 2>/dev/null || true
    fi
fi

exec python -m nanobot "$@"
