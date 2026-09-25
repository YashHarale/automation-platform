#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <backup.sql.gz> --yes" >&2
  exit 1
fi

backup_file="$1"
confirm_flag="$2"
if [[ ! -f "$backup_file" ]]; then
  echo "Backup not found: $backup_file" >&2
  exit 1
fi

if [[ "$confirm_flag" != "--yes" ]]; then
  echo "Restore aborted. Pass --yes as second argument to confirm destructive restore." >&2
  exit 1
fi

if [[ -f "${backup_file}.sha256" ]]; then
  sha256sum -c "${backup_file}.sha256"
else
  echo "Warning: checksum file missing (${backup_file}.sha256)." >&2
fi

gunzip -c "$backup_file" | docker compose exec -T postgres psql -U "${POSTGRES_USER:-n8n}" "${POSTGRES_DB:-n8n}"
echo "Restored $backup_file"
