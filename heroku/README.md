# n8n on Heroku — persistent community nodes

> **Before using the button below**, push this repo to your own GitHub account
> and update the `repository` field in [`app.json`](../app.json) to your repo
> URL (e.g. `https://github.com/genfuture/n8n`). Then the button will
> point at your customised image with the nodes already baked in.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/genfuture/n8n)

---

This folder contains everything you need to deploy n8n to Heroku **with
community nodes (e.g. Apify) baked into the Docker image** so they are never
lost when a dyno restarts or the app sleeps.

## Why nodes vanish on plain Heroku deployments

Heroku's filesystem is **ephemeral**. Any `npm install` that happens at runtime
writes to a layer that is discarded when the dyno restarts. The fix is to
install the nodes at **Docker build time** so they are part of the image layer.

---

## Quick-start (Docker / Container stack)

### 1. Prerequisites
```bash
# Heroku CLI ≥ 8
brew install heroku/brew/heroku   # macOS
heroku login
heroku container:login
```

### 2. Add/remove nodes

Open [heroku/Dockerfile](./Dockerfile) and edit the `npm install` line:

```dockerfile
RUN mkdir -p /home/node/.n8n/nodes && \
    cd /home/node/.n8n/nodes && \
    npm init -y && \
    npm install \
      @apify/n8n-nodes-apify \
      n8n-nodes-browserless \    # ← add more here
    && chown -R node:node /home/node/.n8n && \
    rm -rf /root/.npm /tmp/*
```

### 3. Copy Heroku config to repo root

Heroku needs `heroku.yml` at the **root** of your repo:

```bash
# Run from repo root
cp heroku/heroku.yml heroku.yml
```

### 4. Create the Heroku app

```bash
heroku create my-n8n-app
heroku stack:set container -a my-n8n-app
```

### 5. Set required environment variables

```bash
# Mandatory
heroku config:set N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)" -a my-n8n-app

# Timezone — set both so cron triggers fire at the right local time
# Use any TZ database name: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
heroku config:set GENERIC_TIMEZONE="America/New_York" TZ="America/New_York" -a my-n8n-app

# Highly recommended — enables webhooks
heroku config:set WEBHOOK_URL="https://my-n8n-app.herokuapp.com/" -a my-n8n-app

# For persistent workflows across restarts, add Heroku Postgres:
heroku addons:create heroku-postgresql:essential-0 -a my-n8n-app
heroku config:set \
  DB_TYPE=postgresdb \
  DB_POSTGRESDB_HOST=<host> \
  DB_POSTGRESDB_PORT=5432 \
  DB_POSTGRESDB_DATABASE=<db> \
  DB_POSTGRESDB_USER=<user> \
  DB_POSTGRESDB_PASSWORD=<pw> \
  DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false \
  -a my-n8n-app
```

### 6. Deploy

```bash
# From repo root
git add heroku.yml heroku/
git commit -m "chore: add Heroku deployment config"
git push heroku main
```

Or build & push the container directly:

```bash
heroku container:push web --context-path . \
  --dockerfile heroku/Dockerfile \
  -a my-n8n-app
heroku container:release web -a my-n8n-app
```

---

## File reference

| File | Purpose |
|---|---|
| `heroku/Dockerfile` | Extends `n8nio/n8n:latest`, installs community nodes at build time |
| `heroku/docker-entrypoint.heroku.sh` | Bridges Heroku's `$PORT` to `N8N_PORT` |
| `heroku/heroku.yml` | Tells Heroku to build the Docker image (copy to repo root) |
| `heroku/app.json` | One-click "Deploy to Heroku" template config |

---

## Adding more community nodes later

1. Add the package name to the `npm install` line in `heroku/Dockerfile`
2. Commit the change
3. `git push heroku main` — Heroku rebuilds the image with the new node bundled

No more manual reinstalls after every dyno restart. ✔

---

## Important: use PostgreSQL for workflow persistence

SQLite data lives on the ephemeral filesystem and **will be lost** when the
dyno restarts. Add the `heroku-postgresql` add-on and set the `DB_TYPE` env
vars (see step 5) to keep your workflows safe.
