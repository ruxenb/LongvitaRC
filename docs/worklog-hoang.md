# Worklog cá nhân — Hoàng / LongvitaRC

## 2026-11-04 — Laptop ASUS (D:\PRM393)
- Reviewed 26 tasks in docs/tasks/task-hoang.md and 112-task master tracker.
- Existing D:\PRM393\LongvitaRC was an ordinary directory (without .git). Preserved it as D:\PRM393\LongvitaRC_snapshot_20261104_before_git_clone, then cloned origin/main into the requested path.
- Base main revision: 96c9f573bc29c2bbd4c9c07e6c2d98a777c29d14.
- Created development branch feature/hoang-flows-data-a11y-20261104.
- Installed Flutter 3.47.2 / Dart 3.13.2, ADB 37.0.1, FlutterFire CLI 1.4.1, Android command-line tools 22.0 and JDK 21.0.13 separately on D:.
- Drafted Firestore data schema and owner-only shopping-list rules (NOT deployed).
- Reworked DataService and ViewModels to load recipes from Firestore without sample fallback; added explicit errors/empty states and reportablePlan getter.
- Added functional S02-S10 Flutter screen implementations for meal plans, recipe details/alternatives and shopping list, keeping existing Sign-in and Profile functionality.
- Added tests for model behaviours, lost network/retry, save error, cloud edit error, checklist persistence/undo, session isolation and responsive layout.
- Initial code checkpoint commit 0dc6253 (feat(hoang): Firestore-backed meal, recipe, and shopping flows with VM tests).
- Test evidence: flutter analyze clean; full Flutter suite 294/294 passed after new session regression and responsive/widget tests 6/6 passed.
- Authored ARTEMIS test scripts for three flows, search and detail; not run without Android device/daemon.
- Found HOANG-F01: completed empty announcement stream could leave Home spinning indefinitely. Corrected empty handling in Home.
- Found HOANG-F02: an old user's unresolved shopping write could queue new user's updates. Reset per-session write queue in clearSession and added a targeted regression test.
- Inspected Figma Page 03 (Final UI) and Page 06 (Prototype) read-only; identified major structural gaps in S02/S03/S04/S05/S09. Documented source nodes in docs/hoang-figma-deviation-audit.md; no changes to frozen Figma file.
- Found HOANG-F03: RecipeModel default sourceNote invented a book attribution for records with missing citation. Fixed with empty source and regression test; commit 3c80cb2.
- Opened GitHub PR #10: https://github.com/ruxenb/LongvitaRC/pull/10; CodeRabbit returned 4 actionable findings. Fixed accessibility double-announcement, offline write timeout with uncertain-sync messaging and stable draft ID, out-of-order recipe/alternative requests, and Node slide-generation instructions. The follow-up PR review and live Android validation remain pending.
- Full local Flutter regression suite after fixes: 305/305 pass; flutter analyze --no-pub clean. Log: D:\PRM393\longvita_pr10_review_tests_20261104.log.
- Installed Firebase CLI 15.34.2 and rules-unit-testing 6.0.0 on D:. Ran Firestore Emulator locally using synthetic demo-longvita project. **22/22 security rules tests passed**, 0 failed, emulator exited normally. Reproduction: npm --prefix test/firestore test; evidence log D:\PRM393\longvita_hoang_firestore_rules_20261104.log. No production rules deployment.
- GitHub main stayed unchanged; no Firebase deployment, no fake ARTEMIS results, no fabricated UI screenshots.
- Android SDK platform/build-tools install stopped at official Google SDK licence prompt; accepting terms requires user action.

## Team coordination and unresolved verification
- Team recorded Lab 2 Figma frozen on 2026-11-02; code-side deviations documented instead of editing the Figma file.
- Review tasks S7-1/2/3 require an actual PR, AI reviewer output and distinct fix commit.
- S8 slides, final report and demo video require evidence from a real Android session; written drafts must not be called recording evidence.
- Formal task status belongs to team leader; this worklog records implementation only.


## 2026-11-04 — Android certificate verification (same laptop)
- Used JDK 21 keytool to read the existing C:\Users\ASUS\.android\debug.keystore (alias androiddebugkey); did not generate or replace a keystore.
- SHA-1 and SHA-256 saved in docs/hoang-android-sha.md.
- Compared only Android OAuth SHA-1 with the committed android/app/google-services.json: **mismatch**. Current config may be stale, so team must verify Firebase Console before changing it. No production Firebase changes performed.
- android/app/build.gradle.kts still signs release with debug signing configuration; requires team-approved release signing plan before distribution.

## 2026-11-06 — Sync main, portable environment and independent QA
- Fast-forwarded `main` from `96c9f57` to `ec576be` (53 upstream commits) in `D:\PRM393\LongvitaRC`. Preserved all untracked Charlie UI evidence folders.
- Verified PR #10 already merged on 2026-11-04. Formal completion of the 26 tasks still depends on device, Figma, Firebase and team acceptance; did not edit the master status tracker.
- Repaired `scripts/project-env.ps1` to work with existing `D:\Tools` while retaining the team's original `T:\` paths. Dot-source smoke test resolves Flutter, Dart, ADB, Java, FlutterFire and Firebase CLI.
- Ran Flutter 3.47.2/Dart 3.13.2: `flutter pub get` success, `flutter analyze --no-pub` clean, **337/337 Flutter tests pass**.
- Firestore Emulator with demo-longvita: **22/22 Firestore rules tests pass** using the local shared npm dependencies. ARTEMIS Python scripts compile successfully but were **not run against a device**.
- Android doctor remains blocked by missing SDK platform packages; ADB shows no device. Did not accept Android SDK licenses or modify production Firebase/OAuth settings.
- Created `docs/hoang-verification-20261106.md` with current evidence/blockers.
- Commit `821daf4`, pushed `fix/hoang-environment-qa-20261106`, opened PR #15: https://github.com/ruxenb/LongvitaRC/pull/15 for review. No merge performed.
