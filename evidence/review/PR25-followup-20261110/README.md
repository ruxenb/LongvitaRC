# PR #25 follow-up verification — 10/11/2026

Scope: authentication hardening, browser-test retry, Security Rules rerun and
ARTEMIS selector refresh. No Firebase deployment or production data write was
performed.

## Changes

- Web Admin authentication now maps popup cancellation, blocked-popup and
  network failures to safe Vietnamese messages instead of raw exceptions.
- Role lookups share one in-flight request and remain cached for the current
  session; sign-out clears the cache.
- The access gate uses a session generation so a late role result from a prior
  user cannot authorize the next session.
- ARTEMIS home detection accepts the Vietnamese Final Assignment UI while
  retaining the previous title for an older installed APK.
- Chrome test instructions pass individual files instead of `test/admin`.

## Verified

- `flutter analyze lib test`: no issues.
- `flutter test test/admin/admin_web_test.dart`: 7/7 passed.
- `flutter test test/admin/pr25_integration_test.dart`: 11/11 passed.
- `flutter test`: 496/496 passed.
- `flutter build web --target lib/admin_main.dart --release`: passed, including
  the Wasm dry run.
- `firebase/npm run test:rules`: 117/117 passed on the demo emulators. This
  includes owner submit, owner self-approve denial, staff approval, rejection
  without a reason denial, valid admin rejection and terminal-state denial.
- `pytest e2e_test --collect-only -q`: 18 ARTEMIS cases collected.

## Unverified boundaries

- Both individual Chrome test commands remained at `loading ...dart` without
  completing after Web precache. They were stopped; zero browser-test passes
  are claimed.
- No Android device was attached and the ARTEMIS daemon on port 8000 refused
  the connection, so no new ARTEMIS execution is claimed.
- Google OAuth, authorized Hosting domains, staff/admin production reads and
  writes, Firebase Hosting, and an incognito live check were not exercised.
- Re-requesting CodeRabbit requires an authenticated GitHub account after this
  commit is pushed.
