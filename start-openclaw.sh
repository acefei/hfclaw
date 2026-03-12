#!/bin/bash
set -e

OPENCLAW_DIR="/root/.openclaw"
BACKUP_INTERVAL=1200

log_info()  { echo "  ℹ $1"; }
log_ok()    { echo "  ✓ $1"; }
log_step()  { echo ""; echo "▶ $1"; echo "  ─────────────────────"; }
log_error() { echo "  ✗ $1"; }

init_directories() {
    mkdir -p "$OPENCLAW_DIR"/{sessions,workspace}
}

restore_data() {
    log_step "Restoring data from HuggingFace"
    if python3 /usr/local/bin/sync.py restore; then
        log_ok "Data restored successfully"
    else
        log_info "No backup found or restore skipped"
    fi
}

clean_api_base() {
    echo "$OPENAI_API_BASE" | sed 's|/chat/completions||g; s|/v1/|/v1|g; s|/v1$|/v1|g'
}

generate_config() {
    log_step "Generating configuration"

    if [ -z "$HF_SPACE_DOMAIN" ]; then
        log_error "HF_SPACE_DOMAIN environment variable is required"
        echo "  Example: HF_SPACE_DOMAIN=your-space-name"
        exit 1
    fi

    local clean_base
    clean_base=$(clean_api_base)

    cat > "$OPENCLAW_DIR/openclaw.json" <<EOF
{
  "models": {
    "providers": {
      "siliconflow": {
        "baseUrl": "$clean_base",
        "apiKey": "$OPENAI_API_KEY",
        "api": "openai-completions",
        "models": [{ "id": "$MODEL", "name": "DeepSeek", "contextWindow": 128000 }]
      }
    }
  },
  "agents": { "defaults": { "model": { "primary": "siliconflow/$MODEL" } } },
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": ${PORT:-7860},
    "trustedProxies": ["*"],
    "auth": { "mode": "token", "token": "$OPENCLAW_GATEWAY_PASSWORD" },
    "controlUi": {
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true,
      "allowedOrigins": ["https://${HF_SPACE_DOMAIN}.hf.space", "https://*.hf.space", "https://*.huggingface.co", "http://localhost:*", "http://127.0.0.1:*"]
    }
  },
  "channels": {
    "feishu": {
      "enabled": ${FEISHU_ENABLED:-false},
      "appId": "$FEISHU_APP_ID",
      "appSecret": "$FEISHU_APP_SECRET",
      "dmPolicy": "open"
    }
  }
}
EOF

    log_ok "Configuration generated"
}

start_backup_scheduler() {
    log_step "Starting backup scheduler"
    (while true; do sleep $BACKUP_INTERVAL; python3 /usr/local/bin/sync.py backup; done) &
    log_ok "Backup scheduler running (interval: ${BACKUP_INTERVAL}s)"
}

initial_backup_if_needed() {
    if [ ! -f "$OPENCLAW_DIR/openclaw.json" ]; then
        log_info "No existing config, performing initial backup"
        python3 /usr/local/bin/sync.py backup
    fi
}

start_gateway() {
    log_step "Starting OpenClaw Gateway"
    openclaw doctor --fix
    exec node openclaw.mjs gateway --allow-unconfigured
}

main() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║       OpenClaw Gateway Starter       ║"
    echo "╚══════════════════════════════════════╝"

    init_directories
    restore_data
    generate_config
    initial_backup_if_needed
    start_backup_scheduler
    start_gateway
}

main "$@"
