#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
	set -a
	# shellcheck disable=SC1091
	source .env
	set +a
fi

backup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../backups" && pwd)"
backup_file="${backup_dir}/postgres-$(date +%Y%m%d-%H%M%S).sql.gz"
retention_days="${BACKUP_RETENTION_DAYS:-14}"

mkdir -p "$backup_dir"
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER:-n8n}" "${POSTGRES_DB:-n8n}" | gzip > "$backup_file"
sha256sum "$backup_file" > "${backup_file}.sha256"

# Prune old backups and their checksums based on retention policy.
find "$backup_dir" -type f -name 'postgres-*.sql.gz' -mtime +"$retention_days" -delete
find "$backup_dir" -type f -name 'postgres-*.sql.gz.sha256' -mtime +"$retention_days" -delete

echo "Created $backup_file"
