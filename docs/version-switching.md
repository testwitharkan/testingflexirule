# Version switching policy

## App branch versus framework version

Changing the FlexiRule app branch inside an already compatible Bench is a narrower operation than changing the Frappe/ERPNext major release. For a FlexiRule-only branch change, inspect the working tree first, use `scripts/prepare-flexirule-branch.sh <branch>`, and run the relevant tests.

For framework major changes, first inspect the actual current versions and the current official Frappe installation requirements. A branch-switch command is not a substitute for provisioning compatible Python, Node.js, and MariaDB versions. Bench's `switch-to-branch` implementation checks out app branches; when `--upgrade` is accepted for a detected version upgrade, it also performs setup requirements, backup, patches, assets, and post-upgrade steps. It does not itself install a new Python interpreter, a different Node.js runtime, or a different MariaDB server.

Therefore:

- Do not change v15 to v16 by editing `jules-targets.json` alone.
- Do not run `bench switch-to-branch version-16 frappe erpnext --upgrade` against a v15 snapshot until the runtime and app compatibility checks have passed.
- Prefer independent Jules snapshots for v15 and v16 if both are frequent targets.
- Confirm whether the chosen FlexiRule branch explicitly supports the requested Frappe release before installing or testing it.

## Diagnosing a task

```bash
./scripts/doctor.sh
```

Keep the diagnostic output with the report when a version mismatch causes a test failure.
