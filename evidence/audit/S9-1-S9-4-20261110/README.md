# Lab 3 final audit snapshot — 10/11/2026

Baseline: `origin/main` and tag `v1.0-rc` at `aeae4c3`.

This folder records a redacted audit summary. It intentionally does not store
the raw Gitleaks JSON because that report can reproduce secret values.

## S9-1 — secret scan

Tool: Gitleaks `8.30.1`, `--redact=100`.

| Scope | Commits/files scanned | Findings |
|:---|---:|---:|
| Current tree before redaction | 3.98 MB | 7 |
| Current tree after redaction | 3.99 MB | 4 |
| Git history (`origin/main`) | 232 non-merge commits | 9 |

Current-tree classification:

- Three GCP/Firebase client API key findings in
  `mobile/android/app/google-services.json`,
  `mobile/lib/firebase_options.dart` and `web/lib/firebase_options.dart`.
  These are client configuration values, not service-account private keys, but
  they still require Firebase/Google API restriction review before S9-1 closes.
- Three affected lines containing four Firebase Storage download-token
  occurrences in `evidence/artemis/raw/runs.jsonl` were sanitized to
  `token=<redacted>`. The corresponding historical tokens still require
  revoke/rotation in Firebase before S9-1 closes.
- One false positive in
  `evidence/review/PR25-final-harness-20261110/verification.json` line 16: the
  value is a source verification hash keyed by a test-file path, not a secret.

History adds earlier copies of Firebase client configuration, including the
pre-monorepo `android/app/google-services.json`. No service-account JSON,
password or keystore finding was identified by this scan. This statement does
not waive manual review or Google Console restrictions.

**Status:** S9-1 remains **In progress** until the historical download tokens
are revoked and the client-key restrictions are confirmed. The current tree no
longer contains the raw download-token values; its remaining four findings are
the three client configuration keys and the documented hash false positive.

## S9-2 — Firebase project identity

Read-only configuration comparison:

- `mobile/android/app/google-services.json`: project `longvita-8da7e`, project
  number `1041459198085`, Android package `vn.edu.fpt.longvita`.
- `mobile/lib/firebase_options.dart`: project `longvita-8da7e`.
- `web/lib/firebase_options.dart`: project `longvita-8da7e`.
- `firebase.json`: Hosting output `web/build/web`.

Repository references to `demo-longvita` occur in Emulator/test documentation;
they must not be presented as production evidence. Production screenshots used
in the final report must show `longvita-8da7e` where the project identity is
visible.

**Status:** configuration comparison passes; S9-2 remains **In progress** until
the final report/slide screenshot set is selected and checked.

## S9-4 — Git history

Snapshot of `origin/main`:

- Total commits: **273**.
- Non-merge commits: **232**.
- Merge commits: **41**.
- First commit: `23ce8bc` on 01/11/2026.
- Current release-candidate commit: `aeae4c3` on 10/11/2026.

| Date | Commits |
|:---|---:|
| 01/11 | 2 |
| 02/11 | 55 |
| 03/11 | 54 |
| 04/11 | 36 |
| 05/11 | 3 |
| 06/11 | 23 |
| 07/11 | 2 |
| 08/11 | 19 |
| 09/11 | 45 |
| 10/11 | 34 |

The history shows work across planning, architecture, features, testing,
review and evidence instead of a single final commit. The course's numeric
minimum-commits-per-day requirement is still not documented in the repository,
so this audit records distribution without claiming that an unknown threshold
has passed.

**Status:** current snapshot recorded; repeat after the final deliverable
commits and before S9-6 submission.
