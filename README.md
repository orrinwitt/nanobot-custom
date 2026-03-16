# Nanobot Custom Image

Custom Docker image for nanobot with MCP servers, Google Workspace API access, GitHub CLI, and Nextcloud sync.

## What's Included

| Component | Location | Notes |
|-----------|----------|-------|
| nanobot | `/usr/local/lib/python3.12/site-packages/` | Built from source (v0.1.4.post5) |
| Node.js | `/usr/bin/node` | apt package |
| npm | `/usr/bin/npm` | apt package |
| tmux | `/usr/bin/tmux` | apt package |
| GitHub CLI | `/usr/bin/gh` | apt package |
| nextcloud-desktop-cmd | `/usr/bin/nextcloudcmd` | apt package |
| gws | `/usr/bin/gws` | Google Workspace CLI (npm global) |
| fabric | `/usr/local/bin/fabric` | AI augmentation patterns (danielmiessler/fabric) |
| pip-audit | `/usr/local/bin/pip-audit` | Python dependency security scanning |
| ebooklib | Python package | EPUB generation |
| Pillow | Python package | Image processing (EPUB covers) |
| mcp-obsidian | npx cache | Run via `npx @mauricio.wolff/mcp-obsidian` |
| mcp-server-memory | npx cache | Run via `npx @modelcontextprotocol/server-memory` |

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

MCP servers are run via `npx` (no global install needed, cached automatically):

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["-y", "@mauricio.wolff/mcp-obsidian", "/root/.nanobot/workspace/vault"],
      "transport": "stdio",
      "disabled": false
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "transport": "stdio",
      "disabled": false
    }
  }
}
```

## Auto-Updates

This image automatically checks for new releases from [HKUDS/nanobot](https://github.com/HKUDS/nanobot) daily:

- **Schedule**: Daily at 6 AM UTC (1 AM EST)
- **Process**: Detects new release → updates Dockerfile → builds image → notifies via Telegram
- **Manual trigger**: Go to Actions → "Auto-Update from Upstream" → Run workflow

### Manual Update

To manually update to a specific version:

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

## Google Workspace API Access (gws)

The `gws` CLI provides access to Google services (Gmail, Calendar, Tasks, Drive, Docs, Sheets, Slides):

```bash
# Authenticate
gws auth login

# Example: list emails
gws gmail list

# Example: list calendar events
gws calendar list
```

See: https://github.com/googleworkspace/cli

## Fabric (AI Augmentation Patterns)

`fabric` provides 257+ AI patterns for text transformation, summarization, analysis, and more:

```bash
# List available patterns
fabric --list

# Use a pattern
echo "content" | fabric --pattern summarize
cat file.txt | fabric --pattern extract_wisdom
```

### Pattern Storage

| Type | Location | Notes |
|------|----------|-------|
| Standard patterns | Baked into image | 257 patterns pre-downloaded at build |
| Custom patterns | `workspace/skills/fabric/patterns/` | Persisted in volume, copied at boot |

**Benefits:**
- No boot-time download delay (patterns already in image)
- Custom patterns persist across container rebuilds
- Background update check keeps patterns current

### Configuration

Fabric is configured via `~/.config/fabric/.env` (mounted from `/root/.nanobot/workspace/secrets/fabric.env`):

```env
OPENAI_API_KEY=your-api-key
OPENAI_API_BASE_URL=https://your-openwebui-instance/api/v1
DEFAULT_MODEL=anthropic/claude-sonnet-4.6
DEFAULT_VENDOR=OpenAI
FABRIC_DISABLE_RESPONSES_API=true
```

> **Note:** `FABRIC_DISABLE_RESPONSES_API=true` is required for OpenWebUI compatibility (prevents fabric from using the `/responses` endpoint).

See: https://github.com/danielmiessler/fabric

## GitHub CLI (gh)

The `gh` CLI provides GitHub API access for issues, PRs, Actions, and more:

```bash
# Authenticate
gh auth login

# Example: trigger workflow
gh workflow run build.yml

# Example: check workflow status
gh run list --limit 5
```

See: https://cli.github.com/