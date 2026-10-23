#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE_ROOT="artifacts/playwright-runs"
OUT_DIR="$ARCHIVE_ROOT/$RUN_STAMP"
while [ -e "$OUT_DIR" ]; do
  OUT_DIR="$ARCHIVE_ROOT/$RUN_STAMP-$$"
done

if [ ! -f reports/results.json ] && [ ! -f reports/junit.xml ]; then
  echo "No Playwright result report exists to archive. Run the UI suite first." >&2
  exit 2
fi

mkdir -p "$OUT_DIR"
[ ! -f reports/results.json ] || cp reports/results.json "$OUT_DIR/results.json"
[ ! -f reports/junit.xml ] || cp reports/junit.xml "$OUT_DIR/junit.xml"
[ ! -f reports/generated/layout-audit.json ] || cp reports/generated/layout-audit.json "$OUT_DIR/layout-audit.json"

CAPTURE_SCREENSHOTS="$(printenv CAPTURE_SCREENSHOTS || printf '%s' '0')"
if [ "$CAPTURE_SCREENSHOTS" = "1" ] && [ -d screenshots/generated ]; then
  mkdir -p "$OUT_DIR/screenshots"
  cp -R screenshots/generated/. "$OUT_DIR/screenshots/"
fi

SOURCE_COMMIT="$(git rev-parse HEAD 2>/dev/null || printf '%s' 'unknown')"
{
  printf 'run_utc=%s\n' "$RUN_STAMP"
  printf 'source_commit=%s\n' "$SOURCE_COMMIT"
  printf 'screenshots_requested=%s\n' "$CAPTURE_SCREENSHOTS"
} > "$OUT_DIR/metadata.txt"

echo "Archived Playwright result files to $OUT_DIR"
echo "Review the contents before committing them to GitHub; screenshots may contain test-site data."