# CM-06 — Web Google sign-in and role gate

Baseline: `f9178ee` (main, PR #31). Implementation is confined to the Web client; Mobile, Shared Core, Firestore rules, Firebase configuration and dependencies are unchanged.

## Result

- `SignInWebScreen` uses the shared theme, tokens and button, with Vietnamese loading/error/retry feedback.
- `AdminAuthViewModel` owns auth state, role checks and session/request generations. Admission reads the signed-in user's profile from the server and accepts exactly `staff` or `admin`. Missing/invalid roles are denied; failures do not expose raw SDK errors.
- Restore, role and logout waits have a 15-second deadline and a recovery action. The Google popup remains user-controlled; closing it is not simulated as an SDK cancellation.
- SDK sign-in/sign-out mutations are serialized. Late requests cannot reopen a signed-out session or replace another session's authorization.
- Admin screen ViewModels live inside the authorized session, so logout/session changes dispose their state. Server rules remain authoritative for Firestore operations.

## Verification

| Check | Result | Scope |
| --- | --- | --- |
| `flutter analyze --no-pub lib test` from `web/` | No issues | Entire Web source and tests |
| `flutter test --no-pub --reporter expanded` from `web/` | **60/60 pass** | Includes all 27 existing Web tests and 33 new auth tests |
| `flutter build web --release --no-pub` from `web/` | Successful, 55.9 s | Real app, before final delivery checks; application source unchanged afterwards |
| `dart format` on the nine changed/new Dart files | 0 changes | Delivery files |
| `git diff --check` | Clean | Delivery diff |
| Baseline regressions | 3 fail on baseline, pass on implementation | Invalid non-null role, raw error disclosure, stalled role request |

`web-tests.txt` is the final test output with local paths replaced. Flutter 3.47.6 / Dart 3.13.5. No new Mobile/native or SDK Emulator verification is claimed.

## Manual verification reported by Charlie

The release build was served at `http://localhost:8777`, using real Google Auth and the existing Firebase project. Charlie confirmed:

1. A non-authorized account receives the Vietnamese access-denied screen.
2. An authorized **admin** account signs in and reaches the administration UI.
3. Reload while signed in restores access without getting stuck loading.
4. Logout followed by reload stays at sign-in and does not restore the admin UI.

These are user-reported manual results, not an automated browser trace. No email, UID or OAuth token is published here. Test account provisioning was explicitly authorized separately and is recorded only in the private audit.

## Limits and handoff

- `staff`, missing/invalid roles, recovery paths and session races have controlled unit/widget coverage; there is no separate live staff-account run or successful Firebase SDK Emulator run for this package.
- Optional Chrome/SDK harness attempts were stopped and retained privately; they are not counted as passing evidence or shipped in this diff.
- Admission is checked on session entry/retry. Live role revocation is enforced by Firestore rules for operations; this package does not add a live role-change watcher.
- This is a local release verification. Hosting has not been redeployed by this package; the deployed website can still show an earlier release.
- CM-07 (announcement form) is a separate task after CM-06 integration.
