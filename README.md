# FlexiRule UI test harness

This repository provisions a disposable Frappe v15 test site and contains an independent Playwright suite for FlexiRule. It is intentionally separate from the application repository: UI checks, diagnostics, generated reports and requested screenshots can evolve without adding test-runner dependencies to FlexiRule itself.

## Quick start

Requirements: the repository workspace, Python/Bench and MariaDB/Redis setup used by the existing test-site script, Node.js/npm, and a Frappe site with FlexiRule installed. The application and site setup remain managed by scripts/setup-test-site.sh.

Install the JavaScript dependencies once:

    npm install --no-audit --no-fund --package-lock=false
    npx playwright install chromium

Start the prepared Bench server on port 8000, then run:

    npm run test:ui

The suite uses Administrator/admin by default to match the disposable site created by the setup script. Override the credentials and host through environment variables when necessary:

    FRAPPE_TEST_USER=Administrator
    FRAPPE_TEST_PASSWORD=admin
    PLAYWRIGHT_BASE_URL=http://localhost:8000

Run the existing provisioning and backend tests with the UI suite enabled:

    RUN_PLAYWRIGHT_TESTS=1 bash scripts/setup-test-site.sh

That switch is opt-in so the existing backend-test workflow is unchanged for normal runs. The setup script keeps Bench running until the Playwright run finishes.

## Screenshot capture

Screenshots are not created on ordinary successful runs. To explicitly request screenshots for test pages, run:

    CAPTURE_SCREENSHOTS=1 npm run test:ui

Or combine this with site setup:

    RUN_PLAYWRIGHT_TESTS=1 CAPTURE_SCREENSHOTS=1 bash scripts/setup-test-site.sh

Requested page screenshots are written under screenshots/generated. Playwright failure screenshots are also enabled only when CAPTURE_SCREENSHOTS=1. Inspect the generated test report for the failing assertion and browser diagnostics.

## Reports and diagnostics

Each run writes reports into the repository workspace:

- reports/html — interactive Playwright HTML report
- reports/results.json — JSON test results
- reports/junit.xml — JUnit-compatible results
- reports/generated/test-results — per-test output, attachments and optional Playwright captures
- reports/generated/layout-audit.json — measured layout/overflow/style geometry records
- screenshots/generated — explicit screenshot captures

Generated artifacts are ignored by Git by default so routine test runs do not create large or noisy commits. Jules can inspect the report files immediately after running the suite. When you specifically request retaining a run in GitHub, commit the relevant report/audit files and any requested screenshots with a short run-specific name; do not commit full HTML output or personal/session data by default.

## What the initial suite checks

- Desk login, session readiness and uncaught browser JavaScript errors.
- RuleFlow workspace shortcuts and number cards.
- Rule list navigation to the Visual Builder.
- The Rule form's native Link/Select fields and save transition.
- Lazy loading of the Rule Builder bundle, contract API presence, canvas and zoom/fit controls.
- Inserting a Condition action, editing its configuration view, and transitioning to/from Raw Configuration.
- Save/reload persistence of the graph.
- Layout measurements at desktop and narrower laptop viewport sizes, including document-level horizontal overflow and key component bounds.
- Evidence useful for debugging: failing assertions, browser errors, and structured layout audit data.

This is a baseline that should grow into a component/interaction matrix for every action type, resolver/configuration family, modal, edge case, and responsive state. A passing run means the listed assertions passed; it does not yet prove every FlexiRule component or every configuration permutation has been exhaustively tested.

## Jules workflow

1. Run the setup script with RUN_PLAYWRIGHT_TESTS=1.
2. Read reports/html, reports/results.json and reports/generated/layout-audit.json. Diagnose the first underlying failure rather than weakening the assertion to make the run green.
3. When asked to show the UI state, rerun with CAPTURE_SCREENSHOTS=1 and inspect screenshots beside the test and layout report.
4. Fix the underlying application issue in Sendipad/flexirule only when a fix is requested. The testingflexirule repository owns the harness and tests; application changes belong in a separate FlexiRule branch/PR.
5. Report the exact command, commit, pass/fail counts, failures, layout findings, screenshot locations (when requested), and any checks not run. Distinguish tests executed from tests merely added.

The test suite uses real Frappe routes and server APIs, and stable selectors already found in the current FlexiRule implementation. If the application UI intentionally changes, update the corresponding test to reflect the intended contract rather than blindly preserving an obsolete selector.