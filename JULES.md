# Jules workflow for FlexiRule UI tests

## Purpose and repository boundaries

This repository owns the Playwright harness, tests, setup integration, browser diagnostics and test reports. FlexiRule production code remains in Sendipad/flexirule. Do not modify production files in this repository.

## Run the suite

Use the prepared site and real web server. The integrated path is:

    RUN_PLAYWRIGHT_TESTS=1 bash scripts/setup-test-site.sh

For a screenshot run:

    RUN_PLAYWRIGHT_TESTS=1 CAPTURE_SCREENSHOTS=1 bash scripts/setup-test-site.sh

If the Bench site is already prepared and its server is running, install dependencies/browsers as needed and call:

    npm install --no-audit --no-fund --package-lock=false
    npx playwright install chromium
    npm run test:ui

A non-default host can be set with PLAYWRIGHT_BASE_URL. The disposable site credentials can be set with FRAPPE_TEST_USER and FRAPPE_TEST_PASSWORD. Never commit secrets or session data.

## Triage expectations

1. Record the exact commit and command executed.
2. Read reports/results.json, reports/html, reports/junit.xml, reports/generated/layout-audit.json, and browser-diagnostics.json attachments.
3. Separate an actual product defect from an invalid test assumption, setup failure, missing DocType/fixture, environmental network issue, and an existing console error.
4. For layout issues, use the attached viewport and measured element bounds to describe the affected element, viewport size, horizontal overflow, computed style and reproduction steps. Do not silently disable the overflow assertion merely to get a green run.
5. When screenshots are requested, set CAPTURE_SCREENSHOTS=1 and compare the relevant screen at the same viewport before and after a UI change. Do not produce or commit screenshots on every routine passing run.
6. If an application fix is explicitly requested, implement it in a branch of Sendipad/flexirule, inspect native Frappe patterns first, run the focused test and relevant regression checks, and report the real test outcome. Do not pretend that changing a test alone fixes a UI defect.
7. Do not progress to broad styling refactors based only on speculation. Group evidence by component, confirm expected behavior, then make the smallest maintainable change.

## Results to report

Provide pass/fail/skipped counts, failed test names and root causes, UI behavior verified, layout findings by viewport, browser console/page errors, whether screenshots were requested and where they are stored, and any checks that were not run. State clearly if tests could not execute. Added test code and passing static checks are not evidence that the browser suite passed.