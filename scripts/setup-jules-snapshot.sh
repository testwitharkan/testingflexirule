#!/usr/bin/env bash
set -Eeuo pipefail

# One-time Jules environment bootstrap. Keep task-time tests in run-tests.sh.
# Validate this script in a fresh Jules environment before configuring it as the
# repository setup script. It intentionally does not run the FlexiRule tests.

FRAPPE_USER="${FRAPPE_USER:-frappe}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-15}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-15}"
FLEXIRULE_BRANCH="${FLEXIRULE_BRANCH:-develop}"
FLEXIRULE_REPO="${FLEXIRULE_REPO:-https://github.com/Sendipad/flexirule}"
SITE_NAME="${SITE_NAME:-test_site}"
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-mariadb_root_password}"
BENCH_PATH="${BENCH_PATH:-$HOME/frappe-bench}"

export CI=Yes
: > "$HOME/.bash_logout"

if [[ "$FRAPPE_BRANCH" != "$ERPNEXT_BRANCH" ]]; then
  echo "ERROR: Frappe ($FRAPPE_BRANCH) and ERPNext ($ERPNEXT_BRANCH) branches differ." >&2
  echo "This bootstrap expects matching framework major-version branches." >&2
  exit 2
fi

# OS packages and daemons are installed only during snapshot creation.
sudo apt update
sudo apt remove -y mysql-server mysql-client || true
sudo apt install -y cron mariadb-server mariadb-client libmariadb-dev redis-server libcups2-dev
sudo service redis-server start
sudo service mariadb start
/usr/bin/redis-server --port 11000 --daemonize yes
/usr/bin/redis-server --port 13000 --daemonize yes

python3 -m pip install --user frappe-bench
export PATH="$HOME/.local/bin:$PATH"

# Bench init clones Frappe at the selected branch. Do not reuse a partial Bench
# created with another framework major version.
if [[ ! -d "$BENCH_PATH" ]]; then
  bench init --skip-assets --frappe-branch "$FRAPPE_BRANCH" --python "$(command -v python3)" "$BENCH_PATH"
fi
cd "$BENCH_PATH"

sudo mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('');" || true
sudo mariadb -u root <<SQL
SET GLOBAL character_set_server = 'utf8mb4';
SET GLOBAL collation_server = 'utf8mb4_unicode_ci';
CREATE USER IF NOT EXISTS 'test_frappe'@'localhost' IDENTIFIED BY 'test_frappe';
CREATE DATABASE IF NOT EXISTS \`test_frappe\`;
GRANT ALL PRIVILEGES ON \`test_frappe\`.* TO 'test_frappe'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL

bench set-config -g mariadb_root_username root
bench set-config -g mariadb_root_password "$MARIADB_ROOT_PASSWORD"

# Install ERPNext explicitly; the old script defined ERPNEXT_BRANCH but never
# fetched or installed ERPNext.
if [[ ! -d apps/erpnext ]]; then
  bench get-app --branch "$ERPNEXT_BRANCH" https://github.com/frappe/erpnext
else
  current_branch="$(git -C apps/erpnext branch --show-current)"
  if [[ "$current_branch" != "$ERPNEXT_BRANCH" ]]; then
    echo "ERROR: Existing ERPNext checkout is on '$current_branch', expected '$ERPNEXT_BRANCH'." >&2
    echo "Do not silently switch framework major versions in snapshot setup." >&2
    exit 3
  fi
fi

if [[ ! -d apps/flexirule ]]; then
  bench get-app --branch "$FLEXIRULE_BRANCH" "$FLEXIRULE_REPO"
else
  current_branch="$(git -C apps/flexirule branch --show-current)"
  if [[ "$current_branch" != "$FLEXIRULE_BRANCH" ]]; then
    echo "ERROR: Existing FlexiRule checkout is on '$current_branch', expected '$FLEXIRULE_BRANCH'." >&2
    echo "Use scripts/prepare-flexirule-branch.sh for a task-time app branch change." >&2
    exit 4
  fi
fi

bench setup requirements --dev
"$BENCH_PATH/env/bin/python" -m pip install pre-commit

# Do not destroy an existing site. Create it only when missing, then ensure apps
# are installed. A clean site should be created explicitly in a disposable task.
if [[ ! -d "sites/$SITE_NAME" ]]; then
  bench new-site "$SITE_NAME" --mariadb-root-password "$MARIADB_ROOT_PASSWORD" --admin-password admin
fi
installed_apps="$(bench --site "$SITE_NAME" list-apps 2>/dev/null || true)"
if ! grep -qx 'erpnext' <<< "$installed_apps"; then
  bench --site "$SITE_NAME" install-app erpnext
fi
if ! grep -qx 'flexirule' <<< "$installed_apps"; then
  bench --site "$SITE_NAME" install-app flexirule
fi
bench --site "$SITE_NAME" set-config allow_tests true
bench build --app erpnext --app flexirule

echo "Snapshot environment prepared. Tests were intentionally not run during setup."
echo "Run ./scripts/doctor.sh and ./scripts/run-tests.sh from the testingflexirule repository after setup."
