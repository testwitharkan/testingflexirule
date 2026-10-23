#!/usr/bin/env bash
set -euo pipefail

# Dedicated smoke-test runner script for FlexiRule
# Site defaults to test_site if not set in SITE env var
SITE="${SITE:-test_site}"

echo "=========================================="
echo "Running FlexiRule Smoke Tests on site: ${SITE}"
echo "=========================================="

cd "${HOME}/frappe-bench"

bench --site "${SITE}" run-tests --app flexirule --module flexirule.ruleflow.tests.test_smoke
