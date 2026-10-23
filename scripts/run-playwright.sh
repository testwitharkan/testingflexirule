#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PLAYWRIGHT_BASE_URL="$(printenv PLAYWRIGHT_BASE_URL || printf '%s' 'http://localhost:8000')"
PLAYWRIGHT_INSTALL_DEPS="$(printenv PLAYWRIGHT_INSTALL_DEPS || printf '%s' '0')"
CAPTURE_SCREENSHOTS="$(printenv CAPTURE_SCREENSHOTS || printf '%s' '0')"
export PLAYWRIGHT_BASE_URL

# Keep this run's diagnostics separate from stale files left by a prior Jules run.
mkdir -p reports/generated
rm -f reports/results.json reports/junit.xml reports/generated/layout-audit.json
if [ "$CAPTURE_SCREENSHOTS" = "1" ]; then
  rm -rf screenshots/generated
fi

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Node.js and npm are required to run the Playwright UI suite." >&2
  exit 2
fi

if [ ! -d node_modules/@playwright/test ]; then
  echo "Installing Playwright test dependencies..."
  npm install --no-audit --no-fund --package-lock=false
fi

if [ "$PLAYWRIGHT_INSTALL_DEPS" = "1" ]; then
  npx playwright install --with-deps chromium
else
  npx playwright install chromium
fi

echo "Checking Frappe server at $PLAYWRIGHT_BASE_URL..."
server_ready=0
for attempt in $(seq 1 30); do
  if curl -fsS --max-time 4 "$PLAYWRIGHT_BASE_URL/login" >/dev/null 2>&1; then
    server_ready=1
    break
  fi
  sleep 1
done

if [ "$server_ready" -ne 1 ]; then
  echo "Frappe did not respond at $PLAYWRIGHT_BASE_URL/login." >&2
  if [ -f /tmp/bench.log ]; then
    echo "Last Bench log lines:" >&2
    tail -n 80 /tmp/bench.log >&2
  fi
  exit 2
fi

if [ "$CAPTURE_SCREENSHOTS" = "1" ]; then
  echo "Screenshot capture enabled for this run."
  npm run test:ui:screenshots
else
  echo "Screenshot capture is disabled. Set CAPTURE_SCREENSHOTS=1 to request it."
  npm run test:ui
fi