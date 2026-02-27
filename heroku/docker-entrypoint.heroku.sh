#!/bin/sh
# ─── Heroku entrypoint ────────────────────────────────────────────────────────
# Heroku exposes the port via $PORT. n8n reads N8N_PORT, so we bridge them.
# ──────────────────────────────────────────────────────────────────────────────

# Trust any custom CA certs mounted at /opt/custom-certificates
if [ -d /opt/custom-certificates ]; then
  echo "Trusting custom certificates from /opt/custom-certificates."
  export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"
  export SSL_CERT_DIR=/opt/custom-certificates
  c_rehash /opt/custom-certificates
fi

# Forward Heroku's dynamic $PORT to n8n
export N8N_PORT="${PORT:-5678}"

# Timezone — set GENERIC_TIMEZONE + TZ via Heroku config vars.
# Fall back to UTC if neither is provided.
export GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-UTC}"
export TZ="${TZ:-$GENERIC_TIMEZONE}"

# Heroku uses HTTPS in front of the dyno; tell n8n it is behind a proxy
export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"
export WEBHOOK_URL="${WEBHOOK_URL:-}"

echo "Starting n8n on port $N8N_PORT ..."

if [ "$#" -gt 0 ]; then
  exec n8n "$@"
else
  exec n8n
fi
