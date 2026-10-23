# FlexiRule UI test harness

This repository provisions a disposable Frappe v15 test site and contains an independent Playwright suite for FlexiRule. It is intentionally separate from the application repository: UI checks, diagnostics, generated reports and requested screenshots can evolve without adding test-runner dependencies to FlexiRule itself.

## Quick start

Requirements: the repository workspace, Python/Bench and MariaDB/Redis setup used by the existing test-site script, Node.js/npm, and a Frappe site with FlexiRule installed. The application and site setup remain managed by scripts/setup-test-site.sh.

Install the JavaScript dependencies once. The first `npm install` creates `package-lock.json`; keep that generated lockfile in the repository so future Jules runs can use `npm ci` reproducibly:

    npm install --no-audit --no-fund
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

To keep structured reports (and screenshots when requested) in a timestamped directory inside the repository for an intentional Git commit, add ARCHIVE_PLAYWRIGHT_REPORTS=1:

    RUN_PLAYWRIGHT_TESTS=1 ARCHIVE_PLAYWRIGHT_REPORTS=1 bash scripts/setup-test-site.sh

Requested page screenshots are written under screenshots/generated. Playwright failure screenshots are also enabled only when CAPTURE_SCREENSHOTS=1. Inspect the generated test report for the failing assertion and browser diagnostics.

## Reports and diagnostics

Each run writes reports into the repository workspace:

- reports/html — interactive Playwright HTML report
- reports/results.json — JSON test results
- reports/junit.xml — JUnit-compatible results
- reports/generated/test-results — per-test output, attachments and optional Playwright captures
- reports/generated/layout-audit.json — measured layout/overflow/style geometry records
- screenshots/generated — explicit screenshot captures

Transient outputs are ignored by Git by default so routine test runs do not create large or noisy commits. Set ARCHIVE_PLAYWRIGHT_REPORTS=1 to copy the JSON result, JUnit report, layout audit, metadata and (only if requested) screenshots into artifacts/playwright-runs/<UTC timestamp>/. Review the contents before committing that run to GitHub. The interactive HTML report remains in reports/html for local inspection; it is not archived because it may bundle browser traces or session-related page data.

## What the initial suite checks

- Desk login, session readiness and uncaught browser JavaScript errors.
- RuleFlow workspace shortcuts and number cards.
- Rule list navigation to the Visual Builder.
- The Rule form's native Link/Select fields and save transition.
- Lazy loading of the Rule Builder bundle, contract API presence, canvas and zoom/fit controls.
- Rendering the Assignment, Condition, Loop, Switch, Wait, Notify, Raise Error, Query Records, Document Action and Sub-Rule configuration components through the real builder ActionZone.
- Assignment configuration modal and Raw Configuration navigation, plus save/reload persistence of a Wait node.
- Layout measurements at desktop and narrower laptop viewport sizes, including document-level horizontal overflow and key component bounds.
- Evidence useful for debugging: failing assertions, browser errors, and structured layout audit data.

This is a first component-registry baseline; it should continue growing into a behavior matrix for every action type, resolver/configuration family, modal, edge case, and responsive state. The ten registry tests verify the corresponding config editors render instead of falling back to the empty-state component; they do not yet exhaustively verify every editor's business behavior. A passing run means the listed assertions passed; it does not yet prove every FlexiRule component or every configuration permutation has been exhaustively tested.

## Jules workflow

1. Run the setup script with RUN_PLAYWRIGHT_TESTS=1.
2. Read reports/html, reports/results.json and reports/generated/layout-audit.json. Diagnose the first underlying failure rather than weakening the assertion to make the run green.
3. When asked to show the UI state, rerun with CAPTURE_SCREENSHOTS=1 and inspect screenshots beside the test and layout report.
4. Fix the underlying application issue in Sendipad/flexirule only when a fix is requested. The testingflexirule repository owns the harness and tests; application changes belong in a separate FlexiRule branch/PR.
5. Report the exact command, commit, pass/fail counts, failures, layout findings, screenshot locations (when requested), and any checks not run. Distinguish tests executed from tests merely added.

The test suite uses real Frappe routes and server APIs, and stable selectors already found in the current FlexiRule implementation. If the application UI intentionally changes, update the corresponding test to reflect the intended contract rather than blindly preserving an obsolete selector.