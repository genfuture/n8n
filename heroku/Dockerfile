# ─── Heroku n8n Deployment ────────────────────────────────────────────────────
# Pre-installs community nodes at BUILD time so they survive dyno restarts.
# Add extra nodes to the "npm install" line at the bottom of this file.
# ──────────────────────────────────────────────────────────────────────────────

FROM n8nio/n8n:latest

# Switch to root so we can write to the global node_modules
USER root

# ─── Pre-install community nodes ─────────────────────────────────────────────
# These are baked into the image and will NOT be lost on dyno restart.
# Add/remove packages on this line as needed:
RUN cd /usr/local/lib/node_modules/n8n && \
    npm install --save \
      @apify/n8n-nodes-apify \
    && rm -rf /root/.npm /tmp/*

# ─── Runtime environment wiring ───────────────────────────────────────────────
# Tell n8n where to find any additional external packages you install here.
# The path already contains the pre-installed nodes, so we just point n8n at
# the same directory.
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV N8N_RUNNERS_ENABLED=true

# Heroku assigns a dynamic port via $PORT – the entrypoint script below
# forwards it to n8n's listener.
COPY heroku/docker-entrypoint.heroku.sh /docker-entrypoint.heroku.sh
RUN chmod +x /docker-entrypoint.heroku.sh

USER node

ENTRYPOINT ["/docker-entrypoint.heroku.sh"]
