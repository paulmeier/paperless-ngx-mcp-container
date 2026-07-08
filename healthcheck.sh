#!/usr/bin/env bash
# Container HEALTHCHECK. In http mode, succeed iff the MCP port is accepting
# TCP connections (a bare /dev/tcp connect avoids opening the streamable-HTTP
# SSE stream, which a GET would leave hanging). In stdio mode there is no
# listening socket, so report healthy unconditionally.

if [ "${MCP_TRANSPORT:-http}" = "stdio" ]; then
  exit 0
fi

port="${MCP_HTTP_PORT:-3000}"
timeout 4 bash -c "exec 3<>/dev/tcp/127.0.0.1/${port}" 2>/dev/null
