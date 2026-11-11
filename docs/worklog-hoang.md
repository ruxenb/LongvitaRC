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

## 2026-11-06 — Recipe-source intake, registered debug SHA, and publication approval
- User supplied Firebase Console evidence for `longvita-8da7e`/`vn.edu.fpt.longvita` showing existing ASUS debug SHA-1 and SHA-256 registered; corrected previous assumptions in `docs/hoang-android-sha.md` and `docs/hoang-firestore-schema.md`. The checked-in OAuth fingerprint comparison only indicated potentially stale config; Android sign-in still needs runtime validation.
- Reviewed the active recipe/ingredient models, Firestore rules, local project, prior UX repository, accessible Drive and related email. No reviewed import-ready recipe catalog or explicit batch publication approval was located. No production collection read/write was performed.
- Identified official potential recipe and food composition sources (Valter Longo Foundation, Vietnam National Institute of Nutrition lookup, USDA FoodData Central). None implies team-approved exact recipe data.
- Added `docs/hoang-recipe-approval-20261106.md` with exact current Firestore field mapping, per-serving nutrition provenance, reviewer checklist, rights and source gates, and no production dataset.
- Implemented a read-only `scripts/validate-recipe-intake.cjs` with batch hash and explicit approval gate; seven synthetic test-only unit scenarios in `test/firestore/recipe_intake.test.cjs` all pass. No data seeds or Firebase writers were added.
- Opened approval request https://github.com/ruxenb/LongvitaRC/issues/16 to obtain approved recipe IDs, citations, numerical values and permission for the exact batch and writer role. Until team responds, collection writes remain blocked.

## 2026-11-06 — Primary USDA numeric validation of Valter Longo Foundation meal components
- Independently fetched USDA FoodData Central SR Legacy JSON API `/fdc/v1/food/{id}` for nutrient 1008 kcal and 1003 protein for IDs `169745, 172420, 170150, 171413, 175167, 172688, 169986, 170567, 170273`. Original primary source URLs are attached to each staged ingredient; did not invent nutrition data.
- Matched two component-based meals in Fondazione Valter Longo official 2020 sample diets: spelt + dry lentils + sesame + olive oil; salmon + whole-wheat bread + cauliflower + olive oil. Stored exact source quantities and explicit modeling assumptions in `docs/hoang-staged-usda-recipes-20261106.json`. Computed under those assumptions **578.11 kcal/25.1735 g protein** and **582.60 kcal/43.185 g** per source-based main component, excluding unquantified/variable sides and desserts. These are computed estimates, not exact cooked-meal lab results.
- Added author-web-site chocolate/almond dessert candidate (500 g + 500 g, 20 pieces) with **294.25 kcal/7.235 g** per 50 g unit only on the explicit assumption that chocolate uses USDA 70–85% cocoa entry. Dessert intentionally lacks any `firestore` payload due to unsupported category.
- Corrected Analytics `isBookCitation`: previously any nonempty `sourceNote` incorrectly claimed a book citation; now only explicitly `[book] `-prefixed values count. Official websites are marked `[web]`; unmarked old notes are unknown. Added Flutter tests.
- Hardened offline review validator in response to verified CodeRabbit findings: reject template placeholders; require conversion rationale + manual-review link when edible weight differs from grams; fail shared-publication verify while `reviewBlockers` remain. Extended test matrix.
- Updated source/field crosswalk and calculated evidence in `docs/hoang-usda-direct-validation-20261106.md`. Updated test instructions in `docs/hoang-recipe-approval-20261106.md`.
- `--review` is a **structural/math pass only**, while `--verify` **deliberately fails** absent external approval. Issue #16 has no independent team authorization as of check. **No production Firebase changes.**

## 2026-11-06 — Requestor approval, main integration, and guarded Firestore publisher
- The requestor stated they are the project approver and explicitly authorized completion/publication to the shared Firebase project. This removes the requestor-permission dependency, **not** the factual/source quality or credential/device checks.
- Merged PR #15 into main at `9997f1c` after CodeRabbit success. Reintegrated that main update into the Hoàng recipe branch via conflict-resolved merge `48f1a53`, preserving both worklog additions and Charlie untracked evidence.
- Verified main-integrated branch locally: Flutter analyze 0 issues; Flutter test 341 passed; Node review/validator tests 25 passed.
- Cached local Firebase CLI login exists but `firebase projects:list --json` fails `Failed to authenticate`, so no production project access is available to the session. ADB shows zero devices, Android SDK platform packages absent.
- Built `scripts/publish-approved-recipes.cjs` as an explicit-acknowledgment, SHA-verified, create-only Firestore REST publisher. Default is local dry-run; publication is blocked if reviewBlockers, owner approval evidence or credential/target arguments are missing. It preflights document IDs and reads back newly created values. No overwrite/delete/deploy function exists.
- Added `test/firestore/recipe_publisher.test.cjs` with mock network safety/integrity tests; **31/31 Node tests pass** after fixing CLI flag mapping. Real production write **not attempted** due expired CLI credentials and source assumptions.
- Created `docs/hoang-acceptance-audit-20261106.md` to distinguish 5 technically evidenced items, 18 partially implemented/unaccepted and 3 blocked deliverables; did not falsely mark 26/26 complete.

## 2026-11-08 — Main sync and Hoàng a11y/S05 follow-up
- Connected to authorized ASUS Windows device, fetched `origin/main`, and fast-forwarded local `D:\PRM393\LongvitaRC` from `c4e8024` to `4f3fd07` (PR #19). Preserved all untracked Charlie UI evidence; the separate `D:\PRM393\longvita` folder was not changed.
- Audited the 26 tasks in `docs/tasks/task-hoang.md`, the 2026-11-06 acceptance audit, GitHub issue #16, PR #10/#15/#17/#18, and latest merge #19. No independent certification of 26/26 was found.
- Created `fix/hoang-a11y-20261108`; corrected headings and loading announcements for Hoàng's screens, added S05 Firestore HTTPS image hero with honest fallback, and added widget regression tests.
- Baseline main: Flutter analyze 0 issues, full Flutter suite 388/388; first updated check: Flutter analyze 0 issues, full suite 390/390, 31/31 offline Node recipe/publisher tests. Firestore Emulator with synthetic `demo-longvita` passed 22/22 after setting `NODE_PATH=D:\Tools\LongvitaFirebase\node_modules`; first attempt failed solely because the local Node dependency path was not configured.
- Flutter doctor still reports no installed Android SDK platform and no connected ADB device. Real Hoàng ARTEMIS runs, native video, live Firebase recipe publication and Figma visual approval remain unverified. No Firebase production writes or rules deployments were made.

## 2026-11-09 — Merge PR #20 và xác nhận lại chất lượng `main`
- Đã merge [PR #20](https://github.com/ruxenb/LongvitaRC/pull/20) sau khi CodeRabbit pass; merge SHA `934b7f4`, nhánh `main` trên máy đồng bộ bằng `git pull --ff-only origin main`. Giữ nguyên mọi thư mục evidence/UI chưa track của Charlie.
- Kết quả `main`: 398/398 Flutter tests pass; `flutter analyze --no-pub` 0 issues; E2E Python compileall pass. Không gọi kiểm thử fake service là bằng chứng E2E Android.
- Kiểm tra lại S0-3: JDK Temurin D: sử dụng được nếu nạp `scripts/project-env.ps1`; Android SDK platforms/build-tools/emulator/licenses đều trống, ADB không có thiết bị. Firebase CLI vẫn hết xác thực. Không chấp nhận thay người dùng giấy phép SDK và không chạm production Firebase.
- Cập nhật `report/hoang-implementation-report.md` để sửa trạng thái cũ của PR #10, SHA debug/Firebase và thêm bằng chứng đúng của PR20; không tự chấp nhận 18 task còn chờ nghiệm thu hoặc 3 task bị chặn.
- Bổ sung `uv` bản 0.13.7 tại `D:\Tools\uv` và Python virtualenv của `e2e_test` (không đưa vào Git); `uv sync --python 3.12` cài thành công ARTEMIS client pinned commit `351ca84` và các phụ thuộc. `pytest --collect-only -q` thu thập đủ 18 test, không chạy E2E thật. Thêm tìm kiếm thư mục `uv` vào `scripts/project-env.ps1` để sử dụng được CLI trong những phiên PowerShell mới.


## 2026-11-11 — Native QA Samsung A15 và sửa lỗi giao diện từ chứng cứ thật

- Kết nối Samsung A15 Android 16, kiểm tra ứng dụng trên tài khoản user thực. Mở S02 → S03 → S04, tạo thực đơn dùng công thức hệ thống có ghi chú nguồn, bấm lưu thành công theo phản hồi client Firestore; chưa xác minh S10 read-back.
- Mở S05 chi tiết, S06 thay món. S06 không có phương án phù hợp hiển thị Empty/Thử lại, bấm Điều chỉnh sở thích trở về S02. S01 hiển thị thông báo CM-07 có sẵn từ Web Admin, chưa đo thông báo mới realtime.
- Phát hiện UI: S04 nhãn Đang chờ chen tên món và sourceNote quá dài; S05 có nhãn English và row nguyên liệu chiều cao cố định. Sửa 3 file mobile/lib/screens/meal_flow_screens.dart, recipe_flow_screens.dart và viewmodels/meal_plan_viewmodel.dart; không sửa schema/record production.
- Thêm 2 widget regression tests cho S04/S05 tên dài ở 360dp, chữ 200%. Chỉnh 4 expectation A11y cũ sang nhãn tiếng Việt mới, vẫn giữ assertion.
- Kiểm tra: Flutter Analyze 0 vấn đề; Mobile tests 487/487 đạt; Android APK build thành công. Cài đè APK mới bằng ADB thành công, PID 28804, logcat smoke 0 dòng báo lỗi Flutter nghiêm trọng.
- Ảnh đã cắt danh tính tại evidence/hoang/android-a15-20261111; biên bản docs/hoang-native-acceptance-20261111.md; logs D:\PRM393\hoang_a15_final_*. Ảnh raw PII không commit.
- Tạo lại 4 slide minh chứng thực tế: slides/Longvita_Hoang_4_Slides_Verified_20261111.pptx.
- Còn thiếu ARTEMIS live 3 lần/ca, Web Staff review realtime, Figma đủ 10 màn, PDF/video và kiểm định recipe; không ghi 26/26 hoàn thành.

- Bổ sung riêng nhãn Nguồn tham khảo và toàn văn sourceNote ở S05 khi S04 đã cắt ghi chú quá dài. Chạy lại full suite 487/487, analyze 0 vấn đề, build APK thành công. Tại lần kiểm tra cuối USB ADB mất kết nối, chưa chụp/cài APK của thay đổi S05 sau cùng.


## 2026-11-11 — Hợp nhất PR #41 đã merge main và audit ARTEMIS thực

- Khi push commit Hoàng 4aa85ff, Git từ chối non-fast-forward do remote PR40 đã cập nhật main, gồm PR41 merge 706ffef. Không force push, fetch và đối chiếu đầy đủ ba phía.
- Giải quyết hunk S04, bảo tồn calo/đạm từ PR41 và sourceNote 2 dòng của Hoàng; merge commit 4030f63. Không có unmerged files.
- Kiểm thử bản ghép: Mobile 487/487, Core 20/20, Web 69/69; tổng **576/576 pass**, Flutter Analyze 0 vấn đề cả ba, Python compileall e2e_test thành công. Logs lưu D:\PRM393\hoang_pr41_merged_*.
- Phân tích 45 run log ARTEMIS từ main: 11 bản ghi thuộc Hoàng, 8 completed/3 failed, chưa ca nào có >=3 completed. Không gọi completed là pass nếu replay/goal chưa xác nhận; xem docs/hoang-artemis-run-audit-20261111.md.
