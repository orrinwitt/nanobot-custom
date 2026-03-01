# Nanobot Custom Image
# Build: docker build -t ghcr.io/orrinwitt/nanobot-custom:latest .
# Push: docker push ghcr.io/orrinwitt/nanobot-custom:latest

# ============================================
# Stage 1: Build nanobot from source
# ============================================
FROM python:3.12-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Clone nanobot repository (specific version)
ARG NANOBOT_VERSION=v0.1.4.post3
WORKDIR /build
RUN git clone --depth 1 --branch ${NANOBOT_VERSION} https://github.com/HKUDS/nanobot.git .

# Install nanobot and dependencies (regular install, not editable)
RUN pip install --no-cache-dir .

# ============================================
# Stage 2: Runtime image
# ============================================
FROM python:3.12-slim

# Install runtime dependencies (standard locations)
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    nextcloud-desktop-cmd \
    git \
    curl \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# MCP servers will be run via npx (no global install needed)
# npx caches packages in ~/.npm/_npx

# Install gog (Google API CLI) from steipete/gogcli releases
# Binary is named 'gog' inside the tarball
RUN curl -L -o /tmp/gogcli.tar.gz \
    https://github.com/steipete/gogcli/releases/download/v0.11.0/gogcli_0.11.0_linux_amd64.tar.gz \
    && tar -xzf /tmp/gogcli.tar.gz -C /usr/bin gog \
    && chmod +x /usr/bin/gog \
    && rm /tmp/gogcli.tar.gz

# Copy nanobot from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Set working directory
WORKDIR /root/.nanobot

# Environment
ENV PYTHONUNBUFFERED=1
ENV NODE_PATH=/usr/lib/node_modules

# Match original image: ENTRYPOINT + CMD for default gateway command
ENTRYPOINT ["python", "-m", "nanobot"]
CMD ["gateway"]