# HFClaw

OpenClaw Gateway sync utility for HuggingFace deployment with automated backup/restore support.

## Features

- **HuggingFace Dataset Sync** - Automatic backup and restore of OpenClaw data
- **Feishu Integration** - Optional Feishu channel support
- **Docker Ready** - Optimized Dockerfile with uv package management
- **CI/CD** - GitHub Actions workflow for automated deployment

## Project Structure

```
hfclaw/
├── sync.py              # Backup/restore sync utility
├── start-openclaw.sh    # Container startup script
├── Dockerfile           # Docker image definition
├── pyproject.toml       # Python project configuration
└── .github/
    └── workflows/
        └── deploy.yml   # GitHub Actions deployment
```

## Local Development

### Prerequisites

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) package manager

### Setup

```bash
# Install dependencies
uv sync

# Run ruff checks
uv run --extra dev ruff check sync.py
uv run --extra dev ruff format sync.py
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HF_DATASET` | Yes | HuggingFace dataset repo ID (e.g., `username/openclaw-backup`) |
| `HF_TOKEN` | Yes | HuggingFace write access token |
| `HF_SPACE_DOMAIN` | Yes | HuggingFace Space domain (without `.hf.space`) |
| `OPENAI_API_BASE` | Yes | OpenAI API base URL |
| `OPENAI_API_KEY` | Yes | OpenAI API key |
| `MODEL` | Yes | Model ID to use |
| `OPENCLAW_GATEWAY_PASSWORD` | Yes | Gateway authentication token |
| `PORT` | No | Server port (default: 7860) |
| `FEISHU_ENABLED` | No | Enable Feishu integration (default: false) |
| `FEISHU_APP_ID` | No | Feishu app ID |
| `FEISHU_APP_SECRET` | No | Feishu app secret |

## Docker Deployment

### Build

```bash
docker build -t hfclaw .
```

### Run

```bash
docker run -d \
  -p 7860:7860 \
  -e HF_DATASET=your-username/openclaw-backup \
  -e HF_TOKEN=your-hf-token \
  -e HF_SPACE_DOMAIN=your-space-name \
  -e OPENAI_API_BASE=https://api.example.com/v1 \
  -e OPENAI_API_KEY=your-api-key \
  -e MODEL=deepseek-chat \
  -e OPENCLAW_GATEWAY_PASSWORD=your-password \
  hfclaw
```

## HuggingFace Spaces Deployment

### 1. Create HuggingFace Space

1. Go to [huggingface.co/new-space](https://huggingface.co/new-space)
2. Select **Docker** as SDK
3. Choose **Public** or **Private** visibility
4. Create the space

### 2. Configure Secrets

In your Space settings, add the following secrets:

| Secret | Description |
|--------|-------------|
| `HF_DATASET` | Dataset repo for backup storage |
| `HF_TOKEN` | HuggingFace write token |
| `OPENAI_API_BASE` | API endpoint URL |
| `OPENAI_API_KEY` | API key |
| `MODEL` | Model identifier |
| `OPENCLAW_GATEWAY_PASSWORD` | Gateway password |

### 3. Set Variables

| Variable | Description |
|----------|-------------|
| `HF_SPACE_DOMAIN` | Your space name (without `.hf.space`) |

## GitHub Actions Deployment

### Required Secrets

Add these in your GitHub repository: **Settings → Secrets and variables → Actions**

| Secret | Description | How to get |
|--------|-------------|------------|
| `HF_TOKEN` | HuggingFace write token | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HF_USERNAME` | GitHub repo owner | HuggingFace username |
| `HF_SPACE_NAME` | `hfclaw` | Target Space name |

### Workflow Triggers

- **Automatic**: Push to `main` branch
- **Manual**: Workflow dispatch from Actions tab

## Backup & Restore

The sync utility automatically:

1. **On Startup**: Restores data from the most recent backup (checks last 5 days)
2. **Scheduled**: Creates backups every 20 minutes
3. **Initial**: Creates initial backup if no config exists

### Backup Contents

- `sessions/` - Session data
- `workspace/` - Workspace files
- `agents/` - Agent configurations
- `memory/` - Memory storage
- `openclaw.json` - Main configuration

## License

MIT
