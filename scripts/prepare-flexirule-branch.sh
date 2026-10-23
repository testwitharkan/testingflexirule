#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <flexirule-branch>" >&2
  exit 2
fi

BRANCH="$1"
BENCH_PATH="${BENCH_PATH:-$HOME/frappe-bench}"
SITE_NAME="${SITE_NAME:-test_site}"
APP_PATH="$BENCH_PATH/apps/flexirule"

if [[ ! -d "$APP_PATH/.git" ]]; then
  echo "ERROR: FlexiRule is not installed at $APP_PATH" >&2
  exit 2
fi
if [[ ! -d "$BENCH_PATH/sites/$SITE_NAME" ]]; then
  echo "ERROR: Site not found: $BENCH_PATH/sites/$SITE_NAME" >&2
  exit 2
fi

# Bench's switch-to-branch uses git checkout -f; protect in-progress work.
if [[ -n "$(git -C "$APP_PATH" status --porcelain)" ]]; then
  echo "ERROR: apps/flexirule has uncommitted or untracked files. Preserve or commit them before switching." >&2
  git -C "$APP_PATH" status --short >&2
  exit 3
fi

if ! git -C "$APP_PATH" ls-remote --exit-code --heads origin "refs/heads/$BRANCH" >/dev/null 2>&1; then
  echo "ERROR: Branch '$BRANCH' was not found on the FlexiRule origin remote." >&2
  exit 4
fi

cd "$BENCH_PATH"
bench switch-to-branch "$BRANCH" flexirule
bench setup requirements --dev
bench --site "$SITE_NAME" migrate
bench build --app flexirule

echo "Prepared FlexiRule branch '$BRANCH' on site '$SITE_NAME'."
echo "Verify actual branch, commit, migration, and tests before reporting success."
