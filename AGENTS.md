# Instructions for Jules — testingflexirule

## Purpose
This repository is the test harness for FlexiRule. Use it to prepare the test environment, run tests, and record accurate reports. Do not make changes to the upstream `Sendipad/flexirule` application unless the task explicitly asks for an application change.

## Target selection
- Default target: `version-15`, as defined in `jules-targets.json`.
- Read `jules-targets.json` before preparing or changing the environment.
- A task prompt may request another target, such as “test against Frappe v16”. Treat that as a request to select the target configuration; do not assume it changes environment variables or changes the VM snapshot automatically.
- Report the exact Frappe, ERPNext, and FlexiRule branches/versions actually present. Never report a target as tested just because it was requested.

## First inspect the actual environment
Before changing branches or running tests, inspect the existing snapshot:

```bash
./scripts/doctor.sh
```

Also inspect `git status --short` in `~/frappe-bench/apps/frappe`, `~/frappe-bench/apps/erpnext` (if installed), and `~/frappe-bench/apps/flexirule`. Read the relevant Frappe/Bench source or official documentation before relying on a command whose behavior may vary by version.

## Snapshot and setup rules
- The Jules environment setup script creates the repository's reusable baseline snapshot. It is not a per-task configuration mechanism.
- For the normal `version-15` target, reuse the prepared `~/frappe-bench` and `test_site` when they exist and are healthy.
- Do not rerun the full environment bootstrap or `bench new-site ... --force` on every task. `--force` can replace an existing site and discard its database state.
- Keep one-time OS/package/service installation separate from per-task branch selection, migration, building, and testing.
- Run tests as part of the task, not as a reason to reinstall the whole VM baseline.

## Framework major versions — important safety boundary
- Do not treat `bench switch-to-branch version-16 ... --upgrade` as a complete v15-to-v16 runtime upgrade. Bench's branch-switch implementation checks out application branches and may run requirements, backup, patches, and asset builds, but it does not by itself replace the Python interpreter, Node.js runtime, or MariaDB server installed in the VM.
- Before switching Frappe/ERPNext major versions, compare the actual Python, Node.js, and MariaDB versions with the requirements in `jules-targets.json` and the current official Frappe installation documentation.
- If the existing snapshot does not meet the target requirements, do not force the switch or make speculative package changes. Report the mismatch and use a correctly provisioned snapshot/environment for that major version. Prefer a separate Jules codebase/repository configuration for a frequently tested major version so its snapshot can be provisioned independently.
- Ensure Frappe, ERPNext, and every installed app use compatible branches. Do not assume FlexiRule's `develop` branch is compatible with every framework major version; verify its declared requirements and tests.

## Changing only the FlexiRule app branch
For an already compatible framework major version, the helper below can change the FlexiRule app branch and then install requirements, migrate the existing site, and rebuild the app assets:

```bash
./scripts/prepare-flexirule-branch.sh develop
```

Use the branch requested by the task instead of `develop` when appropriate. The helper refuses to switch if it detects uncommitted changes in the FlexiRule checkout. Review and preserve any intentional changes rather than resetting them.

## Testing and reporting
Run the test command from this repository:

```bash
./scripts/run-tests.sh
```

For UI smoke tests, use the separately documented command or script required by the task; do not claim that unit tests imply that UI smoke tests passed.

In the final report, state:
1. Actual Frappe/ERPNext/FlexiRule branch or version and the site used.
2. Exact test command(s) executed and their exit status.
3. Whether tests passed, failed, or were not run; include the relevant failure output.
4. Files changed and commit/push status. Never claim a commit was pushed unless the remote branch and commit SHA were verified.
