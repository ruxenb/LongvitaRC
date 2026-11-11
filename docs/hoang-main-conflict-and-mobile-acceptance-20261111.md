# Hoàng — Rà soát xung đột Git và nghiệm thu Mobile trên Samsung A15

**Ngày rà soát:** 11/11/2026
**Dự án:** PRM393 LongvitaRC — monorepo `mobile/`, `web/`, `packages/core/`
**Nhánh kiểm tra:** `feature/hoang-a15-localization-20261111` (PR #40); bản `origin/main` được fetch đến `53d7fc5` trong lượt này.

## 1. Kiểm tra conflict thật, không suy đoán từ chữ đỏ trong IDE

- GitHub hiện có **2 PR đang mở**: #40 và #41; cả hai được API GitHub trả `MERGEABLE` ở thời điểm kiểm tra.
- `git merge-tree --write-tree origin/main origin/feature/hoang-a15-localization-20261111` trả mã thoát **0** và tree hợp lệ. Thử tương tự với nhánh `fix/app-ux-and-meal-card-refinement` (PR #41) cũng trả **0**.
- `git grep` dấu `<<<<<<<`, `=======`, `>>>>>>>` trên mã theo dõi trong `origin/main` không có kết quả; `git ls-files -u` trong worktree kiểm tra rỗng.
- Merge `origin/main` mới nhất vào nhánh Hoàng hoàn thành bằng chiến lược `ort`, `MERGE_EXIT=0`. **Không force-push, reset cứng, xoá file đồng đội hoặc giả tạo resolution.**
- Nhánh `main` cục bộ trong repo cũ đã được **fast-forward an toàn** từ `3297ed6` lên `53d7fc5` sau khi chứng minh commit cũ là tổ tiên của `origin/main` (`merge-base --is-ancestor` thành công).
- Những file untracked `evidence/ui/CHARLIE-UI-01` và nhánh feature cũ được giữ nguyên; không coi file chưa theo dõi là conflict.

**Kết luận Git:** Chưa phát hiện merge conflict trên `main` hay hai PR mở ở snapshot kiểm tra. Cần fetch và đo lại ngay trước khi merge vì nhánh có thể tiếp tục thay đổi. Code không conflict vẫn có thể sai business logic, config Firebase, hoặc runtime.

## 2. Kiểm chứng kỹ thuật trên monorepo mới nhất

- `flutter pub get --enforce-lockfile` tại root: **đạt**.
- `flutter analyze --no-pub` tại `mobile/`: **No issues found**.
- `flutter test --no-pub --concurrency=1` tại `mobile/`: **483/483 đạt**.
- Bằng chứng local: `D:\PRM393\hoang_main_final_pubget_20261111.log`, `hoang_main_final_analyze_20261111.log`, `hoang_main_final_test_20261111.log`.
- Nhánh `main` trước đó có 19 lỗi Analyzer liên quan integration Gemini; phiên `origin/main` mới nhất đã khắc phục được lỗi analyze hiện tại. Điều này **không** chứng minh Gemini đã được nghiệm thu trên production.

## 3. Test Android thật

Samsung Galaxy A15 (SM-A155F), Android 16, ADB kết nối với trạng thái `device`. Những lượt smoke được kiểm tra và chụp ảnh cục bộ ở `D:\PRM393\Longvita_phone_evidence\20261111_reconnect`:
- S01 Trang chủ, S10 kế hoạch đã lưu, Tra cứu công thức, Hồ sơ, S02 sở thích ăn uống, S05 chi tiết công thức.
- Form thiếu tuổi/cân nặng báo validation đúng; 2 công thức đọc được từ ứng dụng trong lúc kiểm tra.
- Không thấy crash trong các khoảng log đã lấy; không phải bảo đảm toàn ứng dụng không crash.
- **Ảnh chứa danh tính/email không đưa lên GitHub**; dùng kết quả đã khử PII trong báo cáo này.
- Bản sửa mới trong PR40 Việt hóa tên vai trò, cấu hình từ xa, thông điệp mà không thay role code/database; test riêng Hồ sơ 60/60 trước merge, và full 483/483 sau merge.
- Chưa tuyên bố màn mới sau cài đè đã nghiệm thu cho đến khi có xác nhận ADB và ảnh thực tế.

## 4. Kiểm toán các yêu cầu HD-01 → HD-08

| Mã | Phạm vi | Bằng chứng hiện có | Còn thiếu / kết luận |
| --- | --- | --- | --- |
| HD-01 | Đóng finding từ Lab 3 | Các PR review, thay đổi UI/semantics, unit/widget test | Rà soát findings mới của PR41 và nghiệm thu đầy đủ từng finding; **chưa chốt 100%** |
| HD-02 | 10 màn và 3 luồng Flutter/Firestore | Source `mobile/`, các widget test, ảnh một số màn thật | Chưa có bộ ảnh so Figma đủ S01–S10 và E2E tất cả flow; **chưa chốt 100%** |
| HD-03 | Loading/Empty/Error/Retry | Unit/widget test, validation S02 trên A15 | Offline/retry E2E trên thiết bị thật chưa đủ; **chưa chốt 100%** |
| HD-03B | Mobile gate/role bootstrap | AuthGate, roles/rules và unit tests | Chưa có biên bản role-gate trên Firebase thực bằng tài khoản thử nghiệm; **chưa chốt 100%** |
| HD-04 | Firestore Announcement Inbox | Inbox UI, service và test; ảnh empty state | Cần Web đăng thông báo rồi xác nhận mobile realtime; **chưa chốt 100%** |
| HD-05 | Gửi thực đơn ↔ Web duyệt | ViewModel stream, status models/rules `submitted`, regression tests | Ba lượt duyệt live có timestamps và role hợp lệ còn trống ở `docs/cross-role-flow.md`; **chưa chốt 100%** |
| HD-06 | PDF offline và metadata | Code report, tests metadata, UI disable khi chưa có thực đơn | Chưa có lượt xuất PDF thật với thực đơn hợp lệ trên A15; **chưa chốt 100%** |
| HD-07 | Analytics/Crashlytics | SDK, code instrumentation và tests | Thiếu đối chiếu Firebase DebugView và Crashlytics Console; **chưa chốt 100%** |
| HD-08 | Chương báo cáo Mobile | `docs/report-hoang-mobile-draft-20261110.md`, `report/hoang-implementation-report.md` | Cần đính ảnh minh chứng đã khử PII và team chốt; đã có bản thảo nhưng **chưa ký nghiệm thu** |

## 5. ARTEMIS & dữ liệu recipes

- `e2e_test/test_flows.py`, `test_search.py`, `test_detail.py` và các script còn lại tồn tại; `python -m compileall -q e2e_test` đạt (chỉ kiểm tra cú pháp Python).
- Ở lượt kiểm tra môi trường: `e2e_test/.env` chưa tồn tại; không có `GEMINI_API_KEY` hoặc `ARTEMIS_TEST_ACCOUNT` trong env, daemon `http://127.0.0.1:8000/health` không phản hồi. **Không có bằng chứng ARTEMIS 3 lượt thực** từ lượt này; không dùng kết quả widget test thay thế.
- Ảnh đọc trực tiếp trên A15 cho thấy hai recipe được trả về, một recipe có ghi nguồn sách và dinh dưỡng ước tính từ USDA, ảnh chưa được xác minh. Dữ liệu như vậy **chưa** chứng minh mọi món đã được kiểm duyệt, đúng nguồn hoặc phù hợp cho từng người. Quy trình phê duyệt recipe tại `docs/hoang-recipe-approval-20261106.md` vẫn là rào an toàn trước khi phát hành.

## 6. Phạm vi chưa được phép gọi hoàn tất

**Không đánh dấu 26/26 task Lab 3 và toàn bộ HD-01..HD-08 hoàn thành 100%** cho đến khi có ARTEMIS ≥3 runs, video demo đủ flows, kiểm thử full real-device, đối chiếu Figma 10 màn, xác nhận Firebase role/Firestore rules/metadata và batch dữ liệu recipe được phê duyệt.

Không sửa production Firestore, không đổi role tài khoản, không tạo dữ liệu mock hoặc lời khẳng định dinh dưỡng y khoa, và không đẩy ảnh chụp nhạy cảm lên repository.

## 7. Kết quả kiểm thử cuối sau khi sửa nhãn trên Samsung A15 (11/11/2026)

- Mobile: `flutter analyze --no-pub`: **No issues found**; `flutter test --no-pub --concurrency=1`: **483/483 đạt**.
- Shared Core: Analyze **0 lỗi**, **20/20 bài test đạt**.
- Web Admin: Analyze **0 lỗi**, **69/69 bài test đạt**.
- Tất cả kết quả trên chạy ở monorepo đã đồng bộ `origin/main` commit `53d7fc5` vào nhánh Hoàng; đây là unit/widget tests, không phải ba lần ARTEMIS hoặc kiểm thử production liên vai trò.
- Android debug APK đã build và cài đè trên Samsung A15 **thành công** (`APK_BUILD=0`, `APK_INSTALL=0`), không xóa dữ liệu ứng dụng; sau khi mở app có PID. Ảnh thật xác nhận `Vai trò: Người dùng`, `Tiện ích Firebase`, `Cấu hình từ xa`, `Làm mới cấu hình`.
- Ảnh có thông tin tài khoản chỉ lưu cục bộ dưới `D:\PRM393\Longvita_phone_evidence\20261111_merged_main\profile_final.png` và `profile_config_final.png`; không thêm ảnh nhạy cảm vào Git.
- Nhánh `main` cục bộ tại `D:\PRM393\LongvitaRC` đã được cập nhật bằng fast-forward rồi checkout thành công, Git trả `main...origin/main`. Các thư mục untracked của đồng đội được giữ nguyên.
- Android build còn cảnh báo về plugin Kotlin/SDK XML tương lai, nhưng **build hiện tại thành công**; cảnh báo này không phải merge conflict.
- ARTEMIS daemon/API key/test account chưa sẵn có, live cross-role 3 lượt vẫn chưa chạy, dataset recipe chưa phê duyệt đủ. Vì vậy trạng thái toàn bộ 26 task và HD01–08 vẫn phải đánh giá theo bằng chứng, không tuyên bố đạt 100%.

## 8. Xác minh sạch sau clean build, A15 và kiểm tra hai PR (11/11/2026)

- Sau khi thay tiêu đề Hồ sơ thành **Tiện ích Firebase**, chạy Flutter clean, pub get theo lockfile và build lại từ đầu: **thành công**.
- Flutter Analyze: **No issues found**. Flutter Test chạy serial: **483/483 đạt**. Log ở D:\PRM393\hoang_final_a15_analyze.log, hoang_final_a15_tests.log và hoang_final_a15_build.log.
- Android debug APK: **BUILD_EXIT=0**. Cài lại trên Samsung A15 (SM-A155F/Android 16) bằng adb install -r: **INSTALL_EXIT=0**; PID sau mở: **16207**. Không xóa dữ liệu ứng dụng.
- Ảnh thực tế sau khi app tải hoàn tất xác nhận **Tiện ích Firebase** và **Vai trò: Người dùng**. Ảnh gốc có PII chỉ ở D:\PRM393\Longvita_phone_evidence\20261111_clean_rebuild\profile_heading_verified.png; ảnh đã cắt khu vực danh tính dùng trong Git là evidence/hoang/android-a15-20261111/profile-vietnamese-no-pii.png.
- Logcat lần smoke gần nhất: **ERROR_MATCHES=0** với ba mẫu FATAL EXCEPTION, E/flutter, FlutterError trong 1.000 dòng cuối. Không suy rộng thành đảm bảo không crash.
- Kiểm tra ghép PR #41 vào nhánh Hoàng bằng git merge-tree: **exit=0**. Main cục bộ tại D:\PRM393\LongvitaRC trùng origin/main commit 53d7fc5; index unmerged=0 và tracked diff=0. Các file untracked android/ và evidence/ui/CHARLIE-UI-01 được giữ nguyên.
- ARTEMIS thực vẫn thiếu daemon/API key/test account, live cross-role và bộ recipe đã duyệt chưa có chứng cứ. **Chưa đạt nghiệm thu toàn bộ 100%.**

## 8. Kịch bản ARTEMIS đã sửa theo giao diện mới

- Đã cập nhật e2e_test/test_flows.py, test_search.py, test_detail.py để dùng chính xác S02 Tùy chọn (nhóm tuổi/cân nặng), S03 Tạo thực đơn tuần, S04 Thực đơn tuần và Lưu thực đơn, S07 Xem nguyên liệu, S10 Thực đơn đã lưu.
- Điều hướng tab và kiểm tra chuyển sang nhãn tiếng Việt Thực đơn, Dinh dưỡng, Hồ sơ, Tra cứu công thức, Chi tiết công thức, Đổi món.
- Giữ assertions đọc ngày thực của thẻ S10, đủ các ngày của tuần và thông báo Firestore; không chỉ kiểm tra mã S04/S10 vì chúng không xuất hiện trên màn hình.
- Quan sát A15 mới: S02 và S03 hiển thị; nhưng điện thoại tự khóa (deviceLocked=1, isKeyguardShowing=true) trong lần nhấn S03. Không coi là lỗi tạo thực đơn hoặc lượt ARTEMIS đã đạt. Ảnh chỉ lưu ở D:/PRM393/Longvita_phone_evidence/20261111_merged_main, không upload vì có dữ liệu tài khoản.
- ARTEMIS vẫn bị chặn vì daemon, tài khoản test và API key chưa được cấu hình. Chỉ xác nhận cú pháp script; không tính vào ba lượt chạy chính thức.

## 9. Khắc phục S09 không Việt hóa và nguồn dự phòng không được xác minh

- Khi đối chiếu `e2e_test` với code S09, phát hiện `Book knowledge`, `Source` và thông tin dự phòng `The Longevity Diet · Phụ lục A...` không có trích dẫn trang sách xác thực.
- Đã sửa S09: tiêu đề `Kiến thức sách`, nhãn `Nguồn tham khảo` và nội dung dự phòng `Chưa có nguồn trích dẫn được xác minh cho nội dung này.`. Khi `recipe.sourceNote` có giá trị, vẫn dùng đúng dữ liệu nguồn được cung cấp, không tự thêm thông tin tài liệu.
- Thêm bài kiểm thử `mobile/test/flows/hoang_s09_source_placeholder_test.dart`: xác minh màn nguồn trống không tự gán phụ lục; bài test riêng **đạt**.
- Sau sửa S09, `flutter analyze --no-pub` tại `mobile/`: **No issues found**; `flutter test --no-pub --concurrency=1`: **484/484 đạt**. Log: `D:\PRM393\hoang_s09_full_analyze_20261111.log` và `D:\PRM393\hoang_s09_full_tests_20261111.log`.
- Cú pháp Python `e2e_test/` đã qua `compileall`; script kiểm tra đúng các nhãn UI hiện tại trên máy (không phải chạy ARTEMIS). Bằng chứng chính thức ≥3 lượt và tài khoản test vẫn đang thiếu.
- Web (69/69) và Core (20/20) đã đạt trước thay đổi S09, và hai thành phần này không bị sửa trong đợt cập nhật. Không được suy ra luồng live Firebase đã được nghiệm thu từ các test này.

## 10. Cài lại bản S09 cuối cùng trên thiết bị Android

- Đã chạy lại build Flutter debug APK từ monorepo sau chỉnh sửa S09: BUILD_EXIT=0.
- APK SHA-256 trong log build: 67ED702454E89E63F2283FFDFF21E8A9681058351B7C62DB136B3102BBBB9414.
- ADB Samsung SM-A155F Android 16 ở trạng thái device; cài đặt bằng install -r, không xóa dữ liệu, trả PHONE_INSTALL_EXIT=0 và app có PID sau khởi chạy.
- Log build ở D:/PRM393/hoang_s09_apk_build_20261111.log. Đây là bằng chứng build/cài và khởi chạy, không phải ảnh nghiệm thu riêng S09, do điện thoại tự khóa trong đợt thao tác.
- Code S09 mới có test riêng đạt và Flutter toàn bộ 484/484 đạt. ARTEMIS, ba lần cross-role Firebase thật, và đối chiếu ảnh Figma toàn bộ vẫn chưa có đủ bằng chứng để nhận 100%.


## Cập nhật phát hiện conflict mới 11/11

Kết quả không conflict ở phần trên đúng tại snapshot cũ của PR #40. Sau commit mới cập nhật kịch bản ARTEMIS trên nhánh Hoàng, kiểm tra ghép PR #40 và #41 phát hiện **hai xung đột thực** ở e2e_test/test_detail.py và e2e_test/test_flows.py. Main gốc vẫn sạch. Đây là conflict giữa hai PR nếu ghép mà không xử lý.

Đã giải quyết ở nhánh audit/resolve-pr40-pr41-20261111, commit 1df3e0d, trên worktree riêng, Mobile 485/485 + Core 20/20 + Web 69/69 = **574/574 tests đạt, Analyze 0 vấn đề**. Xem docs/hoang-pr40-pr41-conflict-resolution-20261111.md. Không merge nhánh audit trực tiếp thay cho review và nghiệm thu của cả hai PR.
