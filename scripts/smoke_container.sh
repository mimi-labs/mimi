#!/usr/bin/env bash
set -euo pipefail

# Use exported DOCKER if present; else use docker directly (user should be in docker group)
DOCKER_BIN="${DOCKER:-docker}"

name="prufwerk"
img="prufwerk:local"

echo "== start container =="
$DOCKER_BIN rm -f "$name" 2>/dev/null || true
$DOCKER_BIN run -d --name "$name" -p 8080:8080 "$img" >/dev/null

# wait for service
for i in {1..10}; do
  if curl -sf "http://localhost:8080/health" >/dev/null; then break; fi
  sleep 0.5
done

./scripts/smoke.sh

echo "== logs =="
$DOCKER_BIN logs "$name" | tail -n +1

echo "== stop container =="
$DOCKER_BIN rm -f "$name" >/dev/null
echo "CONTAINER SMOKE: PASS"
