#!/usr/bin/env bash
set -euo pipefail

required_services=(postgres n8n caddy uptime-kuma)

echo "[1/5] Checking required services are running"
for service in "${required_services[@]}"; do
  if ! docker compose ps --status running --services | grep -Fxq "$service"; then
    echo "Service is not running: $service" >&2
    exit 1
  fi
done

echo "[2/5] Checking container health states"
for service in "${required_services[@]}"; do
  cid="$(docker compose ps -q "$service")"
  if [[ -z "$cid" ]]; then
    echo "Container ID not found for service: $service" >&2
    exit 1
  fi

  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid")"
  case "$health" in
    healthy|none)
      ;;
    *)
      echo "Unhealthy service detected: $service (health=$health)" >&2
      exit 1
      ;;
  esac
done

echo "[3/5] Validating Caddy configuration"
docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile >/dev/null

echo "[4/5] Checking n8n health endpoint"
docker compose exec -T n8n node -e "require('http').get('http://127.0.0.1:5678/healthz',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

echo "[5/5] Checking Uptime Kuma endpoint"
docker compose exec -T uptime-kuma node -e "require('http').get('http://127.0.0.1:3001/',r=>process.exit(r.statusCode>=200&&r.statusCode<500?0:1)).on('error',()=>process.exit(1))"

echo "Smoke test passed."
