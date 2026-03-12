FROM ghcr.io/openclaw/openclaw:latest

LABEL maintainer="OpenClaw"
LABEL description="OpenClaw Gateway with HuggingFace sync support"

USER root

# Install system dependencies in single layer with cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install uv for fast Python package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Install Python dependencies with cache cleanup
RUN uv pip install --system --no-cache huggingface_hub

# Copy scripts and set permissions in single layer
COPY sync.py start-openclaw.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/sync.py /usr/local/bin/start-openclaw.sh

# Environment variables
ENV PORT=7860 \
    OPENCLAW_GATEWAY_MODE=local \
    UV_SYSTEM_PYTHON=1

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

CMD ["/usr/local/bin/start-openclaw.sh"]
