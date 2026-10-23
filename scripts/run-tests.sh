#!/usr/bin/env bash
set -Eeuo pipefail

BENCH_PATH="${BENCH_PATH:-$HOME/frappe-bench}"
SITE_NAME="${SITE_NAME:-test_site}"
APP_NAME="${APP_NAME:-flexirule}"
START_WEB_SERVER="${START_WEB_SERVER:-1}"

if [[ ! -x "$BENCH_PATH/env/bin/bench" ]]; then
  echo "ERROR: Bench executable not found under $BENCH_PATH" >&2
  exit 2
fi
if [[ ! -d "$BENCH_PATH/sites/$SITE_NAME" ]]; then
  echo "ERROR: Site not found: $BENCH_PATH/sites/$SITE_NAME" >&2
  exit 2
fi
if [[ ! -d "$BENCH_PATH/apps/$APP_NAME" ]]; then
  echo "ERROR: App not found: $BENCH_PATH/apps/$APP_NAME" >&2
  exit 2
fi

cd "$BENCH_PATH"
bench --site "$SITE_NAME" set-config allow_tests true

# Keep compatibility with the current harness, which runs tests while Bench's
# development web server is active. Set START_WEB_SERVER=0 to skip that step.
if [[ "$START_WEB_SERVER" == "1" ]]; then
  if ! command -v setsid >/dev/null 2>&1; then
    echo "ERROR: setsid is required to shut down the Bench process group safely." >&2
    exit 2
  fi

  LOG_FILE="${BENCH_LOG_FILE:-/tmp/bench.log}"
  setsid bench start >"$LOG_FILE" 2>&1 &
  BENCH_PID=$!

  cleanup() {
    kill -- "-$BENCH_PID" 2>/dev/null || true
    wait "$BENCH_PID" 2>/dev/null || true
  }
  trap cleanup EXIT INT TERM

  timeout_seconds="${WEB_SERVER_TIMEOUT:-60}"
  until curl -fsS http://localhost:8000 >/dev/null 2>&1; do
    if ! kill -0 "$BENCH_PID" 2>/dev/null; then
      echo "ERROR: Bench exited before port 8000 became responsive." >&2
      cat "$LOG_FILE" >&2 || true
      exit 1
    fi
    if (( timeout_seconds <= 0 )); then
      echo "ERROR: Bench did not become responsive within the timeout." >&2
      cat "$LOG_FILE" >&2 || true
      exit 1
    fi
    sleep 1
    timeout_seconds=$((timeout_seconds - 1))
  done
fi

bench --site "$SITE_NAME" run-tests --app "$APP_NAME"
