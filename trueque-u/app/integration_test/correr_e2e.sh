#!/usr/bin/env bash
# Corre la prueba E2E de publicar objeto en Chrome.
# Requiere: backend en :3000 y chromedriver en el PATH (o en app/.tools/).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CHROMEDRIVER_BIN="${CHROMEDRIVER_BIN:-$ROOT/.tools/chromedriver}"
if [[ ! -x "$CHROMEDRIVER_BIN" ]]; then
  CHROMEDRIVER_BIN="$(command -v chromedriver || true)"
fi
if [[ -z "${CHROMEDRIVER_BIN}" ]]; then
  echo "No se encontró chromedriver. Colócalo en app/.tools/ o en el PATH."
  exit 1
fi

if ! curl -sf "http://localhost:3000/api/sesiones" -X OPTIONS >/dev/null 2>&1 \
  && ! curl -sf "http://localhost:3000/" >/dev/null 2>&1; then
  echo "El backend no responde en http://localhost:3000"
  exit 1
fi

pkill -f "chromedriver --port=4444" 2>/dev/null || true
"$CHROMEDRIVER_BIN" --port=4444 >/tmp/trueque_chromedriver.log 2>&1 &
CD_PID=$!
trap 'kill "$CD_PID" 2>/dev/null || true' EXIT
sleep 1

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/publicar_objeto_test.dart \
  -d web-server \
  --browser-name=chrome \
  --driver-port=4444
