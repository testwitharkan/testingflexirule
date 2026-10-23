#!/bin/bash

# Exit immediately if a command exits with a non-zero status or references an unbound variable
set -eu

cd ~ || exit

# Clear out bash_logout to prevent clear_console from hijacking the exit code in headless CI
echo "" > ~/.bash_logout

# ==============================================================================
# 1. Environment Variables Configuration
# ==============================================================================
export GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-"/app"}
export GITHUB_BASE_REF=${GITHUB_BASE_REF:-"version-15"}
export GITHUB_REF=${GITHUB_REF:-"refs/heads/version-15"}

GITHUB_BRANCH=${GITHUB_BASE_REF:-${GITHUB_REF##*/}}
export FRAPPE_USER=${FRAPPE_USER:-"frappe"}
export FRAPPE_BRANCH=${FRAPPE_BRANCH:-"version-15"}
export ERPNEXT_BRANCH=${ERPNEXT_BRANCH:-"version-15"}
export FLEXIRULE_BRANCH=${FLEXIRULE_BRANCH:-"develop"}
export FLEXIRULE_REPO=${FLEXIRULE_REPO:-"https://github.com/Sendipad/flexirule"}
export SITE_NAME=${SITE_NAME:-"test_site"}
export MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"mariadb_root_password"}

export CI=Yes
export RUN_PLAYWRIGHT_TESTS=${RUN_PLAYWRIGHT_TESTS:-"0"}
export CAPTURE_SCREENSHOTS=${CAPTURE_SCREENSHOTS:-"0"}
export PLAYWRIGHT_BASE_URL=${PLAYWRIGHT_BASE_URL:-"http://localhost:8000"}
export ARCHIVE_PLAYWRIGHT_REPORTS=${ARCHIVE_PLAYWRIGHT_REPORTS:-"0"}
# ==============================================================================

echo "Starting environment setup for FlexiRule..."

# 2. System Package Setup
sudo apt update
sudo apt remove -y mysql-server mysql-client || true
sudo apt install -y cron mariadb-server mariadb-client libmariadb-dev redis-server libcups2-dev

# 3. Explicitly Start Background Engine Daemons
sudo service redis-server start
sudo service mariadb start

echo "Starting additional Redis instances..."
/usr/bin/redis-server --port 11000 --daemonize yes
/usr/bin/redis-server --port 13000 --daemonize yes

sleep 5

# 4. Install Frappe Bench CLI tool
pip install frappe-bench

# 5. Initialize Core Frappe Framework
if [ ! -d "frappe" ]; then
    echo "Cloning Frappe..."
    git clone "https://github.com/${FRAPPE_USER}/frappe" --branch "${FRAPPE_BRANCH}" --depth 1 ~/frappe
fi

if [ ! -d "frappe-bench" ]; then
    echo "Initializing Bench..."
    bench init --skip-assets --frappe-path ~/frappe --python "$(which python3)" frappe-bench
fi

# 6. Configure MariaDB Database, Users, and Collations
echo "Configuring MariaDB..."
sudo mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('');" || true

sudo mariadb -u root << EOF
SET GLOBAL character_set_server = 'utf8mb4';
SET GLOBAL collation_server = 'utf8mb4_unicode_ci';
CREATE USER IF NOT EXISTS 'test_frappe'@'localhost' IDENTIFIED BY 'test_frappe';
CREATE DATABASE IF NOT EXISTS \`test_frappe\`;
GRANT ALL PRIVILEGES ON \`test_frappe\`.* TO 'test_frappe'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# 7. CI Optimization: Strip Unnecessary Background Daemons
cd ~/frappe-bench || exit
sed -i 's/watch:/# watch:/g' Procfile
sed -i 's/schedule:/# schedule:/g' Procfile
sed -i 's/socketio:/# socketio:/g' Procfile
sed -i 's/redis_socketio:/# redis_socketio:/g' Procfile

bench set-config -g mariadb_root_username root
bench set-config -g mariadb_root_password "${MARIADB_ROOT_PASSWORD}"

# ==============================================================================
# 8. Install FlexiRule using Bench's native app installation workflow
# ==============================================================================
# ==============================================================================
# 8.1 Install Pre-commit in the Bench Virtual Environment
# ==============================================================================
echo "Installing pre-commit..."
~/frappe-bench/env/bin/python -m pip install pre-commit

# Verify installation
~/frappe-bench/env/bin/pre-commit --version

echo "Installing FlexiRule app using bench get-app..."
if [ ! -d "apps/flexirule" ]; then
    bench get-app --branch "${FLEXIRULE_BRANCH}" "${FLEXIRULE_REPO}"
else
    echo "FlexiRule app already exists in apps/flexirule, skipping get-app."
fi

bench setup requirements --dev

# ==============================================================================
# 9. Create Site and Install App
# ==============================================================================
echo "Creating site and installing app..."
bench new-site "${SITE_NAME}" --mariadb-root-password "${MARIADB_ROOT_PASSWORD}" --admin-password admin --force
bench --site "${SITE_NAME}" install-app flexirule

# Complete the native Frappe setup wizard so browser login lands in Desk.
bench --site "${SITE_NAME}" execute frappe.utils.install.complete_setup_wizard

# 10. Build Assets
echo "Building assets..."
bench build --app flexirule

# ==============================================================================
# 11. Run Frappe Tests with Active Web Server
# ==============================================================================
echo "Preparing test environment..."
bench --site "${SITE_NAME}" set-config allow_tests true

echo "Starting Bench server in the background..."
bench start > /tmp/bench.log 2>&1 &
BENCH_PID=$!

echo "Waiting for web server to become responsive on port 8000..."
TIMEOUT=60
while ! curl -s http://localhost:8000 > /dev/null; do
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
    if [ "$TIMEOUT" -le 0 ]; then
        echo "Error: Bench server failed to start within 60 seconds."
        cat /tmp/bench.log
        kill "$BENCH_PID" || true
        exit 1
    fi
done
echo "Bench server is live!"

echo "Running Frappe tests..."
set +e
bench --site "${SITE_NAME}" run-tests --app flexirule
TEST_EXIT_CODE=$?
set -e

UI_TEST_EXIT_CODE=0
if [ "$RUN_PLAYWRIGHT_TESTS" = "1" ]; then
    echo "Running integrated Playwright UI tests..."
    cd "$GITHUB_WORKSPACE"
    set +e
    bash scripts/run-playwright.sh
    UI_TEST_EXIT_CODE=$?
    set -e
else
    echo "Playwright UI tests were not requested (RUN_PLAYWRIGHT_TESTS=0)."
fi

ARCHIVE_EXIT_CODE=0
if [ "$RUN_PLAYWRIGHT_TESTS" = "1" ] && [ "$ARCHIVE_PLAYWRIGHT_REPORTS" = "1" ]; then
    echo "Archiving Playwright reports requested..."
    cd "$GITHUB_WORKSPACE"
    set +e
    bash scripts/archive-playwright-results.sh
    ARCHIVE_EXIT_CODE=$?
    set -e
    if [ "$ARCHIVE_EXIT_CODE" -ne 0 ] && [ "$UI_TEST_EXIT_CODE" -eq 0 ]; then
        UI_TEST_EXIT_CODE=$ARCHIVE_EXIT_CODE
    fi
fi

echo "Shutting down background Bench server..."
kill "$BENCH_PID" || true

echo "Setup and testing completed!"
if [ "$TEST_EXIT_CODE" -ne 0 ]; then
    exit "$TEST_EXIT_CODE"
fi
exit "$UI_TEST_EXIT_CODE"
