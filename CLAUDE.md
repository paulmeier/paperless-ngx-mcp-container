# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Docker packaging for [paperless-ngx-mcp](https://github.com/cubinet-code/paperless-ngx-mcp) — an MCP server that
exposes a Paperless-NGX instance to AI assistants. **No upstream source lives in this repo**; the server is installed
from npm at image-build time (`ARG PAPERLESS_MCP_VERSION`, default `latest`).

The image tag mirrors the upstream version: `ghcr.io/paulmeier/paperless-ngx-mcp-container:0.1.6` bundles
`paperless-ngx-mcp@0.1.6`.

## Build & run

```bash
# Build the latest upstream release
docker build -t paperless-ngx-mcp .

# Build a specific upstream version
docker build --build-arg PAPERLESS_MCP_VERSION=0.1.6 -t paperless-ngx-mcp:0.1.6 .

# Run (HTTP transport, the default)
docker run -p 3000:3000 \
  -e PAPERLESS_URL=https://paperless.example.com \
  -e PAPERLESS_API_KEY=token \
  paperless-ngx-mcp

# Run via Compose
cp .env.example .env   # then edit
docker compose up
```

## Architecture

**`Dockerfile`** — `node:24-trixie-slim` base (upstream requires Node ≥24), installs `tini` + `ca-certificates`, then
`npm install -g paperless-ngx-mcp@${PAPERLESS_MCP_VERSION}`. Runs as the unprivileged `node` user. `tini` is PID 1.

**`entrypoint.sh`** — Selects the transport from `MCP_TRANSPORT` (`http` default → `--http --port $MCP_HTTP_PORT`, or
`stdio`), warns on missing `PAPERLESS_URL`/`PAPERLESS_API_KEY`, forwards any extra args, then `exec`s the server.

**`healthcheck.sh`** — In http mode, a `/dev/tcp` connect to the port (no HTTP request, to avoid hanging on the SSE
stream). In stdio mode, a no-op success.

**`.upstream-ref`** — Plain-text file holding the last-published upstream version. The source of truth for "have we
built this yet." Ships as `0.0.0` (nothing built yet) so the first sync builds the current latest.

## CI / release flow (all via built-in `GITHUB_TOKEN`, no PAT)

- **`upstream-sync.yml`** (daily + manual): `detect` reads npm's latest and diffs `.upstream-ref` → `publish` (reusable
  call into `docker-publish.yml`) → `record` commits the new `.upstream-ref` and cuts a GitHub Release. `record` runs
  only after a successful publish, so failed builds are retried next run.
- **`docker-publish.yml`** (`workflow_call` + `workflow_dispatch`): multi-arch build+push to GHCR, tags `X.Y.Z`/`X.Y`/
  `X`/`latest`, passing `PAPERLESS_MCP_VERSION`.
- **`lint.yml`** — hadolint + ShellCheck. **`security.yml`** — Trivy image scan.

Requires **Settings → Actions → Workflow permissions = Read and write**. If you enable branch protection on `main`, the
`record` job's push of `.upstream-ref` needs the actions bot to be allowed to push (or switch that step to a PR flow).

## Upstream facts (for context)

- Distributed on npm as `paperless-ngx-mcp`; bin `paperless-ngx-mcp` → `build/index.js`; engines `node >=24`.
- Transports: **stdio** (default) and **HTTP** (`--http --port <n>`, endpoint `POST /mcp`).
- Config env: `PAPERLESS_URL`, `PAPERLESS_API_KEY` (required), `PAPERLESS_PUBLIC_URL` (optional). CLI flags
  `--baseUrl`, `--token`, `--publicUrl`, `--http`, `--port` override env.
