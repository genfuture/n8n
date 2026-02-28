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

# ─── Startup ──────────────────────────────────────────────────────────────────
# Clear the base image ENTRYPOINT (tini + original entrypoint) and replace with
# a simple inline CMD. Heroku sets $PORT at runtime; we forward it to N8N_PORT.
# No external script file needed — avoids all .dockerignore / COPY issues.
USER node

ENTRYPOINT []
# Heroku Postgres provides DATABASE_URL — parse it into the individual vars n8n needs.
# Falls back to SQLite if DATABASE_URL is not set.
CMD export N8N_PORT=${PORT:-5678} \
 && export GENERIC_TIMEZONE=${GENERIC_TIMEZONE:-UTC} \
 && export TZ=${TZ:-${GENERIC_TIMEZONE:-UTC}} \
 && export N8N_PROTOCOL=${N8N_PROTOCOL:-https} \
 && if [ -n "$DATABASE_URL" ]; then \
      export DB_TYPE=postgresdb ; \
      export DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false ; \
      export DB_POSTGRESDB_HOST=$(echo "$DATABASE_URL" | sed -E 's|postgres(ql)?://[^:]+:[^@]+@([^:/]+).*|\2|') ; \
      export DB_POSTGRESDB_PORT=$(echo "$DATABASE_URL" | sed -E 's|postgres(ql)?://[^@]+@[^:]+:([0-9]+).*|\2|') ; \
      export DB_POSTGRESDB_DATABASE=$(echo "$DATABASE_URL" | sed -E 's|.*/([^?]+).*|\1|') ; \
      export DB_POSTGRESDB_USER=$(echo "$DATABASE_URL" | sed -E 's|postgres(ql)?://([^:]+):.*|\2|') ; \
      export DB_POSTGRESDB_PASSWORD=$(echo "$DATABASE_URL" | sed -E 's|postgres(ql)?://[^:]+:([^@]+)@.*|\2|') ; \
    fi \
 && echo "Starting n8n on port $N8N_PORT (DB_TYPE=${DB_TYPE:-sqlite})..." \
 && exec n8n
