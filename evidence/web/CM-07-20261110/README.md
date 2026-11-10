# CM-07 — Web announcement form → Firestore → Mobile inbox

Baseline `0cfe905` (PR #33), implementation **`89f04f8`**. Flutter 3.47.6 / Dart 3.13.5; Android 15 AVD `LocalMate_API_35`. The user authorized Codex to implement and test CM-07 end-to-end, including the necessary clearly labeled test announcement.

## Implemented scope

- Vietnamese `AnnouncementForm`: title/content validation, counters, local preview, audience confirmation, loading, error/retry and success/new-draft states. Uses the Core theme/tokens, cards and buttons; tested at 360/1280 px with text scale 2.0.
- Separate Core `IAnnouncementPublisher` / `FirestoreAnnouncementPublisher`; existing team service interfaces and the Mobile listener are preserved.
- Exactly the established schema: `title`, `content`, `authorRole`, `createdAt` (UTC ISO string). No user ID, email, body/status fields, Storage, FCM or new packages.
- Each publish intent retains its auto-ID, payload and time for retries in the current session. An online transaction verifies the current profile role, reads the target document and only creates when absent. Identical retries succeed without a second document; different content is not overwritten.
- Session checks precede the transaction, its reads/writes and result handling. Pending work cannot apply its UI result/analytics to a later session. This does **not** cancel a transaction already accepted by the server.
- After 15 seconds without acknowledgement the UI reports that it is still waiting and keeps repeat submission disabled. It continues waiting for the same request; it does not claim cancellation or create a new intent.
- `publish_announcement` is invoked once after successful acknowledgement, outside the retryable transaction callback. Telemetry failures do not turn a successful publication into a form error. A live Analytics Console event was not independently verified in this task.

## Verification results

| Verification | Result | Evidence/scope |
| --- | --- | --- |
| Web tests | **68/68 pass** | 60 existing tests + 8 CM-07 tests; `web-tests.txt` |
| Core tests | **20/20 pass** | 16 existing tests + 4 publication contract tests; `core-tests.txt` |
| Mobile regression suite | **465/465 pass** | Existing suite, `mobile-tests.txt` |
| Canonical Firestore rules | **103/103 pass** | Actual local Firestore Emulator, demo project; includes staff/admin allow, user/anonymous deny and author-role spoofing/bounds cases; `rules.txt` |
| Analyzer | Clean | Web/Core source/tests + Mobile source; final Web pass includes preview-heading fix |
| Release Web | Built, **58.6 s**, Wasm dry run succeeded | Final source, `build-web.txt` |
| Debug APK | Built, **111.2 s** | Source preceding the Web-only heading change; Mobile/Core application files are unchanged afterwards; `build-apk.txt` |
| Format / branch diff | Clean | No dependency/lockfile/config/rules changes |

The 553 Flutter tests and 103 rules cases are separate counts. Controlled tests cover uncertain outcomes, same-intent retry, disabled duplicate submission, session termination, telemetry failure, validation and layout. They are not described as native race/negative-role test runs.

## Actual Firebase end-to-end run

Web release served locally at `http://localhost:8777`; real Google Auth and Firestore project `longvita-8da7e`. Android ran the actual debug APK, without a fake Auth service or SDK Emulator. Its existing authenticated session was retained.

1. Read-only server inventory and Android Home both showed an empty inbox (`01-mobile-empty.png`).
2. Empty form displayed both required-field errors (`02-web-required.png`).
3. Entered the explicitly labeled test title/content and opened the audience confirmation (`03-web-confirmation.png`). Selecting **Hủy** preserved the draft. Independent server read still found **0 documents** (`firestore-after-cancel.json`).
4. Confirmed publication once. The form showed the disabled **Đang phát…** state, then the server-acknowledged success state (`04-web-published.png`).
5. Independent read-back found exactly **1 document**, ID `RcD18Y0qJsieDsvn0AjY`, title/content matching the form, `authorRole=admin`, `createdAt=2026-11-10T12:28:07.642Z`, and no extra fields (`firestore-after-publish.json`). This administrative read is only a read-back check; the write itself used the Web's signed-in Firebase client and its transaction.
6. Android Home was left open on its existing listener throughout publication. It replaced the empty state with the same title/content without navigation or refresh (`05-mobile-realtime.png`).

The one clearly labeled test announcement remains in Firestore. No recipes, plans, roles, IAM, billing or other production data were modified. No additional announcement or cleanup delete was issued.

## Deployment and ownership boundaries

- Hosting was **not** redeployed; the existing hosted URL can still contain an older release.
- Deployed rules are an older release (read-only inventory timestamp `2026-11-09T11:03:44.086074Z`). Their announcement role checks and four-field schema match this flow, but their title/content validator has not yet received CM-03's maximum-length checks. The form validates 120/2000; the canonical rules with those limits pass on Emulator. **This run does not establish deployed server-side enforcement of those limits.** No shared rules deployment was performed for CM-07.
- Live positive run used `admin`. Staff/user/anonymous negative cases were exercised against canonical Emulator rules and controlled auth tests, not with new production accounts.
- Home's announcement inbox (HD-04) is used as implemented by its owner; Profile's FCM inbox is a separate flow. No new claim that HD-04/TV-03B/CM-03 is accepted is made here.
- No changes were made to the Figma reference or Mobile presentation.

Official transaction semantics used in this implementation: [Firebase transactions](https://firebase.google.com/docs/firestore/manage-data/transactions) (reads before writes, callback retries, offline failure; UI/analytics kept outside callbacks).
