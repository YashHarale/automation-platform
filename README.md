# Automation Platform

Personal automation platform built using:

- n8n
- PostgreSQL
- Caddy
- Uptime Kuma

Designed to be portable across:

- Local Docker
- Oracle Cloud
- VPS

## Architecture baseline

- Compose spec file: `compose.yaml`
- Edge network: public ingress via Caddy
- Backend network: internal-only service traffic (PostgreSQL and n8n)
- Service discovery: container-to-container access uses Compose service names

Current runtime flow:

- Internet -> Caddy -> n8n
- Internet -> Caddy -> uptime-kuma
- n8n -> postgres

## Run

1. Copy `.env.example` to `.env` and set real values.
2. Start services:

	```powershell
	docker compose up -d
	```

## PostgreSQL operations

- Backup:

	```bash
	./scripts/backup.sh
	```

- Restore (destructive, requires explicit confirmation):

	```bash
	./scripts/restore.sh backups/postgres-YYYYMMDD-HHMMSS.sql.gz --yes
	```

Current PostgreSQL hardening baseline:

- Image tag is environment-driven via `POSTGRES_IMAGE_TAG`
- Persistent storage path inside container is set via `POSTGRES_PGDATA`
- Health check has a startup grace period and higher retry budget
- Backups include SHA-256 checksum files and retention pruning

## n8n hardening baseline

- n8n is reachable only through Caddy on the edge network; it is not published directly to host ports
- Health check probes `http://127.0.0.1:5678/healthz` inside the container
- Secure defaults are environment-driven: diagnostics off, secure cookies on, proxy hops set for reverse-proxy deployment
- Execution-data pruning is enabled to control database growth over time

Operational settings are controlled from `.env` values mirrored in `.env.example`.

## Caddy hardening baseline

- Caddy image tag is environment-driven via `CADDY_IMAGE_TAG`
- TLS certificate contact email is environment-driven via `CADDY_ACME_EMAIL`
- Caddy admin endpoint behavior is environment-driven via `CADDY_ADMIN` (default `off`)
- Caddy waits for healthy n8n before startup routing
- Reverse proxy upstream checks n8n health endpoint and applies fail windows
- Security headers are applied at the edge for all requests

Why this is recommended:

- A single hardened ingress layer keeps TLS and HTTP security controls consistent across Docker Desktop and Linux VPS targets.

Alternatives:

- Use Traefik instead of Caddy for dynamic service discovery.
- Terminate TLS externally (for example at cloud load balancer) and run Caddy only for internal routing.

Trade-offs:

- Caddy is simple and low-maintenance, but less dynamic than Traefik for label-driven multi-service routing.
- Strict edge hardening adds a little configuration overhead now, but reduces production drift and exposure risk later.

## Uptime Kuma service baseline

- Uptime Kuma runs as an internal service on the backend network
- Data persists via bind mount at `./data/uptime-kuma:/app/data`
- Container restart policy is `unless-stopped`
- Health checks monitor local HTTP availability inside the container

Why this is recommended:

- Keeping Kuma internal first avoids exposing another public admin surface while still enabling monitoring from inside the platform network.

Alternatives:

- Publish port 3001 directly to host for immediate access.
- Route Kuma through Caddy with a dedicated host (for example, `status.example.com`).

Trade-offs:

- Internal-only is safer by default but requires a reverse proxy route or temporary local port mapping when operators need UI access.
- Direct host port publishing is simpler initially, but increases exposure risk in production if firewall rules are weak.

Current ingress for Uptime Kuma:

- Set `UPTIME_KUMA_HOST` in `.env` (for example, `status.example.com`)
- Caddy serves that hostname and proxies to the internal `uptime-kuma` service

## Operations runbook

- Deployment and recovery procedures are documented in `docs/deployment-runbook.md`
- The runbook includes Ubuntu VPS notes for Oracle Cloud, AWS, and Hetzner
- Security rotation and rollback checklist is documented in `docs/security-rotation-and-rollback-checklist.md`
- Post-deploy verification can be run with `./scripts/smoke-test.sh`