# Deployment and Operations Runbook

## Scope

This runbook is for the automation platform running with Docker Compose v2 on:

- Local development using Docker Desktop
- Production on Ubuntu 24.04 (Oracle Cloud, AWS, Hetzner, or similar VPS)

Architecture portability rule:

- Same repository and compose file
- Environment-specific values only in .env
- Deployment command remains docker compose up -d

## Prerequisites

- Docker Engine 24+ and Docker Compose v2 plugin
- Ubuntu host clock synchronized (chrony or systemd-timesyncd)
- DNS A records pointing to server public IP
- Ports 80 and 443 reachable from internet
- SSH access and sudo privileges

## First-Time Host Setup (Ubuntu 24.04)

1. Create a non-root sudo user and disable direct password login if not required.
2. Install Docker Engine and Compose plugin from official Docker repository.
3. Configure firewall:
   - allow 22/tcp (restricted source if possible)
   - allow 80/tcp
   - allow 443/tcp
4. Create deployment directory, clone repository, and copy .env.example to .env.
5. Set strong secrets in .env:
   - POSTGRES_PASSWORD
   - N8N_ENCRYPTION_KEY
6. Set DNS hostnames in .env:
   - N8N_HOST
   - UPTIME_KUMA_HOST
7. Launch stack:

   ```bash
   docker compose up -d
   ```

8. Verify health:

   ```bash
   docker compose ps
   docker compose logs --tail=100 caddy
   ```

## Provider Notes

### Oracle Cloud

- Ensure VCN security list and Network Security Group both allow 80/443 ingress.
- Confirm public subnet route table has internet gateway route.
- If using free tier, monitor block storage space closely for growing backups and database files.

### AWS EC2

- Open 80/443 in Security Group attached to instance.
- If UFW is enabled on host, allow matching ports there too.
- Prefer Elastic IP for stable DNS mapping.

### Hetzner Cloud

- If using Hetzner Cloud Firewall, open 80/443 and limit 22 by source.
- Confirm reverse DNS and A records are aligned for easier TLS troubleshooting.

## Deployment Workflow

1. Pull latest code:

   ```bash
   git pull --ff-only
   ```

2. Pull images and recreate containers:

   ```bash
   ./scripts/update.sh
   ```

3. Validate service health and logs:

   ```bash
   docker compose ps
   docker compose logs --tail=100 n8n
   docker compose logs --tail=100 postgres
   docker compose logs --tail=100 caddy
   docker compose logs --tail=100 uptime-kuma
   ```

4. Run smoke tests:

   ```bash
   ./scripts/smoke-test.sh
   ```

## Backup Policy

- PostgreSQL logical backup runs via scripts/backup.sh
- Backup files are stored in backups/
- SHA-256 checksum files are generated alongside each backup
- Retention is controlled by BACKUP_RETENTION_DAYS in .env

Recommended cadence:

- Daily automated backup
- Weekly restore drill in a test environment
- Monthly off-host backup copy (object storage or another VPS)

## Restore Drill (Test Procedure)

1. Choose a recent backup file in backups/.
2. Verify checksum:

   ```bash
   sha256sum -c backups/postgres-YYYYMMDD-HHMMSS.sql.gz.sha256
   ```

3. Execute restore in non-production first:

   ```bash
   ./scripts/restore.sh backups/postgres-YYYYMMDD-HHMMSS.sql.gz --yes
   ```

4. Validate n8n workflows, credentials metadata, and recent executions.
5. Record drill date, duration, and findings in docs/.

## Incident Quick Checks

- Container health and state:

  ```bash
  docker compose ps
  ```

- Recent service logs:

  ```bash
  docker compose logs --tail=200 caddy n8n postgres uptime-kuma
  ```

- DNS resolution from server:

  ```bash
  getent hosts "$N8N_HOST" "$UPTIME_KUMA_HOST"
  ```

- Disk usage:

  ```bash
  df -h
  du -sh data/* backups
  ```

## Security Baseline

- Never commit .env
- Rotate POSTGRES_PASSWORD and N8N_ENCRYPTION_KEY with controlled maintenance windows
- Keep Caddy admin endpoint disabled unless explicitly needed
- Restrict SSH access and use key-based auth
- Apply OS security updates regularly

Related checklist:

- docs/security-rotation-and-rollback-checklist.md

## Why This Runbook Structure

Why recommended:

- Keeps platform architecture constant while environment values change, which supports reliable migration between local and cloud VPS providers.

Alternatives:

- Separate compose files per provider or per environment.
- Infrastructure-as-code provisioning with Terraform/Ansible from day one.

Trade-offs:

- Single compose model is simpler and highly portable, but requires strong operational discipline around .env management.
- Full IaC can reduce manual drift further, but adds setup overhead for small teams in early phases.
