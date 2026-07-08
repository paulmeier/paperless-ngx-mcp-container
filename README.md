# paperless-ngx-mcp-container

A minimal, multi-arch Docker image for [**paperless-ngx-mcp**](https://github.com/cubinet-code/paperless-ngx-mcp) — a
[Model Context Protocol](https://modelcontextprotocol.io) server that lets AI assistants (Claude, etc.) search and
manage documents in your [Paperless-NGX](https://docs.paperless-ngx.com/) instance.

The image is **automatically rebuilt and published to GitHub Container Registry on every new upstream release**. The
image tag always equals the upstream version it bundles, so `:0.1.6` contains `paperless-ngx-mcp@0.1.6`.

```
ghcr.io/paulmeier/paperless-ngx-mcp-container
```

| Tag         | Contents                                              |
| ----------- | ----------------------------------------------------- |
| `latest`    | The most recent upstream release                      |
| `0.1.6`     | Exactly `paperless-ngx-mcp@0.1.6` (immutable)         |
| `0.1`       | Latest patch of the `0.1` line                        |
| `0`         | Latest minor/patch of the `0` line                    |

Built for `linux/amd64` and `linux/arm64`.

---

## Quick start (Docker Compose)

```bash
git clone https://github.com/paulmeier/paperless-ngx-mcp-container.git
cd paperless-ngx-mcp-container
cp .env.example .env
# edit .env: set PAPERLESS_URL and PAPERLESS_API_KEY
docker compose up -d
```

The MCP server is now listening on `http://localhost:3000/mcp`.

> You only need the `docker-compose.yml` and `.env` files to run it — the compose file pulls the prebuilt image from
> GHCR, so cloning the whole repo is optional.

## Quick start (docker run)

```bash
docker run -d --name paperless-mcp \
  -p 3000:3000 \
  -e PAPERLESS_URL=https://paperless.example.com \
  -e PAPERLESS_API_KEY=your-api-token \
  ghcr.io/paulmeier/paperless-ngx-mcp-container:latest
```

## Configuration

Configuration is entirely through environment variables:

| Variable               | Required | Default | Description                                                              |
| ---------------------- | -------- | ------- | ------------------------------------------------------------------------ |
| `PAPERLESS_URL`        | ✅       | —       | Base URL of your Paperless-NGX instance.                                 |
| `PAPERLESS_API_KEY`    | ✅       | —       | Paperless-NGX API token (Settings → user menu → API Token).              |
| `PAPERLESS_PUBLIC_URL` | —        | —       | Public URL used when building shareable document links.                  |
| `MCP_TRANSPORT`        | —        | `http`  | Transport to run: `http` or `stdio`.                                     |
| `MCP_HTTP_PORT`        | —        | `3000`  | Port for the HTTP transport.                                             |

Any extra arguments after the image name are forwarded to `paperless-ngx-mcp` unchanged.

---

## Connecting an MCP client

### HTTP transport (default)

The container exposes the streamable-HTTP endpoint at `POST /mcp`. Point any HTTP-capable MCP client at it.

**Claude Code:**

```bash
claude mcp add --transport http paperless http://localhost:3000/mcp
```

**Generic `mcpServers` config:**

```json
{
  "mcpServers": {
    "paperless": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### stdio transport

For clients that spawn the server per-session (e.g. Claude Desktop), run the container in stdio mode. Note the `-i`
(interactive) flag and `MCP_TRANSPORT=stdio`; no port is published.

**Claude Code:**

```bash
claude mcp add paperless -- \
  docker run -i --rm \
    -e PAPERLESS_URL=https://paperless.example.com \
    -e PAPERLESS_API_KEY=your-api-token \
    -e MCP_TRANSPORT=stdio \
    ghcr.io/paulmeier/paperless-ngx-mcp-container:latest
```

**Claude Desktop (`claude_desktop_config.json`):**

```json
{
  "mcpServers": {
    "paperless": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "PAPERLESS_URL",
        "-e", "PAPERLESS_API_KEY",
        "-e", "MCP_TRANSPORT=stdio",
        "ghcr.io/paulmeier/paperless-ngx-mcp-container:latest"
      ],
      "env": {
        "PAPERLESS_URL": "https://paperless.example.com",
        "PAPERLESS_API_KEY": "your-api-token"
      }
    }
  }
}
```

---

## How auto-publishing works

There is **no source code** for the MCP server in this repo — only the packaging. The upstream project is pulled from
npm at image-build time.

1. **`.github/workflows/upstream-sync.yml`** runs daily (and on demand). It reads the latest `paperless-ngx-mcp`
   version from the npm registry and compares it to the version recorded in [`.upstream-ref`](.upstream-ref).
2. If a newer version exists, it calls **`.github/workflows/docker-publish.yml`**, which builds the multi-arch image
   with `--build-arg PAPERLESS_MCP_VERSION=<version>` and pushes it to GHCR tagged `X.Y.Z`, `X.Y`, `X`, and `latest`.
3. Only after a successful publish does it commit the bumped `.upstream-ref` and cut a matching GitHub Release. If a
   build fails, the version is *not* recorded, so the next run retries it.

Everything uses the built-in `GITHUB_TOKEN` — no personal access token or extra secrets are required. The publishing
workflow can also be triggered manually to rebuild any version (for example after a base-image or security bump):

```bash
gh workflow run docker-publish.yml --field version=0.1.6
```

### First run & maintainer setup

The repo ships with `.upstream-ref` set to `0.0.0`, so the **first** `upstream-sync` run (trigger it from the Actions
tab, or wait for the daily schedule) builds the current latest release and publishes it. After that it only builds when
upstream publishes something new. A few one-time repository settings:

- **Actions** must be enabled, with **Settings → Actions → General → Workflow permissions → *Read and write
  permissions*** so `upstream-sync` can push `.upstream-ref` and cut releases.
- The GHCR package is created **private** on first publish. To make it public and link it here, open the package page
  (repo → Packages → Package settings) and change its visibility.

## Building locally

```bash
# Build the latest upstream release
docker build -t paperless-ngx-mcp .

# Pin a specific upstream version
docker build --build-arg PAPERLESS_MCP_VERSION=0.1.6 -t paperless-ngx-mcp:0.1.6 .
```

## Continuous checks

- **Lint** (`lint.yml`) — [hadolint](https://github.com/hadolint/hadolint) on the Dockerfile and
  [ShellCheck](https://www.shellcheck.net/) on the shell scripts, on every push/PR.
- **Security scan** (`security.yml`) — [Trivy](https://github.com/aquasecurity/trivy) scans the built image for
  CRITICAL/HIGH vulnerabilities on every push/PR and weekly, uploading results to the repo's Security tab.

## Security

See [SECURITY.md](SECURITY.md) for the supported-versions policy and how to report a vulnerability. Treat
`PAPERLESS_API_KEY` as a secret — pass it via `.env`/Docker secrets, never bake it into an image.

## License & credits

This packaging is released under the [MIT License](LICENSE). The bundled MCP server,
[**paperless-ngx-mcp**](https://github.com/cubinet-code/paperless-ngx-mcp), is the work of its respective authors and
carries its own license. This project is not affiliated with the Paperless-NGX project.
