# ─── Heroku n8n Deployment ────────────────────────────────────────────────────
# Pre-installs community nodes at BUILD time so they survive dyno restarts.
# Add extra nodes to the "npm install" line at the bottom of this file.
# ──────────────────────────────────────────────────────────────────────────────

FROM n8nio/n8n:latest

# Switch to root so we can write to the global node_modules
USER root

# ─── Pre-install community nodes ─────────────────────────────────────────────
# n8n loads community nodes from ~/.n8n/nodes/ (the user data folder).
# Installing there avoids touching n8n's own package.json (which uses pnpm
# catalog: URLs that npm cannot resolve).
# Add/remove packages on the npm install line as needed.
RUN mkdir -p /home/node/.n8n/nodes && \
    cd /home/node/.n8n/nodes && \
    npm init -y && \
    npm install \
      @apify/n8n-nodes-apify \
    && chown -R node:node /home/node/.n8n && \
    rm -rf /root/.npm /tmp/*

# ─── Runtime environment wiring ───────────────────────────────────────────────
# Tell n8n where to find any additional external packages you install here.
# The path already contains the pre-installed nodes, so we just point n8n at
# the same directory.
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV N8N_RUNNERS_ENABLED=true

# Heroku assigns a dynamic port via $PORT – the entrypoint script below
# forwards it to n8n's listener.
# ─── Entrypoint (written inline — avoids any .dockerignore COPY issues) ───────
RUN printf '%s\n' \
  '#!/bin/sh' \
  'if [ -d /opt/custom-certificates ]; then' \
  '  echo "Trusting custom certificates from /opt/custom-certificates."' \
  '  export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"' \
  '  export SSL_CERT_DIR=/opt/custom-certificates' \
  '  c_rehash /opt/custom-certificates' \
  'fi' \
  'export N8N_PORT="${PORT:-5678}"' \
  'export GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-UTC}"' \
  'export TZ="${TZ:-$GENERIC_TIMEZONE}"' \
  'export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"' \
  'export WEBHOOK_URL="${WEBHOOK_URL:-}"' \
  'echo "Starting n8n on port $N8N_PORT ..."' \
  'if [ "$#" -gt 0 ]; then exec n8n "$@"; else exec n8n; fi' \
  > /entrypoint.sh && chmod +x /entrypoint.sh

USER node

ENTRYPOINT ["/entrypoint.sh"]
