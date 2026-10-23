# testingflexirule — Jules starter structure

This starter adds Jules instructions and task-time helper scripts around the existing FlexiRule test harness. It also includes `scripts/setup-jules-snapshot.sh` as a candidate replacement for the current `scripts/setup-test-site.sh`. Keep the current setup configured until the candidate has been validated in a fresh Jules environment.

## Files

- `AGENTS.md`: task behavior and safety rules. Jules documents root-level `AGENTS.md` support (use this exact uppercase filename).
- `jules-targets.json`: single source of truth for intended branches and runtime requirements.
- `scripts/setup-jules-snapshot.sh`: candidate one-time snapshot bootstrap. It explicitly installs ERPNext, avoids overwriting an existing site, builds assets, and deliberately does not run tests. Validate before using it as the Jules setup script.
- `scripts/doctor.sh`: reports actual installed versions, app branches, app commits, site apps, and working-tree status.
- `scripts/prepare-flexirule-branch.sh <branch>`: safely changes only the FlexiRule app branch, then applies requirements, migrates, and rebuilds. Use it only after confirming the existing Frappe/ERPNext major version is compatible with that branch.
- `scripts/run-tests.sh`: runs the FlexiRule app tests against the prepared site.

All helper scripts are committed as executable files.

## Snapshot recommendation

1. Keep the repository's default Jules snapshot on the most frequently tested target, currently Frappe/ERPNext v15.
2. Use the snapshot for repeated v15 tasks. Keep per-task tests and reports out of the snapshot setup script so a normal task does not reinstall the OS, Bench, or site.
3. Do not point the v15 snapshot at v16 by changing only Git branches. Frappe v16 has a different runtime requirement set. If v16 testing will be frequent, configure a separate Jules codebase/repository snapshot with compatible dependencies; if occasional, rebuild a correctly provisioned v16 environment for that task.
4. Before using this starter in Jules, validate the candidate bootstrap in a fresh environment. The scripts have not been executed inside Jules. The current `scripts/setup-test-site.sh` is intentionally preserved until validation.

## GitHub default branch

The repository's default branch is `main`. This PR targets `main` and does not change the repository's default branch. Merge only after reviewing the changes and validating the candidate bootstrap in a fresh Jules environment.
