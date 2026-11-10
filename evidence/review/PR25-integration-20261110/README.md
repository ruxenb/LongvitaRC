# PR #25 — PM integration review, 10/11/2026

Base `main`: `3297ed6`. Incoming Web head: `b41436b`. Fix commit: `300ab03`.
The incoming head already contains the base; review and fixes use an isolated
worktree. No CM-00 directory migration, deployment, billing change or production
data write was performed.

## Findings and disposition

| ID | Finding | Disposition and regression |
|---|---|---|
| PM-PR25-01 | Existing recipe categories outside the four editor choices trigger a Dropdown assertion. | Accepted. Include the existing source category without rewriting it. The actual editor opens/saves with `vegetables` and preserves category, ingredient metadata and image. Failed before, passed after. |
| PM-PR25-02 | Async save/review/dashboard completion notifies disposed ViewModels. | Accepted. Admin ViewModels stop notifications on disposal; three controlled completion tests failed before and pass after. This does not cancel remote operations or establish session-generation handling (CM-06). |
| PM-PR25-03 | One malformed submitted document throws while deserializing the entire cross-owner queue. | Accepted (also raised by CodeRabbit's architecture review). Decode documents into individual review items. Invalid entries remain visible with a warning, cannot be approved through the UI/VM, and may be rejected with a reason; valid entries remain reviewable. Cases cover invalid days, recipes, ingredients and duplicate day indices. Removing exception isolation makes five tests fail. No nested Firestore rule changes are claimed. |
| PM-PR25-04 | Comma-delimited ingredient editing corrupts names containing commas; duplicate names reuse the first row's metadata. | Accepted. One ingredient per line; consume each matching existing ingredient once. The comma/duplicate regression failed with the old editor helper and passes after. Existing image preservation remains in place. |
| Earlier CodeRabbit nits | Editor controllers not disposed; metrics typed dynamically. | Accepted. Release editor controllers and use `AdminDashboardMetrics`. |

The existing admin widget fixture now supplies seven actual days and wraps it
in the same queue-item representation as the service. Original approve/reject
assertions remain. No test expectation was relaxed to permit malformed approval.

## Verification

| Check | Result |
|---|---|
| Incoming `b41436b`: analyzer and existing suite | Clean; 483/483 |
| First four PM regressions on incoming code | 4 failed, then 4 passed after fixes |
| Comma/duplicate ingredient regression before fix | Failed |
| Exception-isolation mutation | 5 failures, then restored |
| Final `flutter analyze lib test` | No issues |
| Final `flutter test` | 494/494 |
| Admin tests on Flutter VM | 16/16 (5 existing + 11 new) |
| Release Web build, `lib/admin_main.dart` | Passed, including Wasm dry run |
| Debug Android APK | Passed; no new AVD/device run |
| Release Web startup via supported in-app browser | Rendered Vietnamese sign-in screen at localhost; no sign-in or database mutation |
| `git diff --check` | Clean |

Logs and regression failures in this directory have local workspace paths
removed. `compatibility.json` shows exact unchanged Git blobs for ten critical
base files (rules, Profile/PDF/metadata, Flow 2, pubspec and lockfile).

### Browser-test limitation

`flutter test --platform chrome test/admin` did not load either suite. The
isolated browser reported missing CanvasKit resources and a generated test name
with a missing path separator (`adminadmin_web_test.dart`). After diagnosing
these startup errors, the test browser was closed. **Zero browser-test passes**
are claimed; see `browser-diagnostics.txt`. The release app was subsequently
opened separately through the supported browser tool and rendered sign-in.
Neither check proves Google OAuth or staff/admin actions against production.

## Follow-up boundaries

- CM-06 owns the Web auth/MVVM and role-gate completion, including friendly popup
  cancellation/error handling and role-lookup caching. These earlier Trivial
  CodeRabbit suggestions remain recorded, rather than claiming CM-06 complete.
- Production Firestore rules and Hosting deployment are separate checks. Rules
  are unchanged from `3297ed6`; Emulator suites were not rerun for Dart-only fixes.
- A malformed entry whose top-level fields already violate server rules may
  require privileged repair. The queue never deletes or rewrites its payload.
- Final-UI changes make old ARTEMIS labels/selectors stale (including Home's old
  `Longvita Dashboard` title). No new ARTEMIS pass is claimed in this review.
- Integration does not close TV-00…TV-03 live-deployment acceptance, CM-00/02,
  CM-06/07, or any other owner's task.

CodeRabbit was paused on `b41436b` (last reviewed `0f90f35`); request a new review
on the final pushed head before merging. A paused/skipped check is not a pass.
