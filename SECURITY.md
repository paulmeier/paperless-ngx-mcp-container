# Security Policy

## Supported Versions

`paperless-ngx-mcp-container` is published as a rolling set of Docker images on
`ghcr.io/paulmeier/paperless-ngx-mcp-container`. Each image tag mirrors the upstream
`paperless-ngx-mcp` release it bundles, and `:latest` always points at the most
recent build. Only the most recent published image is supported with security
fixes; pin to a specific tag for reproducibility, but be aware older tags will
not receive rebuilds.

| Version  | Supported          |
| -------- | ------------------ |
| `latest` | :white_check_mark: |
| Older    | :x:                |

Note: vulnerabilities in the upstream MCP server itself should be reported to
the [paperless-ngx-mcp](https://github.com/cubinet-code/paperless-ngx-mcp)
project. This policy covers the packaging in *this* repository (Dockerfile,
entrypoint, and CI).

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately via GitHub's
[Private Vulnerability Reporting](https://github.com/paulmeier/paperless-ngx-mcp-container/security/advisories/new):

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Fill out the advisory form with as much detail as you can — affected
   versions, reproduction steps, impact, and any suggested mitigation.

If you cannot use GitHub's advisory flow, email **longish.physic0h@icloud.com**
with the subject line `[paperless-ngx-mcp-container] Security report` and the
same information.

### What to expect

- **Acknowledgement:** within 5 business days.
- **Initial assessment:** within 14 days, including whether the report is
  accepted, declined, or needs more information.
- **Fix and disclosure:** for accepted reports, we aim to ship a patched
  image and publish a coordinated GitHub Security Advisory within 90 days of
  the original report. We will keep you updated throughout.

If a report is declined, we will explain why. If accepted, we will credit you
in the published advisory unless you request otherwise.
