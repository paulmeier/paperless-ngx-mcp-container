#!/usr/bin/env bash
set -euo pipefail

# paperless-ngx-mcp reads PAPERLESS_URL / PAPERLESS_API_KEY (and the optional
# PAPERLESS_PUBLIC_URL) from the environment. This wrapper only selects the
# transport and forwards any extra CLI flags passed after the image name.
#
#   MCP_TRANSPORT   http (default) | stdio
#   MCP_HTTP_PORT   port for http transport (default 3000)

TRANSPORT="${MCP_TRANSPORT:-http}"
PORT="${MCP_HTTP_PORT:-3000}"

# Surface missing config early — in the logs — instead of as opaque 401/404s
# from the Paperless API later on. Warn (don't fail): the flags may be supplied
# directly via "$@", and stdio clients sometimes inject env at spawn time.
if [[ -z "${PAPERLESS_URL:-}" ]]; then
  echo "[paperless-ngx-mcp] WARNING: PAPERLESS_URL is not set." >&2
fi
if [[ -z "${PAPERLESS_API_KEY:-}" ]]; then
  echo "[paperless-ngx-mcp] WARNING: PAPERLESS_API_KEY is not set." >&2
fi

case "${TRANSPORT}" in
  http)
    echo "[paperless-ngx-mcp] Starting HTTP transport on 0.0.0.0:${PORT} (POST /mcp)" >&2
    set -- paperless-ngx-mcp --http --port "${PORT}" "$@"
    ;;
  stdio)
    # Log to stderr only — stdout carries the MCP protocol stream.
    echo "[paperless-ngx-mcp] Starting stdio transport" >&2
    set -- paperless-ngx-mcp "$@"
    ;;
  *)
    echo "[paperless-ngx-mcp] ERROR: unknown MCP_TRANSPORT='${TRANSPORT}' (expected 'http' or 'stdio')" >&2
    exit 1
    ;;
esac

exec "$@"
