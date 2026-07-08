# syntax=docker/dockerfile:1
FROM node:24-trixie-slim

# Upstream npm version of paperless-ngx-mcp to bundle. The docker-publish.yml
# workflow overrides this with the released version at build time; `latest` is
# only the convenience default for local `docker build` runs.
ARG PAPERLESS_MCP_VERSION=latest

LABEL org.opencontainers.image.title="paperless-ngx-mcp-container" \
      org.opencontainers.image.description="Containerized paperless-ngx-mcp MCP server, auto-published to GHCR on each upstream release." \
      org.opencontainers.image.source="https://github.com/paulmeier/paperless-ngx-mcp-container" \
      org.opencontainers.image.url="https://github.com/paulmeier/paperless-ngx-mcp-container" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${PAPERLESS_MCP_VERSION}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# tini gives us a real PID 1 (signal forwarding + zombie reaping) for the
# single Node process; ca-certificates lets it reach an HTTPS Paperless-NGX.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install the MCP server globally at the pinned upstream version. Installed as
# root into /usr/local so the unprivileged `node` user (set below) can execute
# it but not modify it.
RUN npm install -g "paperless-ngx-mcp@${PAPERLESS_MCP_VERSION}" \
    && npm cache clean --force

# Runtime defaults. Transport and port are read by entrypoint.sh; override
# either at `docker run`/compose time. PAPERLESS_URL / PAPERLESS_API_KEY are
# intentionally NOT set here — they are per-deployment secrets.
ENV MCP_TRANSPORT=http \
    MCP_HTTP_PORT=3000

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Drop privileges — the official node image ships an unprivileged `node` user.
USER node

EXPOSE 3000

# Liveness only: in http mode, confirm the port is accepting connections; in
# stdio mode there is no socket to probe, so the check is a no-op.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
