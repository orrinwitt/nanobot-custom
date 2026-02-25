# Nanobot Custom Image

Custom Docker image for nanobot with MCP servers, Google API access, and Nextcloud sync.

## What's Included

| Component | Location | Notes |
|-----------|----------|-------|
| nanobot | `/usr/local/lib/python3.12/site-packages/` | Built from source (v0.1.4.post2) |
| Node.js | `/usr/bin/node` | apt package |
| npm | `/usr/bin/npm` | apt package |
| tmux | `/usr/bin/tmux` | apt package |
| GitHub CLI | `/usr/bin/gh` | apt package |
| nextcloud-desktop-cmd | `/usr/bin/nextcloudcmd` | apt package |
| mcp-obsidian | `/usr/bin/mcp-obsidian` | npm global |
| mcp-server-memory | `/usr/bin/mcp-server-memory` | npm global |
| gog | `/usr/bin/gog` | Google API CLI (v0.11.0) |

## Usage

### Pull

```bash
docker pull ghcr.io/orrinwitt/nanobot-custom:latest
```

### Run

```bash
docker run -d \
  --name nanobot \
  -v /path/to/nanobot-data:/root/.nanobot \
  ghcr.io/orrinwitt/nanobot-custom:latest
```

> **Note:** Only `/root/.nanobot` needs to be mounted. All tools are included in the image.

## MCP Server Configuration

The MCP servers are installed in standard locations and can be referenced by name:

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "mcp-obsidian",
      "args": ["/root/.nanobot/workspace/vault"],
      "disabled": false
    },
    "memory": {
      "command": "mcp-server-memory",
      "disabled": false
    }
  }
}
```

## Updating

1. Update `NANOBOT_VERSION` in `Dockerfile`
2. Push changes to GitHub
3. GitHub Actions will automatically build and push the new image

Or build locally:

```bash
docker build --build-arg NANOBOT_VERSION=v0.1.5 -t ghcr.io/orrinwitt/nanobot-custom:latest .
docker push ghcr.io/orrinwitt/nanobot-custom:latest
```

## Volumes

Only `/root/.nanobot` needs to be mounted as a volume. All tools are included in the image.

| Path | Purpose |
|------|---------|
| `/root/.nanobot/config.json` | Configuration file |
| `/root/.nanobot/workspace/` | Workspace (skills, memory, vault) |
| `/root/.nanobot/workspace/vault/` | Obsidian vault (synced to Nextcloud) |
| `/root/.nanobot/workspace/secrets/` | Credentials and tokens |

## Nextcloud Sync

The vault is synced to Nextcloud using `nextcloudcmd`:

```bash
nextcloudcmd --non-interactive --trust \
  -u 'USERNAME' -p 'PASSWORD' \
  --path 'NanobotMemory' \
  /root/.nanobot/workspace/vault \
  'https://nextcloud.flwitts.us'
```

## Google API Access (gog)

The `gog` CLI provides access to Google services (Gmail, Calendar, Tasks, Drive):

```bash
# Authenticate
gog auth login

# Example: list emails
gog gmail list

# Example: list calendar events
gog calendar list
```

See: https://github.com/steipete/gogcli