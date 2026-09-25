# n8n Docker setup

This repository contains a small Docker Compose setup for running n8n with PostgreSQL and Caddy.

## Quick start

1. Copy `.env.example` to `.env` and replace every placeholder value.
2. Set the hostname in `caddy/Caddyfile` to the domain that points to this server.
3. Start the services:

	```powershell
	docker compose up -d
	```

4. Open the configured hostname in a browser and complete the n8n owner setup.

## Services

- `n8n`: workflow automation server
- `postgres`: persistent n8n database
- `caddy`: reverse proxy and automatic HTTPS

## Operational folders

- `backups/`: local PostgreSQL backup destination
- `scripts/`: backup and maintenance scripts
- `docs/`: deployment notes and runbooks
- `postgres/`: PostgreSQL data mount point

Do not commit `.env`, database data, backups, or generated n8n files.
