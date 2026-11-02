# Longvita - phân tích thống nhất Assignment / Lab 3

Cập nhật: **02/11/2026**. Repo triển khai: **ruxenb/LongvitaRC**, nhánh `main`, baseline kiểm tra `ae35f07e36cab9ad4843396a1c22d72c247853ea` (local khớp remote lúc kiểm tra).

**Lab 3 chính là Assignment đang triển khai.** Không tổ chức thành một bài Lab 3 và một dự án Assignment khác. Thiết kế Lab 2 đã được nhóm/giảng viên duyệt là tham chiếu UI/UX. Theo quyết định user/team 02/11, cải thiện UI trực tiếp trong code, không sửa/đồng bộ Figma; xem mục 7 và UI contract. Bộ tài liệu này thay bản kế hoạch ngày 30/10 có cách diễn đạt tách hai bài.

Bản chuẩn của ba Markdown ở `docs/coordination/` trong repo. Ba file cùng tên tại thư mục cha `Assignment/` là bản đồng bộ để người dùng mở thuận tiện; thay đổi bản chuẩn trước rồi đồng bộ bản cha. Không duy trì hai kế hoạch có nội dung khác nhau.

## 1. Các nguồn và cách giải quyết khác biệt

| Nguồn | Vai trò trong Assignment |
|---|---|
| Xác nhận người dùng | Lab 3 = Assignment; tiếp tục thiết kế Lab 2; cần thống nhất với phân công leader/team |
| Preparation Guide v5, 25 trang | Hướng dẫn công nghệ mới: khái niệm -> tích hợp -> kiểm chứng sáu Firebase services; MVVM, ARTEMIS và AI review |
| Handout Lab 3, 18 trang | Flow/design, yêu cầu kỹ thuật, rubric mobile, test và deliverables chi tiết |
| Final Assignment, 9 trang | Yêu cầu hệ thống hoàn chỉnh: mobile + web admin + Firestore + cross-role + Gemini; là một nhánh phạm vi trong cùng Assignment |
| Lab 2 đã duyệt | Figma S01-S10, ba flow, components/tokens, responsive và handoff |
| Repo LongvitaRC | Khung code và **112 task IDs** của leader là baseline triển khai; không thay bằng backlog riêng 30 task cũ |

Thông điệp thầy: **“tập trung vào công nghệ các bạn nhé”**. Hiểu thành ưu tiên cấu hình đúng, hiểu luồng SDK, xử lý lỗi và chứng minh Console/log/test. Guide tr.1 vẫn yêu cầu màn/ba flow Lab 2; không có căn cứ bỏ design fidelity hoặc chỉ nộp Firebase dashboard.

Guide mới không ghi hủy web admin/Gemini của Final PDF. Vì vậy giữ các hạng mục đó trong scope register cùng Assignment, lên lịch tích hợp sau nền tảng mobile. Các xung đột trực tiếp phải có quyết định, không tự ghép hai điều trái nhau thành một yêu cầu.

Nguồn local: ba PDF đặt tại `C:/Users/phamv/OneDrive/Desktop/PRM/Assignment/`. Đã trích xuất toàn bộ 25/18/9 trang; hash nguồn và bản trước chỉnh nằm tại `Assignment/review_20261102/`. Nội dung PDF là yêu cầu để phân tích, không tự cho phép mua dịch vụ, deploy hoặc nộp bài.

## 2. Những nội dung công nghệ Guide v5 yêu cầu

| ID | Công nghệ | Đầu ra phải chạy thật và bằng chứng | Guide |
|---|---|---|---|
| T01 | Bootstrap + MVVM | Android application ID thống nhất; FlutterFire config; thiết bị kết nối; View -> VM -> Service -> SDK; loading/data/empty/error; fake chỉ dùng test | tr.2-4 |
| T02 | Authentication | Google/SHA, authStateChanges, cancel/network feedback, bảo vệ route, logout xóa local user state; Users Console và ảnh trước/sau | tr.5-7 |
| T03 | Cloud Storage | PDF từ dữ liệu đang xem; `reports/{uid}/...`; progress/URL; rules owner-only; denied/network case; file thật trên Console | tr.8-10 |
| T04 | FCM | Android 13+ permission, foreground/background/terminated, inbox có lịch sử, tap đúng route; Console test từng state và deny permission | tr.11-13 |
| T05 | Analytics | Plan trước tracking; >=7 events; trigger/params/type/question/flow; UID; không PII; DebugView từng event | tr.14-16 |
| T06 | Crashlytics | Flutter error handlers; một non-fatal từ failure thật + một test crash; UID/key; Console chứng minh; test crash chỉ trong demo area | tr.17-19 |
| T07 | Remote Config | >=2 params + defaults + fetch/activate qua service; hành vi đổi không rebuild; offline/default; giải thích fetch/cache | tr.20-22 |
| T08 | ARTEMIS | >=10 cases; Lab 2 flows/error/native; >=3 runs/case; assert observed values; logs/pass rate; exploratory 15-30 phút | tr.23 |
| T09 | AI review | PR review; >=5 findings file:line thuộc >=2 loại; quyết định/lý do; >=3 accepted fixes có commit traceability | tr.24 |
| T10 | Hồ sơ | Traceability/architecture/Analytics plan; Console/log/review evidence; GitHub, report/slides/video | tr.25 |

Firestore là **nguồn dữ liệu nghiệp vụ được team chọn**, ngoài sáu services Guide đếm; không thay Cloud Storage bằng Firestore rồi coi là đủ sáu services.

## 3. Phân công leader đã tồn tại - giữ nguyên

| Thành viên | Số task trong repo | Phạm vi chính |
|---|---:|---|
| Thái An | 29 | Instrumentation, ARTEMIS, Analytics/Crashlytics/Remote Config và điều phối công cụ review |
| Charlie | 29 | Theme/common widgets; Auth/Storage/FCM/PDF; Sign-in/Profile/demo |
| Hoàng | 26 | Models/DataService; ba flow/S01-S10; states, semantics và Figma fidelity |
| Thắng | 28 | Kiến trúc/DI/routing, tài liệu, tích hợp, freeze và tổng hợp bài nộp |

Đã đếm **112 task rows / 112 IDs duy nhất** tại `docs/tasks/danh-sach-task-full.md`. Người dùng đã xác nhận mình là **Charlie**; tiếp tục theo 29 task Charlie được leader giao. Đối chiếu file cá nhân: Charlie/Hoàng/Thắng khớp master; file Thái An hiện có 28 rows, thiếu S0-2 so với 29 task trong master. Thay đổi ownership cần team thống nhất và ghi lại.

Các bảng task đang ghi 0 hoàn thành trong khi repo đã có skeleton. Không tự đánh dấu Done vì file tồn tại: owner cần bổ sung commit và evidence rồi đổi thành Skeleton / Implemented / Verified phù hợp.

## 4. Repo hiện tại: có gì và chưa chứng minh được gì

Đã đọc 33 Dart files, models/services/VM/screens/theme/widgets, Gradle, rules, e2e harness và các docs/tasks. Đây là static review có thêm kiểm tra dependency/analyzer/widget test được ghi riêng; không phải xác nhận đã chạy đầy đủ app/Firebase trên thiết bị.

| Phần | Hiện trạng tại baseline |
|---|---|
| MVVM/DI | Có IAuthService/IDataService/IReportService, Provider wiring, ViewState và bốn VM; Firebase helpers còn là concrete dependencies |
| UI | Có AuthGate, SignInScreen và HomeScreen thử tích hợp. Chưa có đủ mười screen triển khai riêng, ProfileScreen/navigation bốn tab theo Figma |
| Data | Có Firestore recipes/meal_plans/announcements, models role/status; chưa có catalog thực, preferences/shopping/reference persistence hoàn chỉnh trong repo |
| Theme/widgets | Có theme và Button/Card/TextField/state views; thiếu đủ chín nhóm/variants; font/màu hiện chưa khớp Lab 2 |
| Firebase | Có wrappers và rules files; không thấy google-services.json, firebase_options.dart, firebase.json/indexes/tests hoặc plugin wiring Google Services/Crashlytics đầy đủ |
| Test/evidence | Một widget test AppButton; e2e có conftest/pyproject nhưng chưa có test_*.py; evidence chỉ có .gitkeep |
| Web/AI/shared core | Chưa có Flutter Web admin độc lập, packages/core, Gemini/AI Logic/App Check, rules emulator suite hoặc cross-role proof |

Có `role`, `status` và announcements stream chỉ là chuẩn bị tích hợp; chưa chứng minh cross-role end to end. Một AppButton test pass không chứng minh app khởi động hoặc Firebase hoạt động.

## 5. Khoảng trống kỹ thuật và liên kết task

Các mã **AUD-xx** là phát hiện đối chiếu hiện trạng, không phải finding đã chạy PR review hoặc fix đã hoàn tất. File:line ở bảng tham chiếu baseline `ae35f07` trước khi chỉnh docs.

| ID / Ưu tiên | Phát hiện có bằng chứng tĩnh | Cách xử lý / owner / task |
|---|---|---|
| AUD-01 / P0 | `e2e_test/conftest.py:17,26,38`: thiếu SDK sẽ dùng DummyArtemisClient trả SUCCESS và data rỗng; import hiện khác README upstream | Fail setup rõ khi thiếu SDK/model/device; dùng client thật theo commit pin; Thái An, S6-2/S6-8/S6-9 |
| AUD-02 / P0 | `docs/test-plan.md:25-35` điền sẵn 3/3; `docs/code-review.md:13-18` dùng commit mẫu và file chưa có; evidence chỉ .gitkeep | Đánh dấu Planned/template; không tính đạt; lưu raw run/PR output trước tổng kết; Thái An/Thắng, S6-3/S6-9/S7-4 |
| AUD-03 / P0 | Android app ID là `vn.edu.fpt.longvita.longvita` tại Gradle:19; e2e và lệnh Analytics dùng `vn.edu.fpt.longvita`; config Firebase chưa có | Chốt một ID rồi đồng bộ Console/SHA/Gradle/ADB/ARTEMIS; Charlie + Thắng, S3-1/S3-2/S3-6 |
| AUD-04 / P0 | `main.dart:35-41` catch Firebase init rồi vẫn tạo SDK instances; chưa có config/plugin files cần thiết | Bootstrap có configured/error state thật; không nuốt lỗi rồi giả app đã sẵn sàng; Charlie/Thắng, S3-1/S2-2 |
| AUD-05 / P0 | `meal_plan_viewmodel.dart:44,131` fallback recipes hard-coded khi catalog rỗng; ingredients của mẫu rỗng | Bản nộp dùng catalog có nguồn; empty phải ra empty/recovery; Hoàng, S1-2/S4-1/S4-4/S4-7 |
| AUD-06 / P1 | `home_screen.dart:159,165` hard-code tuổi/cân nặng, luôn báo generate thành công sau await; `data_service.dart:104,139-147` nhận mealsPerDay nhưng không dùng để tạo đủ số bữa | Dùng preferences/form thật; success theo VM result; kiểm tra 7 ngày và đúng số bữa; Hoàng, S4-2/S4-4 |
| AUD-07 / P1 | `home_screen.dart:23,221` gọi data service từ View và StreamBuilder che error thành empty | Chuyển stream/state/error/retry sang VM; Thắng/Hoàng, S2-1/S4-2/S4-7 |
| AUD-08 / P1 | `ingredient_viewmodel.dart:77` checkbox chỉ trong list RAM; VM toàn cục và FCM messages chưa có clear theo session | List-scoped persistence, cancel subscriptions/reset state khi logout; Hoàng/Charlie, S4-5/S3-5/S4-12 |
| AUD-09 / P1 | `notification_service.dart:22,29` chỉ onMessage/onMessageOpenedApp; chưa có cold-start initial message/background lifecycle, route target/persistent inbox | Xử lý đủ ba states, dedup, auth-aware routing, permission state; Charlie, S4-12/S4-13/S4-15 |
| AUD-10 / P1 | `analytics_service.dart:34` log weight_kg/age; parameter names khác analytics-plan; logout chưa clear analytics/crash identifiers; RC score/ratio getters chưa chứng minh hành vi | Hợp nhất event contract; giảm dữ liệu hồ sơ không cần thiết, UID lifecycle; chọn hai params không tạo module sức khỏe mới; Thái An + owners, S5-1..S5-9 |
| AUD-11 / P1 | `firestore.rules:41,68` admin có thể đổi role của chính mình; owner draft update chưa khóa uid/status/schema | Validate allowed keys/types, immutable owner, status transitions và cấm tự đổi role; emulator allowed/denied; Hoàng/Thắng phối hợp Charlie, S1-2/S2-1 và SYS-02 |
| AUD-12 / P1 | `app_theme.dart:11` Inter; `app_colors.dart:21` nền #F9FAEF; Figma nền #F6F1E7, Fraunces/Newsreader/Quicksand; Home có text 11/13 | Khôi phục semantic tokens/fonts/layout, đủ widgets và >=14sp body; Charlie/Hoàng, S2-3/S2-4/S4-16/S4-17 |
| AUD-13 / P1 | `profile_viewmodel.dart:70` tên file mới theo timestamp mỗi retry; PDF mới là bytes, không có local/share/metadata flow đầy đủ | Export ID/revision ổn định, tách generate/local/share/upload, preserve errors và PDF tiếng Việt; Charlie, S4-10/S4-11 và SYS-01 |
| AUD-14 / P1 | README gọi HEAD là pinned commit, tool versions khác máy, docs/architecture cam kết migration <=10% không đo | Pin SHA thật, ghi SDK/lockfile và evidence; bỏ cam kết % chưa đo; Thắng/Thái An, S0-3-*/S2-5/S6-2/S8-16 |

Trong generator/PDF hiện có công thức calorie/protein và lời khẳng định theo sách chưa kèm reference đủ. Đây là **gap nguồn nội dung**, không xác nhận quy tắc dinh dưỡng. Không tự phát minh thêm công thức hoặc gọi AI để xác nhận thay nguồn sách.

## 6. Phạm vi toàn Assignment và những quyết định chưa thể tự thay đề

| Hạng mục | Quy định nguồn | Trạng thái phối hợp |
|---|---|---|
| Mobile + sáu services + ARTEMIS/review | Guide v5 + Handout Lab 3 | Core bắt buộc hiện tại; đi theo 112 tasks |
| Web admin | Final tr.4-5: sign-in, management, review queue, dashboard >=3 aggregation figures + chart, announcement form | Giữ trong backlog cùng Assignment; chưa có code/owner chính thức |
| Cross-role | Final: mobile submit -> staff approve/reject/reason -> mobile realtime; deployed 3 lần | Model/status đã có khung, chưa có flow chứng minh |
| Gemini | Final: AI Logic, level 2 JSON->model/user confirm, App Check, model/prompt/on-off Remote Config, fallback, ba events | Chưa có code; dự kiến hỗ trợ S06 thay món thay vì tạo chatbot riêng |
| Rules/shared package | Final: roles, schema/transitions, allowed/denied mỗi role/collection, App Check, MVVM hai clients/shared core | Core-ready là nền; không coi đã đạt shared package hoặc security test |
| **DEC-01 Storage** | Guide tr.8-10 và Handout bắt upload; Final tr.3 loại Storage, chỉ local/share PDF + Firestore metadata | Xung đột nguồn thật. Theo hướng dẫn mới vẫn giữ upload core; tách adapter/policy. Leader chốt với thầy cách áp dụng Final exclusion/billing; không tự bỏ upload |
| **DEC-02 Deliverables** | Guide tr.25/Handout: report 8-12tr, slides 12-15, video 5-10p; Final: report 10-15tr, slides 12-15, video 8-12p + web URL | Cùng Assignment, không tự yêu cầu hai bộ nộp. Tạm chuẩn bị report 10-12tr, slides 12-15, video 8-10p nằm trong cả hai khoảng; nội dung vẫn phủ scope được chốt |
| **DEC-03 Tên/ID/version** | Repo LongvitaRC tồn tại; handouts dùng template tên; README/runtime/e2e IDs khác | Giữ repo hiện tại; leader quyết định tên nộp và ID; không tự rename repo/đổi SDK |
| **DEC-04 Scope/owner phần hệ thống** | Final PDF có yêu cầu chưa xuất hiện trong 112 task mobile | Thái An/Thắng điều phối bổ sung SYS-01..SYS-06, không tự gán việc hoặc coi optional |

“Tạm chuẩn bị” là phương án làm tài liệu, không phải diễn giải thầy đã thay rubric. Deadline, số commit/số ngày trong PDF còn placeholder: không tự điền. Nhóm/Lab 2 đã được duyệt theo người dùng; chỉ ghi bổ sung quyết định scope đang mâu thuẫn.

Firebase official docs được kiểm tra lại 02/11: Storage yêu cầu Blaze từ 03/02/2026. Câu “Spark đủ” trong repo/Handout cần điều chỉnh kỳ vọng. Chưa kiểm tra billing project của nhóm và chưa nâng plan. Nguồn: https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024

ARTEMIS upstream hiện minh họa `from artemis_client import ArtemisClient`, endpoint host, device_serial/default_profile; không dùng Dummy SUCCESS làm bằng chứng. Khi setup phải pin commit/API thực, Flash regression, Pro exploratory; profile không đồng nghĩa tên model cụ thể. Nguồn: https://github.com/google/artemis

## 7. Liên hệ với thiết kế Lab 2

Figma: https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design

Baseline đã kiểm tra trực tiếp ngày 30/10: 10 màn 360x800, 10 QA 412x915, 9 state frames, 64 variables, 81 main components, ba prototype starts. Lượt này dùng baseline đã duyệt và docs/repo; **chưa audit lại live Figma ngày 02/11**.

| Flow | Screen IDs | Contract khi code |
|---|---|---|
| Lập/lưu | S01 -> S02/S03 -> S04 -> S10 | Preferences thật, đủ 7 ngày/số bữa, save/reopen, error/retry giữ draft |
| Nguyên liệu/đi chợ | S04 -> S07 -> S08 | Gộp unit tương thích, edit/validation, delete/Undo, checked theo list |
| Tra cứu/thay món | S04 -> S05 -> S09/S06 -> S04 | Citation đúng, Back theo origin, cancel/error giữ món cũ, totals cập nhật |

**Quyết định user/team cập nhật 02/11/2026:** Figma là mẫu tham chiếu đóng băng; Sign-in/Profile/demo/inbox, web layout và các cải tiến UI thực hiện trực tiếp trong code, cùng design system. Ghi khác biệt/lý do/screenshots và review trong repo; không sửa/đồng bộ Figma hoặc bắt audit live lại từng thay đổi. Code/runtime được PM/user chấp nhận là baseline UI hiện hành; dashboard thử tích hợp chưa mặc nhiên được chấp nhận. Giữ flows/nghiệp vụ và owner; các câu yêu cầu cập nhật Figma trong tài liệu nguồn không phải lệnh thực thi hiện hành, chưa có xác nhận giảng viên đổi rubric. Xem [UI contract](FIGMA_IMPLEMENTATION_CONTRACT.md). Timeout prototype 1000ms là mô phỏng, app chờ tác vụ thật.

## 8. Thứ tự xử lý được thống nhất trong tài liệu

1. Chốt app ID/Firebase config/dependency versions và chuẩn hoá các template chưa có evidence.
2. Hoàn thiện interfaces/state/ownership và theme/widgets cùng baseline Figma.
3. Một flow thật từ preferences đến Firestore/save/reopen, có errors và logs.
4. Flow 2/3, persistence, export/FCM và instrumentation đủ sáu services.
5. ARTEMIS thật, rules/failure checks, AI PR review/fixes và evidence.
6. Tích hợp SYS workstreams web/cross-role/AI/shared core theo Final trong cùng Assignment; quyết định xung đột được ghi trước nghiệm thu.

Chỉ có code được ghi **Skeleton/Implemented**; chỉ có run/Console/evidence phù hợp mới ghi **Verified**. Chưa suy ra một tỷ lệ hoàn thành toàn dự án từ số file.

Xem [kế hoạch triển khai](LONGVITA_LAB3_IMPLEMENTATION_PLAN.md) và [QA/evidence](LONGVITA_LAB3_QA_AND_EVIDENCE_PLAN.md). Kết quả lệnh kiểm tra thực tế nằm trong `verification-20261102.md` cùng thư mục.
