#!/usr/bin/env bash
set -Eeuo pipefail

BENCH_PATH="${BENCH_PATH:-$HOME/frappe-bench}"
SITE_NAME="${SITE_NAME:-test_site}"

if [[ ! -d "$BENCH_PATH" ]]; then
  echo "ERROR: Bench directory not found: $BENCH_PATH" >&2
  exit 2
fi

cd "$BENCH_PATH"

echo '=== Host/runtime ==='
printf 'Python: '; python3 --version 2>&1 || true
printf 'Node.js: '; node --version 2>&1 || true
printf 'npm: '; npm --version 2>&1 || true
printf 'Yarn: '; yarn --version 2>&1 || true
printf 'MariaDB client: '; mariadb --version 2>&1 || mysql --version 2>&1 || true
printf 'Bench: '; bench --version 2>&1 || true
printf 'Bench Python: '; ./env/bin/python --version 2>&1 || true

for app in frappe erpnext flexirule; do
  if [[ -d "$BENCH_PATH/apps/$app/.git" ]]; then
    echo
    echo "=== $app ==="
    git -C "$BENCH_PATH/apps/$app" branch --show-current || true
    git -C "$BENCH_PATH/apps/$app" rev-parse --short HEAD || true
    git -C "$BENCH_PATH/apps/$app" status --short || true
    git -C "$BENCH_PATH/apps/$app" remote -v | head -n 4 || true
  else
    echo
    echo "=== $app: not installed in this Bench ==="
  fi
done

echo
echo "=== Site: $SITE_NAME ==="
if [[ -d "$BENCH_PATH/sites/$SITE_NAME" ]]; then
  bench --site "$SITE_NAME" list-apps || true
  bench --site "$SITE_NAME" get-config allow_tests || true
else
  echo "Site directory not found: $BENCH_PATH/sites/$SITE_NAME"
fi
