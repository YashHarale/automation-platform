# Security Rotation and Rollback Checklist

## Purpose

Use this checklist during planned maintenance windows to rotate sensitive values and keep rollback paths ready.

## Rotate Secrets (Planned Window)

1. Announce maintenance and freeze workflow changes.
2. Take a fresh database backup:

   ```bash
   ./scripts/backup.sh
   ```

3. Verify backup checksum before proceeding.
4. Generate new values for:
   - POSTGRES_PASSWORD
   - N8N_ENCRYPTION_KEY
5. Update .env with new values.
6. Apply changes:

   ```bash
   docker compose up -d
   ./scripts/smoke-test.sh
   ```

7. Validate login and workflow execution in n8n.
8. Record rotation date, owner, and reason in internal change log.

## Rollback Checklist

1. Confirm failure symptoms and affected services.
2. Review recent logs:

   ```bash
   docker compose logs --tail=200 caddy n8n postgres uptime-kuma
   ```

3. Revert to previous known-good git commit.
4. Restore previous .env values from secure backup.
5. Redeploy and validate:

   ```bash
   docker compose up -d
   ./scripts/smoke-test.sh
   ```

6. If data integrity is impacted, execute restore drill using the last verified SQL backup.
7. Capture incident timeline and corrective actions.

## Hardening Checks

- .env is not tracked by git
- Caddy admin endpoint is disabled unless required
- Host firewall permits only required ports
- SSH key-based access is enforced
- OS security updates are current

## Why this checklist

Why recommended:

- Secret rotation and rollback are high-risk operations; a repeatable checklist reduces human error.

Alternatives:

- Full secret manager integration (Vault, cloud secret stores) with automated rotation.

Trade-offs:

- Manual checklist is simple and portable, but depends on operator discipline.
- Automated secret management is safer at scale, but introduces tooling complexity.
