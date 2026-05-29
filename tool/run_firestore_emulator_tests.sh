#!/usr/bin/env bash
set -euo pipefail

compose_file="infra/local/docker-compose.yml"
service_name="firebase-emulator"

FIREBASE_PERSISTENCE=false docker compose -f "$compose_file" up -d --build "$service_name"

cleanup() {
  FIREBASE_PERSISTENCE=false docker compose -f "$compose_file" down
}
trap cleanup EXIT

for _ in {1..60}; do
  logs="$(docker compose -f "$compose_file" logs "$service_name")"
  if grep -q "All emulators ready" <<< "$logs"; then
    break
  fi
  sleep 1
done

logs="$(docker compose -f "$compose_file" logs "$service_name")"
if ! grep -q "All emulators ready" <<< "$logs"; then
  docker compose -f "$compose_file" logs "$service_name"
  echo "Firebase emulators did not become ready in time." >&2
  exit 1
fi

(cd apps/frontend && flutter test)

docker compose -f "$compose_file" exec -T "$service_name" \
  node /workspace/tool/firebase_emulator_smoke_test.mjs
