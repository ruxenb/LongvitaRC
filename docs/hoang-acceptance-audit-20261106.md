# Hoàng — acceptance audit after owner approval (2026-11-06)

**Repository:** `ruxenb/LongvitaRC`. Working copy `D:\PRM393\LongvitaRC`.
**Meaning of approval:** the requestor explicitly stated in this conversation on 2026-11-06 that they are the project approver and authorize completion/publication in the shared Firebase project. This removes the need to ask the same requestor again for permission. **It does not establish a valid Firebase session, cure missing clinical/source evidence, grant legal rights over book text, substitute for successful ARTEMIS executions, or manufacture acceptance of missing deliverables.**

## Current technical evidence

- PR #10 merged to main on 2026-11-04 (Firestore-backed flows/models and CodeRabbit fixes).
- PR #15 merged to main on 2026-11-06 (portable D:/T: environment and QA report).
- PR #17 contains researched source ledger, 2 structured recipe candidates from official Foundation menu facts cross-matched against USDA FDC SR Legacy, attribution fix, offline gates, import tool (after later commit); local **Flutter Analyze = 0 issues**, **341 Flutter tests pass**, **31 Node tests pass**. PR must still be merged and reviewed after latest commit.
- Recipe candidate `--review` passes math/schema. `--verify` rejects publication due to unresolved source and portion assumptions, missing batch approval evidence, and `publicationAuthorized=false`.
- `firebase login:list` reports 1 cached account but `firebase projects:list --json` reports `Failed to authenticate` on this machine as of 2026-11-06. No real Firestore read/write was performed.
- Android SDK platforms directory absent, ADB reports no device. The actual Hoàng ARTEMIS script cases are present but no execution record for them was found in `evidence/artemis/raw/runs.jsonl`; that collection has Charlie's auth/export/remote-config/profile cases only.

## 26-task audit

Legend: **E** = required code/document deliverable exists and tests or code review support it; **V** = implemented/partial but real acceptance evidence lacking; **B** = blocked/required artifact absent. These are *not* 26 formal task acceptances.

| Task | Class | Verification / what's still needed |
|---|---|---|
| S0-3-HD | B | D: Flutter/ADB toolchain present; Android SDK platform, accepted Google SDK licenses and connected device/emulator absent |
| S1-2 | V | Firestore schema documented; production `recipes` source/rights/nutrition still need final human factual review and import |
| S1-5 | V | Sign-in and Profile implementation exists; Figma 03/06 change was frozen; page approval needed |
| S4-1 | V | Interface/DataService/models/errors exist, 22 local rules tests pass; production data and rules consistency not verified |
| S4-2 | V | ViewModels/explicit loading-empty-error-data states exist, test green; real device and review acceptance not shown |
| S4-3 | V | Reportable plan API implemented; Charlie PDF integration acceptance not independently signed |
| S4-4 | V | S01/02/03/04/10 flow exists; need device ARTEMIS TC02–04 with real saved Firestore plan |
| S4-5 | V | S07/08 edit, positive amount, undo and persistence logic exists; native persistence proof needed |
| S4-6 | V | S05/06/09 browse/alternatives/error recovery exists; actual approved recipes and E2E required |
| S4-7 | V | Loading/empty/error/retry and regression tests exist; native offline UX confirmation required |
| S4-8 | V | Semantics in widgets; needs TalkBack focus traversal for Hoàng screens |
| S4-9 | E | Fake service and ViewModel unit tests provided; Flutter suite green |
| S4-16 | V | 360/412dp widget checks in repo; exact 14sp/contrast + real screenshots for Hoàng screens pending |
| S4-17 | V | Design traceability and Figma node deviations documented; no pixel-perfect approved match |
| S5-3 | V | Search/details/replace/shopping analytics instrumentation exists; event parameters not fully verified on DebugView |
| S6-5 | V | `test_flows.py`, `test_search.py` exist; **not executed** on ARTEMIS device |
| S6-6 | V | `test_detail.py` exists; **not executed** on ARTEMIS device |
| S6-13 | V | Hoàng regression fixes exist; no Hoàng-specific ARTEMIS discovery/retest acceptance |
| S7-1-HD | E | PR #10 merged; CodeRabbit review output on PR |
| S7-2-HD | E | Real findings and Accept/Modify decisions documented in `docs/code-review.md` |
| S7-3-HD | E | Separate fix commits and review links provided |
| S8-2 | V | `report/hoang-implementation-report.md` exists; submission screenshots need validation |
| S8-6 | V | Four-slide PowerPoint exists; screenshots/visual final review needed |
| S8-11 | B | No real three-flow video artifact found |
| S8-17-HD | E | Detailed personal `docs/worklog-hoang.md` exists and is updated |
| S9-5-HD | B | No live oral presentation, ARTEMIS demonstration or actual Remote Config edit evidence from Hoàng |

**Total:** E=5, V=18, B=3. **Not 26/26 accepted.** The team's older `docs/tasks/task-hoang.md` header remains 0/26 because its status fields are manually maintained and do not reflect implementation evidence; this audit records new factual status without fabricating final acceptance.

## Approval and publication process (owner authorization accepted; publication still blocked by fact checks)

1. Normalize only source-verified, accurately portioned ingredients. Distinguish `[web]` from `[book]`, do not quote the protected book verbatim.
2. Reconcile raw/dry/cooked masses, side dishes, salmon species, ingredient allergens and nutritional uncertainty. A USDA nutrient computation is an **estimate**, not proof of the exact physical dish.
3. Include final `approval` with reviewer name, date, evidence URL and SHA of the exact final recipes array; set `publicationAuthorized=true` only after **all** `reviewBlockers` are resolved.
4. Reauthenticate the authorized Firebase identity. Only then use `scripts/publish-approved-recipes.cjs` with an explicit project, batch hash and double acknowledgment. Script defaults to offline dryrun and permits **create-only**, never overwrite, delete, schema/rules changes or hidden updates. It verifies all document IDs absent before first write, then reads back each created document.
5. Record final Firestore operation IDs, date, identities/roles, and test real Android plan/search/shopping flows before closing remaining statuses.

## Current non-negotiable blockers

- Expired local Firebase CLI auth; reauthentication is a separate user/Google session action.
- No Android device/emulator and Android SDK platforms; cannot truthfully claim real ARTEMIS or complete video.
- Two staged recipes still have unresolved material scientific/source assumption notes; operator authorization alone cannot assert their unmeasured numbers are exact.
- Publisher expects a valid Google OAuth token from an authorized operator, not a pasted or committed service-account secret. Google Cloud IAM privileges may bypass Firestore client Security Rules, so use a least-privilege account and never assume client-side `staff` role is sufficient for OAuth administration.

**Do not mark absent device/recording outcomes as PASSED, do not silently seed dummy recipes, and do not discard Charlie's untracked UI evidence.**
