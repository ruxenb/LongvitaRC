# Longvita — PRM393 Lab 3 report draft

> Owner/editor: Thắng VLQ — SE184739  
> Status: **working draft, not the final PDF**  
> Baseline: `v1.0-rc` / `aeae4c3`, 10/11/2026

## Completion gate

This source is prepared for S8-5. Do not export or submit it as the final report
until the group supplies the missing ARTEMIS summary, final member sections,
final screenshots and public/unlisted video link.

## 1. Project overview

Longvita converts evidence-backed longevity-nutrition knowledge into a Flutter
Mobile experience for seven-day meal planning, recipes, shopping support and
local PDF export. The Final Assignment extends the same product with a Flutter
Web Admin used by staff/admin roles to manage recipes, review submitted meal
plans, publish announcements and inspect operational metrics.

The product inherits the Lab 2 persona, three core user flows, design tokens and
screen specifications. Traceability from design to Flutter is documented in
[`docs/design-traceability.md`](../docs/design-traceability.md).

## 2. Architecture and implementation

The codebase follows MVVM with one-way dependencies:

1. Screens/widgets render state and dispatch user intent.
2. ViewModels own asynchronous state and business orchestration.
3. Service interfaces isolate Firebase, local storage and platform APIs.
4. Models and the design system are shared through `packages/core`.

The monorepo contains `mobile/`, `web/`, `packages/core/`, `firebase/`, tests,
evidence and deliverables. Dependency boundaries and service contracts are in
[`docs/architecture.md`](../docs/architecture.md) and
[`docs/service-contracts.md`](../docs/service-contracts.md).

## 3. Firebase integration

The registered production project is `longvita-8da7e`; the Android application
ID is `vn.edu.fpt.longvita`. Mobile and Web have separate Firebase bootstrap
configuration while sharing models/services where appropriate.

The project integrates Authentication, Firestore, Storage, FCM, Analytics,
Crashlytics and Remote Config. Evidence must preserve the distinction between
production, Emulator and widget/unit-test results. Storage failure handling was
verified with the Storage Emulator under the Spark-plan constraint; it is not
reported as a production Storage upload pass.

## 4. Mobile application

The Mobile client implements Google sign-in, session-aware routing, meal-plan
and recipe flows, shopping support, notification history, profile functions and
local PDF export. Auth routing and Android Back behavior were smoke-tested on
the `Longvita_API_36` emulator. Accessibility and responsive checks are linked
from `evidence/a11y/` and the member worklogs.

Member-owned screenshots and the final three-flow demonstration remain inputs
to be selected for the final PDF.

## 5. Web Admin

The production Web Admin is hosted at
https://longvita-8da7e.web.app. Google OAuth allows `staff` and `admin` while a
normal `user` receives a clear access-denied screen.

The production screenshots supplied on 11/11/2026 confirm these deployed
screens and states:

- Dashboard with active recipes, submitted plans and approved plans;
- recipe data/search plus create and edit forms;
- review queue empty state;
- role-gated sign-in, including a clear denied state for a non-staff account.

Announcement publication to the Mobile inbox exists in the current source and
passes local tests, but it is not claimed as deployed production functionality
until a production screenshot and Mobile-inbox result are recorded.

Production mobile-browser screenshots demonstrate sign-in/OAuth flow, role
denial, Dashboard data, recipe data/search, create/edit forms and the empty
review queue. They do not prove successful recipe writes, archive/restore,
approve/reject, announcement deployment or a standard desktop viewport.
Mobile-browser evidence also found a responsive defect: the Recipes heading
wraps excessively and the table is clipped at narrow width. The CSS viewport
was not recorded, so this is a mobile-width observation rather than a pass for
the required `412 × 915` case. Evidence and per-image limitations:
[`evidence/web/TV-04B-20261110/`](../evidence/web/TV-04B-20261110/README.md).

## 6. Testing and AI-assisted review

Testing combines Flutter unit/widget tests, Firebase Rules Emulator tests,
manual Android/Firebase failure cases and Google ARTEMIS device automation.
The final report must insert the leader-approved test table with at least three
runs per required ARTEMIS case; a collected test or isolated successful replay
must not be presented as the complete campaign.

AI-assisted review findings, decisions and linked fixes are documented in
[`docs/code-review.md`](../docs/code-review.md). Thắng's PR #6 includes Bugbot
and Security Review evidence with accepted fixes. S7-4 remains open until Thái
An completes the leader's personal review package and confirms the final group
summary.

## 7. Failure handling and limitations

Manual failure evidence covers authentication cancellation/offline behavior,
notification permission denial, Remote Config offline behavior, Analytics
offline delivery, Crashlytics fatal/non-fatal handling and Storage Emulator
failure paths.

Known limitations at this draft checkpoint:

- ARTEMIS does not yet have a final leader-approved three-run report for every
  required case.
- Web Recipes has a source-level narrow-viewport fix but still needs a
  production deploy/retest and post-fix evidence at a recorded CSS viewport.
- Cross-role approve/reject measurements are not yet recorded for three live
  runs.
- Storage production upload is not claimed under the current Spark constraint.

## 8. Security and release audit

Leader Thái An approved the code baseline `a4eaa27`. Tag `v1.0-rc` points to
`aeae4c3`, the following documentation-only decision commit; these two SHAs are
recorded separately rather than treating the tag commit as the approved code
baseline.
Gitleaks 8.30.1 found expected Firebase client configuration plus four
Firebase Storage download-token occurrences in raw ARTEMIS evidence. The
current-tree values were redacted. Those URLs target the local Storage Emulator,
so the retained emulator dataset must be handled separately from a production
download-URL audit. The audit is recorded
in [`evidence/audit/S9-1-S9-4-20261110/`](../evidence/audit/S9-1-S9-4-20261110/README.md).

## 9. Lessons learned

- Separate production, Emulator, test fixture and documentation claims.
- Preserve MVVM boundaries so UI changes do not call Firebase SDKs directly.
- Treat AI review as a source of findings, not runtime proof.
- Keep evidence metadata and redact PII/tokens before committing screenshots or
  raw traces.
- Record failures honestly; a visible responsive defect is more useful than a
  misleading pass claim.

## 10. Missing inputs before final PDF

- [ ] Thái An: final ARTEMIS pass-rate table, DebugView/Crashlytics/Remote
  Config evidence and S7-4 review package.
- [ ] Charlie: final Auth/Storage/FCM report subsection and selected images.
- [ ] Hoàng: final three-flow subsection and selected native screenshots.
- [ ] Thắng: three live cross-role measurements and responsive post-fix image.
- [ ] Group: final demo video link, final appendix references and leader signoff.
- [ ] Security: confirm the emulator dataset disposition, audit production
  download URLs, confirm API-key restrictions and repeat the final Gitleaks scan.
