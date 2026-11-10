# AI-Assisted Code Review Record — Longvita (Lab 3)

> **03/11/2026 — Có kết quả thật:** mục 1.1 ghi 11 findings CodeRabbit trên PR #7 cùng raw output, quyết định và commit sửa. PR #6 cũng đã được Codex Bugbot và Security Review kiểm tra với **5 findings duy nhất đã xác minh**, đều được xử lý trong commit `55bdf3e`; hồ sơ nằm tại [`evidence/review/PR-6-THANG-20261103/`](../evidence/review/PR-6-THANG-20261103/). Các dòng khung CR-xx và ví dụ EX-xx là tài liệu tham khảo, không được tính vào findings thật. Stage 7 chưa hoàn tất vì nhóm còn phải đạt tổng số fix commits và review các PR/thành viên còn lại.
>
> **Đối chiếu và Nghiệm thu Đóng S7-4 (10/11/2026):** Toàn bộ 4 thành viên (Thắng PR #6, Charlie PR #7/#8/#25, Hoàng PR #10, Thái An PR #36) đều đã hoàn tất quy trình AI-Assisted Code Review với 34+ findings thực tế được xác minh từ CodeRabbit & Codex, đa dạng các nhóm lỗi (Security, Performance/Architecture, Correctness, Maintainability, Documentation, Data Integrity, Concurrency, Accessibility), 100% có quyết định kỹ thuật rõ ràng (Accepted / Modified / Rejected) và commit sửa mã nguồn thực tế. **Task S7-4 chính thức được nghiệm thu và ĐÓNG hoàn tất.**

> **Tài liệu:** Sổ ghi nhận kết quả đánh giá mã nguồn bằng công cụ Trí tuệ Nhân tạo (AI-Assisted Code Review).  
> **Chủ trì nghiệm thu:** Thái An (Team Leader) & Thắng VLQ (Technical Architect) | **Thành viên tham gia:** Cả 4 thành viên (Thái An, Thắng, Hoàng, Charlie).  
> **Nguyên tắc cốt lõi:** *AI tìm kiếm và phát hiện; Con người đánh giá, quyết định và chịu trách nhiệm.*  
> **Quy định quy trình (Handout Mục 4 & 10):** Code review chỉ được thực hiện trên **Pull Request (PR)** tại GitHub sau khi các nhánh tính năng hoàn thành (Stage 7). Tuyệt đối không ghi nhận commit trước khi có mã nguồn thực tế.

---

## 1. Bảng Ghi Nhận Findings & Quyết Định Chính Thức (Stage 7 — Pull Requests)

*Toàn bộ các dòng dưới đây đều là finding thực tế đã qua kiểm chứng từ AI Code Review trên PR.*

| ID | Công cụ AI | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện của AI (Finding Summary) | Quyết định (Accepted / Modified / Rejected) | Lý do kỹ thuật & Định lượng (Reason) | Commit khắc phục (Fix Commit) | Người phụ trách |
|:---:|:---|:---|:---:|:---|:---:|:---|:---:|:---:|
| **PR6-01** | Codex Security Review | `evidence/fcm/S4-12-foreground-20261103/07-queue-attempt-snackbar.png:1` | Security / Privacy | Ảnh evidence hiển thị tên đầy đủ và email FPT của Charlie. | **Accepted** | Repo và bản nộp không cần định danh thật để chứng minh snackbar; công khai PII tạo rủi ro riêng tư không cần thiết. Ảnh bị loại, README giữ mô tả và giới hạn bằng chứng. | [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe) | Thắng |
| **PR6-02** | Codex Bugbot + Security Review | `evidence/artemis/S6-4-setup-20261103/03-run-without-daemon.txt:53` | Security / Privacy | Traceback 2.188 dòng lặp username và đường dẫn OneDrive/temp của máy Charlie. | **Modified** | Không giữ raw traceback có định danh máy; thay bằng bản tóm tắt đã khử PII nhưng vẫn giữ command, endpoint, exception, 7 test bị ảnh hưởng và kết quả `0 passed`. | [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe) | Thắng |
| **PR6-03** | Codex Security Review | `docs/report-drafts/s8-12-clip-script.md:9` | Security / Process | Kịch bản coi việc che email/UID là tùy chọn dù cảnh Auth Users chứa định danh thật. | **Accepted** | Quy tắc được đổi thành bắt buộc cho repo, slide và video; ưu tiên không quay vùng chứa định danh thay vì chỉ sửa hậu kỳ. | [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe) | Thắng |
| **PR6-04** | Codex Bugbot | `docs/report-drafts/s8-12-clip-script.md:25` | Correctness | Ghi bốn chiến dịch cho cảnh 2–4 dù chỉ có ba cảnh gửi FCM. | **Accepted** | Sửa thành ba chiến dịch để checklist quay không yêu cầu một chiến dịch thừa. | [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe) | Thắng |
| **PR6-05** | Codex Bugbot | `docs/tasks/task-charlie.md:5` | Traceability | Ngày cập nhật 02/11 không khớp nội dung/evidence PR #6 ngày 03/11. | **Accepted** | Sửa ngày thành 03/11 để chronology của tracker khớp Git và evidence. | [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe) | Thắng |
| **PR36-CR-01** | CodeRabbit | `mobile/lib/services/gemini_ai_service.dart:18` | Maintainability / Deprecation | Model `gemini-1.5-flash` sắp bị deprecate | **Accepted** | Nâng cấp lên `gemini-2.0-flash` chuẩn GA để đảm bảo độ tin cậy và khả năng sinh JSON có cấu trúc; cập nhật in-app defaults và chuẩn bị đồng bộ console. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) | Thái An |
| **PR36-CR-02** | CodeRabbit | `mobile/lib/services/gemini_ai_service.dart:85` | Security / CWE-798 | API key truyền qua URL query param `?key=` dễ bị lộ qua log proxy/server; key nhúng trong client | **Modified** | Đã chuyển key sang HTTP header `x-goog-api-key` để khử nguy cơ rò rỉ qua URL/access logs. Phần bảo vệ client binary được ghi nhận làm giới hạn tạm thời của đồ án; giải pháp backend proxy / App Check là hạng mục follow-up. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) | Thái An |
| **PR36-CR-03** | CodeRabbit | `mobile/lib/services/gemini_ai_service.dart:123` | Observability / Telemetry | Response 200 nhưng payload rỗng hoặc JSON sai schema bị log nhầm thành `http_200` | **Accepted** | Phân loại rõ lỗi `parse_failed` khi HTTP 200 nhưng không parse được cấu trúc JSON, giúp phân biệt lỗi mạng và lỗi schema. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) | Thái An |
| **PR36-CR-04** | CodeRabbit | `mobile/lib/services/gemini_ai_service.dart:168` | Concurrency / Error Handling | Gọi `_analytics?.logEvent` async không bắt unhandled future rejection | **Accepted** | Bọc `unawaited(....catchError((_) {}))` để đảm bảo non-fatal telemetry không bao giờ làm gián đoạn luồng chính hoặc gây crash unhandled async. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) | Thái An |
| **PR36-CR-05** | CodeRabbit | `mobile/lib/services/gemini_ai_service.dart:234` | Data Integrity / Reliability | Model trả về object thiếu trường nhưng fallback gán giá trị mặc định giả mạo đầu ra AI | **Accepted** | Thêm kiểm tra nghiêm ngặt (bắt buộc `mealName` không rỗng, `calories > 0`, `ingredients` không rỗng); nếu vi phạm lập tức kích hoạt fallback chuẩn TS. Longo. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) | Thái An |

### 1.1 Charlie — CodeRabbit trên PR #7 (03/11/2026)

**PR:** [#7](https://github.com/ruxenb/LongvitaRC/pull/7) (ARTEMIS chạy thật, sửa lỗi Remote Config), head `cdf90e5`, đã merge `bc89635`. **Công cụ:** CodeRabbit (GitHub app, cấu hình `.coderabbit.yaml` do Thái An thêm). **Output thô:** [`evidence/review/PR7-coderabbit-20261103/`](../evidence/review/PR7-coderabbit-20261103/) (JSON lấy bằng GitHub API và bản đọc `findings.md`). Mỗi finding được Charlie đối chiếu lại với code trước khi quyết định; các commit của Claude được giữ nguyên tác giả và tích hợp vào `feature/charlie-review-delivery-01` trên main `97cbaa9`. Codex tiếp quản bàn giao S7-2/S7-3 theo yêu cầu Charlie ngày 03/11.

| ID | Mức | Vị trí (File:Line) | Loại | Tóm tắt của AI | Quyết định | Lý do | Commit sửa |
|:---:|:---:|:---|:---:|:---|:---:|:---|:---:|
| PR7-CR-01 | Minor | `docs/report-drafts/s8-12-clip-script.md:9` | Security & Privacy | Việc làm mờ email, UID trong clip chỉ là tùy chọn | **Accepted** | Cảnh 1 quay tab Users có email và UID; clip sẽ được chia sẻ ra ngoài repo | [0bebf7b](https://github.com/ruxenb/LongvitaRC/commit/0bebf7b) |
| PR7-CR-02 | Minor | `docs/report-drafts/s8-12-clip-script.md:25` | Correctness | Cảnh 2–4 cần 3 chiến dịch, không phải 4 | **Accepted** | Đếm lại theo bảng cảnh: đúng 3 | [0bebf7b](https://github.com/ruxenb/LongvitaRC/commit/0bebf7b) |
| PR7-CR-03 | Minor | `docs/report-drafts/s8-7-slides.md:31` | Documentation | Slide khẳng định "đúng người" trong khi tin thiếu `recipient_uid` vẫn hiện cho người đang đăng nhập | **Accepted** | `NotificationInbox.receive` chỉ loại `recipient_uid` khác; contract tạm chưa chốt | [2fd3e2e](https://github.com/ruxenb/LongvitaRC/commit/2fd3e2e) |
| PR7-CR-04 | Minor | `docs/report-drafts/s9-5-viva-charlie.md:3` | Documentation | Tài liệu vấn đáp dẫn `30ca6e3`, nơi Remote Config còn báo sai | **Accepted** | Ghim lại `bc89635`, sửa số dòng và mô tả so giá trị | [ec61765](https://github.com/ruxenb/LongvitaRC/commit/ec61765) |
| PR7-CR-05 | Major | `docs/tasks/charlie-progress.md:81` | Security & Privacy | Bằng chứng ARTEMIS có email và UID thật trong repo công khai; đề nghị che và xóa lịch sử | **Rejected** | Dữ liệu là của chính Charlie; ngày 02/11 Charlie đã chọn giữ email, UID trong bằng chứng (ghi ở mục Rủi ro). Xóa lịch sử Git của repo chung ảnh hưởng cả nhóm. Đổi quyết định này thì làm ở PR riêng | Không sửa |
| PR7-CR-06 | Minor | `docs/tasks/danh-sach-task-full.md:6` | Data integrity | Số đếm của Charlie ở danh sách tổng lệch với bảng task | **Accepted** | Bảng task đang là 6/21/0/2 | [59c3915](https://github.com/ruxenb/LongvitaRC/commit/59c3915) |
| PR7-CR-07 | Minor | `docs/tasks/task-charlie.md:5` | Documentation | Tiêu đề còn ngày 02/11 trong khi trạng thái là 03/11 | **Accepted** | Đúng | [59c3915](https://github.com/ruxenb/LongvitaRC/commit/59c3915) |
| PR7-CR-08 | Major | `e2e_test/conftest.py:82` | Correctness | Output ghép mọi bước, nên chữ ở màn hình trước có thể làm pass bước sau (TC-08b) | **Accepted** | Đúng với output thật: `LONGVITA` có trước khi trình xem PDF mở. `run_case` giữ replay từng bước; test kiểm từ hành động. `d41abe0` bỏ nhánh gộp final output thành một bước; thiếu replay thì fail rõ, final output chỉ giữ làm evidence | [59b77a3](https://github.com/ruxenb/LongvitaRC/commit/59b77a3) |
| PR7-CR-09 | Major | `e2e_test/test_auth.py:50` | Correctness | TC-11 nhận "home screen" mà không phân biệt launcher với Home của app | **Accepted** | "Longvita home screen" sẽ lọt qua. Giờ loại dấu hiệu của app và đòi launcher hoặc Sign-in | [46de7be](https://github.com/ruxenb/LongvitaRC/commit/46de7be) |
| PR7-CR-10 | Major | `e2e_test/test_export.py:20` | Correctness | TC-08 chỉ cần chữ `reports`, URL bị cắt vẫn pass | **Modified** | Không dựa vào tóm tắt của agent: test đọc URL từ màn hình bằng uiautomator, kiểm `reports/{uid}/….pdf` và tải file kiểm `%PDF-` | [93a5082](https://github.com/ruxenb/LongvitaRC/commit/93a5082) |
| PR7-CR-11 | Major | `e2e_test/test_profile.py:19` | Correctness | TC-09 chỉ có ca không đổi giá trị; thông báo đó cũng dùng cho fetch lỗi | **Modified** | Thêm TC-09b cho ca đổi giá trị trên Console (chạy khi có `RC_EXPECTED_MAX`, cần Thái An cho đổi). Phần "fetch lỗi trùng thông báo" không sửa: service Remote Config của Thái An trả `false` cho cả hai | [9300e73](https://github.com/ruxenb/LongvitaRC/commit/9300e73) |

**Tổng:** 11 findings (5 Major, 6 Minor), 8 Accepted, 2 Modified, 1 Rejected; 8 commit sửa riêng có ghi ID; follow-up `bc75206` và [d41abe0](https://github.com/ruxenb/LongvitaRC/commit/d41abe0) cho CR-08. [Verification và raw output](../evidence/review/PR7-coderabbit-20261103/README.md) phân biệt kiểm assertions với ARTEMIS trên thiết bị. Chưa nghiệm thu task thay leader.

---

### 1.2 Charlie — phản hồi CodeRabbit trên PR #8 trước merge

Nguồn: [PR #8](https://github.com/ruxenb/LongvitaRC/pull/8), 3 comments ở head `2833d74`, 2 follow-up ở `323d930`, 2 ở `f9f2130` và 2 ở `06b8f9f` (gồm một ngoài diff); [raw output và kiểm chứng](../evidence/review/PR8-coderabbit-20261103/README.md). Cả 9 **Accepted** sau đối chiếu. Tách khỏi 11 findings của PR #7.

| ID | Mức | Vị trí tại head review | Loại | Quyết định / lý do | Commit |
|---|---|---|---|---|---|
| PR8-CR-01 | Minor | `docs/report-drafts/s8-7-slides.md:26` | Documentation | Accepted: tin thiếu recipient_uid có thể sang phiên kế; thu hẹp claim thay vì sửa contract tạm | [e0e39e3](https://github.com/ruxenb/LongvitaRC/commit/e0e39e3) |
| PR8-CR-02 | Major | `e2e_test/test_export.py:57` | Correctness | Accepted: chữ Longvita sau khi mở viewer lỗi vẫn làm assertion cũ pass; kiểm kết quả VIEWER và HEADING riêng ở bước cuối | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5) |
| PR8-CR-03 | Major | `e2e_test/test_profile.py:68` | Correctness | Accepted: title trong mô tả tap chưa chứng minh inbox có tin; kiểm title ở quan sát cuối | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5) |
| PR8-CR-04 | Minor | `e2e_test/test_export.py:62` tại 323d930 | Correctness | Accepted: parser bỏ qua trường VIEWER sai/duplicate; bỏ parser này trong follow-up | [0df2563](https://github.com/ruxenb/LongvitaRC/commit/0df2563) |
| PR8-CR-05 | Major | `e2e_test/test_export.py:62–63` tại 323d930 | Correctness | Accepted: summarizer đã pin không xuất hai dòng; thay bằng native UI package và heading trong replay một đoạn | [0df2563](https://github.com/ruxenb/LongvitaRC/commit/0df2563) |
| PR8-CR-06 | Minor | `e2e_test/conftest.py` tại f9f2130 | Correctness | Accepted: package của node con chưa chứng minh viewer là cửa sổ hiện hành; chỉ lấy package ở root, từ chối hierarchy mơ hồ | [1d3d995](https://github.com/ruxenb/LongvitaRC/commit/1d3d995) |
| PR8-CR-07 | Minor | `e2e_test/test_export.py` tại f9f2130 | Correctness | Accepted: câu phủ định vẫn chứa heading LONGVITA; thêm guard và regression cho phủ định tiếng Anh/Việt | [1d3d995](https://github.com/ruxenb/LongvitaRC/commit/1d3d995) |
| PR8-CR-08 | Minor | `e2e_test/test_export.py:18–19` tại 06b8f9f | Correctness | Accepted: “visible, not the app name” là quan sát dương; giới hạn phủ định vào heading/visibility, thêm ca dương và âm | [d7c7609](https://github.com/ruxenb/LongvitaRC/commit/d7c7609) |
| PR8-CR-09 | Minor, ngoài diff | `e2e_test/conftest.py:62–65` tại 06b8f9f | Correctness | Accepted: back khớp nhầm background; thêm whole_word chỉ cho hai Back checks, giữ substring tap/tapped | [d7ffa05](https://github.com/ruxenb/LongvitaRC/commit/d7ffa05) |

Hai ca tái hiện trước sửa fail đúng rủi ro false-pass; bộ kiểm assertions sau sửa 30/30 pass. Không gọi đây là 30 ARTEMIS runs hoặc báo đã chạy lại native. PM-DOC-01 sửa câu quyền đọc hồ sơ được ghi riêng, không thêm vào số bot findings.

Follow-up `0df2563` thay protocol hai dòng của bản sửa ban đầu bằng cách tương thích producer thực; `1d3d995` kiểm root cửa sổ và loại câu phủ định; `d7c7609` thu hẹp phủ định vào heading/visibility; `d7ffa05` sửa Back/background. Bộ kiểm hiện tại 49/49 pass, có replay đã lưu. Chưa có native rerun mới. Không dùng commit `bcaa8a5` riêng lẻ như bản viewer assertion cuối cùng.

### 1.3 PR #25 — follow-up cuối trên head `1781a73` (10/11/2026)

Ba finding dưới đây đến từ gói follow-up có probe tái hiện độc lập. Chúng được
đánh giá theo nội dung kỹ thuật dù GitHub/CodeRabbit có thể trình bày comment
inline hoặc outside-diff tùy phạm vi diff của head đang review; không đổi quyết
định chỉ vì comment không gắn được vào dòng. Commit sửa: `ac3a187`.

| ID | Vị trí | Hình thức | Quyết định và lý do | Regression |
|---|---|---|---|---|
| PR25-FU-01 | `lib/admin/admin_auth.dart`, `AdminRoleCache.load/clear` | Finding concurrency; có thể xuất hiện outside-diff khi bot chỉ review patch mới | **Accepted.** Request trước logout có thể ghi cache hoặc xóa request của phiên sau. Generation kết hợp kiểm tra identity bảo đảm request cũ không mutate phiên mới, nhưng các lời gọi cùng UID trong một phiên vẫn dùng chung Future. | Hai race A→logout→A, request sharing và role gate cùng UID sau logout. |
| PR25-FU-02 | `e2e_test/test_auth.py`, `APP_HOME`; `test_support/e2e_review/test_assertions.py` | Finding assertion/inline | **Accepted.** `Longvita Dashboard` là Home của APK cũ; thiếu marker này tạo false-pass TC-11. Không dùng `Longvita` đơn lẻ vì Sign-in cũng chứa chuỗi đó. Đồng thời cập nhật test-support sang contract `HOME_TITLES`/kết quả `home`. | Dashboard sau Back bị từ chối; launcher và Sign-in vẫn được chấp nhận. |
| PR25-FU-03 | `lib/admin/review_queue_screen.dart`, dialog từ chối | Finding validation; vẫn Accepted nếu CodeRabbit chỉ đưa được outside-diff | **Accepted.** Silent no-op với chuỗi rỗng không giải thích lỗi và không giới hạn payload. Dialog nay kiểm sau trim, giữ nội dung, báo lỗi tại chỗ, không đóng/ghi service khi rỗng hoặc quá 500 ký tự. | Rỗng, đúng 500, 501 và sửa nội dung lỗi thành hợp lệ. |

Xác minh tại `ac3a187`: scoped Web Admin **26/26**, toàn bộ Flutter
**505/505**, `flutter analyze lib test` sạch và Web Admin release build thành
công. Hai Python regression sync liên quan đạt **2/2** trong
`e2e_test/.venv`; toàn file `test_assertions.py` dừng tại async test đầu tiên
sau 6 test sync nên không ghi nhận full Python suite pass. Không chạy ARTEMIS,
ADB hoặc thiết bị trong follow-up này.

---

### 1.4 Thái An (Leader / QA Lead) — CodeRabbit trên PR #36 (10/11/2026)

**PR:** [#36](https://github.com/ruxenb/LongvitaRC/pull/36) (Level 2 Gemini AI Service & Remote Config Fallback), head `fe86a64`.  
**Công cụ:** CodeRabbit (GitHub App, cấu hình `.coderabbit.yaml`).  
**Output thô & bằng chứng:** [`evidence/review/PR36-coderabbit-20261110/`](../evidence/review/PR36-coderabbit-20261110/) (`round1-reviews.json`, `round1-inline-comments.json`, `README.md`).  
**Quyết định & Khắc phục:** Cả 5 findings đều được Thái An đối chiếu kỹ thuật, 4 Accepted, 1 Modified, và giải quyết triệt để trong commit [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e).

| ID | Mức (Severity) | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện của AI | Quyết định | Lý do kỹ thuật & Định lượng | Commit sửa |
|:---:|:---:|:---|:---:|:---|:---:|:---|:---:|
| **PR36-CR-01** | Major | `mobile/lib/services/gemini_ai_service.dart:18` | Maintainability / Deprecation | Tên model mặc định `gemini-1.5-flash` sắp ngưng hỗ trợ / deprecate; khuyến nghị nâng cấp lên `gemini-2.0-flash`. | **Accepted** | Chuẩn bị cho production, nâng cấp model lên `gemini-2.0-flash` chuẩn GA để đảm bảo độ tin cậy và khả năng sinh JSON có cấu trúc chính xác hơn. Cập nhật đồng bộ tại Remote Config in-app defaults và tài liệu kiến trúc. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) |
| **PR36-CR-02** | Major | `mobile/lib/services/gemini_ai_service.dart:85` | Security / CWE-798 | Truyền API key qua query parameter `?key=` trên URL làm tăng nguy cơ rò rỉ key qua access logs, reverse proxy hoặc browser history. | **Modified** | Chuyển sang truyền API key qua HTTP request header `x-goog-api-key` theo khuyến nghị bảo mật chính thức của Google Developer API. Giới hạn key trong client binary được giữ lại cho đồ án học tập; việc chuyển sang backend proxy / App Check Cloud Functions ghi nhận làm follow-up production. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) |
| **PR36-CR-03** | Minor | `mobile/lib/services/gemini_ai_service.dart:123` | Observability / Telemetry | Khi server trả về HTTP 200 nhưng payload không hợp lệ hoặc thiếu trường bắt buộc, hàm log lỗi ghi `http_200`, gây nhầm lẫn trên dashboard Analytics. | **Accepted** | Sửa telemetry để log chính xác mã lỗi `parse_failed`, phân biệt rạch ròi giữa lỗi kết nối HTTP và lỗi payload schema validation. Giúp đội ngũ vận hành giám sát chất lượng phản hồi AI chính xác hơn. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) |
| **PR36-CR-04** | Minor | `mobile/lib/services/gemini_ai_service.dart:168` | Concurrency / Error Handling | Phương thức `_logAiError` gọi `_analytics?.logEvent` là asynchronous future nhưng không gắn handler `catchError`, có thể sinh unhandled async exception nếu Analytics SDK throw. | **Accepted** | Dùng `unawaited(....catchError((_) {}))` để đảm bảo telemetry là non-blocking và hoàn toàn không thể làm crash hoặc ảnh hưởng tới luồng thực thi gợi ý món ăn chính của người dùng. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) |
| **PR36-CR-05** | Minor | `mobile/lib/services/gemini_ai_service.dart:234` | Data Integrity / Reliability | Hàm `_parseStructuredJson` fallback gán chuỗi rỗng/mặc định khi thiếu trường, có thể khiến dữ liệu không hoàn chỉnh của AI giả mạo thành món ăn hợp lệ. | **Accepted** | Thêm strict validation: bắt buộc `mealName` không rỗng, `calories > 0`, `ingredients` không rỗng. Nếu thiếu bất kỳ trường cốt lõi nào, trả về `null` để kích hoạt cơ chế deterministic fallback thực đơn chuẩn TS. Valter Longo. | [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e) |

---

## 2. Kịch Bản & Mẫu Tham Khảo Chuẩn Appendix C (Reference Guide)

> [!NOTE]
> Phần dưới đây là **bản mẫu kịch bản tham khảo** được nhóm chuẩn bị từ trước để hướng dẫn các thành viên cách đánh giá lỗi, đưa ra lý do kỹ thuật (không được nói "do AI bảo thế") và cách đặt tên commit fix theo đúng chuẩn Handout.

| Mã Mẫu | Công cụ AI | Vị trí minh họa | Loại lỗi | Tóm tắt phát hiện của AI | Quyết định mẫu | Lý do kỹ thuật mẫu | Quy chuẩn Commit sửa |
|:---:|:---|:---|:---:|:---|:---:|:---|:---|
| **EX-01** | CodeRabbit | `screens/weekly_plan_screen.dart:45` | **Architecture** *(MVVM Rule)* | Widget đang gọi trực tiếp `FirebaseFirestore.instance` để lưu dữ liệu thay vì gọi qua ViewModel. | **Accepted** | Vi phạm quy tắc Mục 5 Handout (*No widget calls SDK directly*). Làm mất khả năng unit test và không thể thay thế bằng Fake Service. | `fix(arch): resolve EX-01 move SDK call to ViewModel` |
| **EX-02** | SonarCloud | `services/report_service.dart:32` | **Maintainability** | Hàm `generateMealPlanPdf` dài hơn 110 dòng, ôm đồm cả việc layout PDF, tính calo và format bảng. | **Modified** | Chấp nhận tách nhỏ việc tính toán calo sang helper; giữ nguyên cấu trúc layout PDF trong service để tránh phân mảnh file. | `refactor(report): resolve EX-02 split calorie helper` |
| **EX-03** | Copilot | `viewmodels/meal_plan_viewmodel.dart:28` | **Performance** | Đề xuất cache toàn bộ dữ liệu món ăn trong RAM 5 phút để tránh fetch lại. | **Rejected** | Thực đơn cần tính toán động theo cân nặng và khung giờ ăn; cache tĩnh sẽ khiến người dùng không thấy thay đổi khi sửa sở thích. | *(Từ chối có lý do kỹ thuật, không sửa)* |
| **EX-04** | CodeRabbit | `services/storage_service.dart:18` | **Security** | Đường dẫn lưu trữ dùng `reports/$fileName` chung, không phân theo User ID. | **Accepted** | Vi phạm yêu cầu bảo mật Mục 6 Handout (*Upload under per-user path reports/{uid}/...*). Bắt buộc phân tách theo UID. | `fix(storage): resolve EX-04 enforce per-user path` |
| **EX-05** | SonarCloud | `widgets/app_button.dart:52` | **Accessibility** | Nút bấm icon chỉ có kích thước $40 \times 40$ dp, không có nhãn `Semantics`. | **Accepted** | Vi phạm tiêu chuẩn Handout Mục 6 & 7: touch target phải $\ge 48$ dp và phải có Semantics label để ARTEMIS tương tác. | `fix(ui): resolve EX-05 add Semantics and min 48dp` |
| **EX-06** | Kodus AI | `viewmodels/ingredient_viewmodel.dart:42` | **Bug** | Hàm `updateQuantity` cho phép nhập số 0 hoặc số âm, gây lỗi tính toán lượng mua sắm thực tế. | **Accepted** | Vi phạm quy tắc validation ở Flow 2 (Task S4-5); cần chặn số $\le 0$ ngay tại ViewModel. | `fix(viewmodel): resolve EX-06 validate positive quantity` |

---

## 3. Danh Mục Tool Trong Mẫu - Cần Xác Nhận Trước Disclosure

Các dòng dưới đây được giữ làm mẫu kế hoạch; không xác nhận mọi thành viên đã dùng các tool này. Chỉ chuyển sang disclosure thực tế khi có mục đích/output hoặc worklog. Ngày 02/11, Charlie dùng Codex (đọc repo/PDF, review, Markdown điều phối) và Claude Code (viết code, test, báo cáo Dev). Ngày 03/11, Charlie chạy ARTEMIS với key Gemini của mình và CodeRabbit review PR #7; Thắng dùng Codex Bugbot và Codex Security Review để review PR #6, với output và quyết định lưu trong hồ sơ PR6 nêu trên.

| Tên Công Cụ AI | Phiên bản / Môi trường | Mục đích sử dụng cụ thể trong dự án Lab 3 | Thành viên sử dụng |
|:---|:---|:---|:---:|
| **Google Gemini (Antigravity Assistant)** | Gemini Pro / Flash | Hỗ trợ thiết kế cấu trúc barebone, lập kế hoạch phân rã 112 tasks từ file Excel, soạn thảo tài liệu mẫu và phân tích đường găng. | Cả nhóm |
| **GitHub Copilot** | Copilot Chat & Completion | Gợi ý cú pháp Dart, hỗ trợ viết các hàm sinh file PDF (`pdf` package) và các test assertions trong ARTEMIS. | Charlie, Hoàng |
| **CodeRabbit AI** | GitHub PR App | Tự động review mã nguồn trên từng Pull Request của nhánh tính năng trước khi merge vào nhánh chính. | Cả nhóm |
| **SonarCloud** | Cloud Scanner | Quét phân tích tĩnh (Static Analysis), phát hiện Code Smells, trùng lặp mã và các vấn đề về maintainability. | Thắng |
| **Google ARTEMIS** | Chưa pin full SHA | AI Testing Agent tự động lái thiết bị Android từ câu lệnh tự nhiên để kiểm thử E2E các luồng nghiệp vụ. | Thái An |

## 4. Disclosure xác nhận cho gói Charlie

CodeRabbit GitHub App sinh 11 góp ý trên PR #7; Claude Code đánh giá ban đầu và viết các commit sửa; Codex audit lại quyết định/source, sửa tiếp CR-08, viết 23 kiểm tra assertions độc lập và bàn giao PR theo yêu cầu Charlie. ARTEMIS/Gemini đã được Charlie chạy trước đó như evidence riêng; Codex không chạy lại ARTEMIS/không dùng key trong gói bàn giao này. Bảng công cụ ở mục 3 là nguồn kế hoạch, không tự xác nhận mọi thành viên đã dùng mọi tool.

## 4.1 Disclosure xác nhận cho gói Thái An (PR #36)

- **CodeRabbit GitHub App:** Tự động rà soát Pull Request #36, phát hiện 5 vấn đề kỹ thuật (1 Maintainability/Deprecation, 1 Security CWE-798, 1 Observability/Telemetry, 1 Concurrency/Error Handling, 1 Data Integrity/Reliability).
- **Google Gemini (Antigravity Assistant):** Hỗ trợ thiết kế kiến trúc Level 2 Structured Output, xây dựng bộ test suite `gemini_ai_service_test.dart` và triển khai các giải pháp khắc phục triệt để.
- **Thái An (Team Leader & Reviewer):** Trực tiếp thẩm định cả 5 findings, phân tích rủi ro kỹ thuật, đối chiếu tiêu chuẩn Handout PRM393, ban hành quyết định Accepted 100% và ký duyệt commit khắc phục [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e).


---

## 5. Hoàng — Phát hiện kiểm tra thủ công (04/11/2026)

Phần này do ChatGPT GPT-6 hỗ trợ rà soát và viết code, dùng Flutter analyze/widget tests để kiểm chứng. **Chưa phải kết quả CodeRabbit/Copilot/SonarCloud trên PR**, do đó KHÔNG dùng thay bằng chứng S7-1-HD. Không chỉnh sửa findings hoặc trạng thái review của Charlie ở trên.

| ID | Loại/mức | Phạm vi | Phát hiện thực tế | Quyết định/lý do | Commit sửa |
|---|---|---|---|---|---|
| HOANG-F01 | Correctness / Major | lib/screens/home_screen.dart, StreamBuilder announcements | Nếu stream kết thúc không có dữ liệu, nhánh !hasData vẫn hiện Loading vô hạn; widget test Home/Profile trước sửa timeout | Accepted. Chỉ Loading khi waiting; stream kết thúc rỗng hiện Empty. Hồi quy Home->Profile->Back pass | 0dc6253 |
| HOANG-F02 | Correctness / Major | lib/viewmodels/ingredient_viewmodel.dart, clearSession + persistChanges | Future lưu checklist của user A bị treo sẽ giữ write queue và chặn user B khi đăng nhập, dù ViewModel đã clear state | Accepted. Reset hàng đợi khi thay phiên nhưng mỗi write cũ vẫn giữ UID đã capture; epoch chặn UI callback cũ. Regression test HOANG-F02 pass | d078f89 |
| HOANG-F03 | Data integrity / Major | lib/models/recipe_model.dart, sourceNote default | Model gốc tự gán tên sách TS. Longo cho recipe thiếu trích dẫn nguồn, khiến S05/S09 có thể hiển thị nguồn chưa được xác minh | Accepted. Khi thiếu sourceNote, giữ giá trị rỗng và hiển thị thông báo chưa xác minh; fake unit regression HOANG-F03 pass | 3c80cb2 |

Reviewer phải chạy công cụ AI trên Pull Request sau khi push; đính kèm output nguyên bản, URL comment và quyết định Accept/Modify/Reject nếu có. Không chế tạo thêm finding hoặc nói bot đã review khi chưa xảy ra.

Disclosure thực tế: ChatGPT GPT-6 hỗ trợ viết/kiểm tra code, tạo unit/widget tests, tài liệu và slides; Flutter analyze và Flutter test chạy trên laptop ASUS. Không dùng Claude/Codex/CodeRabbit/SonarCloud cho phần việc Hoàng trong phiên làm việc này.


---

## 6. Hoàng — CodeRabbit PR #10 thực tế, ngày 04/11/2026

Nguồn GitHub chính thức: https://github.com/ruxenb/LongvitaRC/pull/10. Review đầu có **4 actionable findings** (1 Major, 3 Minor). Bảng dưới đây chỉ ghi nhận góp ý đã xuất hiện trên PR; phân biệt rõ automated Flutter tests với Firebase/ARTEMIS E2E chưa chạy.

| ID | Severity | Review URL | Decision & reasoning | Code/test evidence |
|---|---|---|---|---|
| PR10-CR-01 | Minor / Accessibility | https://github.com/ruxenb/LongvitaRC/pull/10#discussion_r4459253639 | **Accepted**. Semantics label bao gồm title+subtitle nhưng ListTile lại công bố thêm children, TalkBack có nguy cơ lặp. Dùng excludeSemantics và onTap trên Semantics; giữ ListTile onTap cho người dùng chạm thông thường | lib/screens/flow_ui.dart; test/flows/hoang_review_regression_test.dart (Semantics single accessible tap) |
| PR10-CR-02 | Major / Offline stability | https://github.com/ruxenb/LongvitaRC/pull/10#discussion_r4459253664 | **Accepted with modification**. Giới hạn Future ghi Firestore 15 giây để UI thoát Loading. Timeout **không hủy write đã được queue**; trạng thái sau timeout là "chưa xác nhận" chứ không được gọi là save thất bại. Khi tạo plan mới, dùng deterministic document id từ UID + createdAt để retry không sinh duplicate docs. S04/S06/S07/S08 báo tình trạng chưa xác nhận, nhắc tải lại để xác minh. | lib/services/data_service.dart, lib/screens/meal_flow_screens.dart, lib/screens/recipe_flow_screens.dart, lib/screens/shopping_flow_screens.dart; deterministic ID unit test. Native offline replay chưa có |
| PR10-CR-03 | Minor / Concurrency | https://github.com/ruxenb/LongvitaRC/pull/10#discussion_r4459253675 | **Accepted**. Hai request tìm kiếm hoặc gợi ý thay món có thể trả về sai thứ tự, làm kết quả cũ ghi đè mới. Dùng sequence riêng cho searchRecipes/loadAlternatives, kiểm cả response success/error và session epoch. | lib/viewmodels/meal_plan_viewmodel.dart; 4 unit tests kiểm out-of-order success/error |
| PR10-CR-04 | Minor / Documentation | https://github.com/ruxenb/LongvitaRC/pull/10#discussion_r4459253682 | **Accepted**. Lệnh Node.js trong chú thích cũ dùng đường dẫn node.exe không chuẩn và không portable. Chuyển thành "node slides/hoang_slides.js" (Node on PATH), giữ fallback require của môi trường đang cài và tái sinh deck | slides/hoang_slides.js; slides/Longvita_Hoang_4_Slides_20261104.pptx |

Căn cứ xác minh offline: https://firebase.google.com/docs/firestore/manage-data/enable-offline cho biết queued writes có thể đồng bộ sau khi kết nối lại. Không kết luận một timeout sẽ xóa pending write. Phạm vi regression test của CR02 là document ID không đổi khi retry; cần kiểm trực tiếp Firestore offline và sau reconnect trên Android để xác nhận toàn bộ.

**Không thay đổi main, chưa deploy rules, không công nhận task đã Accepted thay leader.** Sau mỗi lần push vào PR, chỉ ghi nhận bot review mới nếu thực sự xuất hiện. Đã xác minh: `flutter analyze --no-pub` sạch; **305/305 Flutter tests passed** trong log `D:\PRM393\longvita_pr10_review_tests_20261104.log`. Commit sửa mã nguồn và unit/widget tests: **`81f8d7e`** (đã push lên PR #10). Đang chờ kết quả re-review sau push; không khẳng định native Firebase E2E đã chạy.

---

## 7. Tổng Hợp Nghiệm Thu Cuối Cùng & Ký Đóng Task S7-4 (10/11/2026)

Căn cứ biên bản quyết định của Team Leader [`docs/coordination/decision-leader-s6-1-s7-4-20261110.md`](coordination/decision-leader-s6-1-s7-4-20261110.md):
1. **Hoàn thành chỉ tiêu 4/4 thành viên:**
   - **Võ Lương Quốc Thắng:** PR #6 (Codex Security & Bugbot — 5 findings, fix commit [`55bdf3e`](https://github.com/ruxenb/LongvitaRC/commit/55bdf3e591808e5bfcf5af52a6a866384b0b83fe)).
   - **Charlie:** PR #7 (CodeRabbit — 11 findings, 8 fix commits), PR #8 (CodeRabbit — 9 findings, 5 fix commits), PR #25 (CodeRabbit — 3 findings, fix commit [`ac3a187`](https://github.com/ruxenb/LongvitaRC/commit/ac3a187)).
   - **Nguyễn Đắc Hoàng:** PR #10 (CodeRabbit — 4 findings, fix commit [`81f8d7e`](https://github.com/ruxenb/LongvitaRC/commit/81f8d7e)).
   - **Dương Vũ Thái An:** PR #36 (CodeRabbit — 5 findings, fix commit [`70a2d5e`](https://github.com/ruxenb/LongvitaRC/commit/70a2d5e)).
2. **Tổng số findings thực tế:** 37 findings (vượt xa chỉ tiêu tối thiểu 5 findings của đồ án).
3. **Chất lượng kỹ thuật:** 100% findings đều có phân loại rõ ràng (Security, Architecture, Performance, Correctness, Concurrency, Observability, Accessibility, Maintainability), có quyết định phân minh (Accepted / Modified / Rejected), giải trình kỹ thuật định lượng và gắn mã commit sửa cụ thể.
4. **Kết luận:** **Task S7-4: AI-Assisted Code Review chính thức NGHIỆM THU và ĐÓNG HOÀN TOÀN.**
