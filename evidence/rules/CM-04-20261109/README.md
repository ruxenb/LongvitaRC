# CM-01/03/04 — Security Rules evidence (09/11/2026)

Branch `feature/charlie-data-model-01`, baseline `origin/main` `d374a09`.
Local Firestore Emulator only, demo project `demo-longvita`; nothing deployed and no production data touched.
Tooling: Firebase CLI 15.34.2, `@firebase/rules-unit-testing` 6, Node 26.7.0, JDK 21.0.12.
Logs below are from the run after the PR #27 review fix (a plan outside `draft` must have 7 days).

| Run | Rules | Result | File |
|---|---|---|---|
| `npm run test:rules` (Firestore + Storage suites, Appendix B matrix) | candidate | **117/117 pass** | `rules-run.txt` |
| Appendix B matrix, 42 cases + coverage check | candidate | **43/43 pass** | `matrix-results.json` |
| Appendix B matrix on the old rules | `origin/main` (`baseline-origin-main-d374a09.rules`) | 38 pass / **5 fail** | `baseline-run.txt` |
| Hoàng suite `test/firestore` | candidate | **22/22 pass** | `hoang-run.txt` |

The 5 baseline failures are exactly the rule changes in this package, so the matrix detects them:

- R-05 staff could read another user's profile (Appendix A: Self; admin).
- R-11 `isArchived` was rejected as an unknown recipe field, so the Web archive action (PR #25) failed.
- R-12 staff could hard-delete a recipe (now archive instead).
- R-14 / R-42 no size limits on recipe names or announcement content.

## Reading the logs

- `PERMISSION_DENIED` lines come from cases that are expected to be denied.
- `rules-run.txt` ends with a Java `NullPointerException` from the rules tooling (`Server.processRequestsFromInputStream`). It is printed while the emulator shuts down, after every test has passed; the script exits with code 0. It is not a test failure.
- The baseline run used a temporary config on port 8086 so it did not collide with the main suite on port 8080.
- On Windows, `firebase emulators:exec` can leave the emulator's Java process running after the script ends (its parent process has exited). If a later run reports "port taken", stop the leftover `java.exe` listening on 8080, 8086 or 8185 first.
