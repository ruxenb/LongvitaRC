# AI-Assisted Code Review Record — Longvita (Lab 3)

> **03/11/2026 — Có kết quả thật:** mục 1.1 ghi 11 findings CodeRabbit trên PR #7 cùng raw output, quyết định và commit sửa. Các dòng khung CR-xx và ví dụ EX-xx là tài liệu tham khảo, không được tính vào findings thật. Gói sửa được bàn giao qua nhánh `feature/charlie-review-delivery-01`, chờ team review; không tuyên bố toàn bộ rubric đã nghiệm thu.

> **Tài liệu:** Sổ ghi nhận kết quả đánh giá mã nguồn bằng công cụ Trí tuệ Nhân tạo (AI-Assisted Code Review).  
> **Chủ trì nghiệm thu:** Thái An (Team Leader) & Thắng VLQ (Technical Architect) | **Thành viên tham gia:** Cả 4 thành viên (Thái An, Thắng, Hoàng, Charlie).  
> **Nguyên tắc cốt lõi:** *AI tìm kiếm và phát hiện; Con người đánh giá, quyết định và chịu trách nhiệm.*  
> **Quy định quy trình (Handout Mục 4 & 10):** Code review chỉ được thực hiện trên **Pull Request (PR)** tại GitHub sau khi các nhánh tính năng hoàn thành (Stage 7). Tuyệt đối không ghi nhận commit trước khi có mã nguồn thực tế.

---

## 1. Bảng Ghi Nhận Findings & Quyết Định Chính Thức (Stage 7 — Pull Requests)

*Bảng này sẽ được các thành viên điền trực tiếp khi mở PR cho từng module tính năng tại Tuần 4 (Stage 7). Dưới đây là bảng khung sẵn sàng ghi nhận:*

| ID | Công cụ AI | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện của AI (Finding Summary) | Quyết định (Accepted / Modified / Rejected) | Lý do kỹ thuật & Định lượng (Reason) | Commit khắc phục (Fix Commit) | Người phụ trách |
|:---:|:---|:---|:---:|:---|:---:|:---|:---:|:---:|
| *[CR-01]* | *CodeRabbit* | *(Chờ mở PR)* | Architecture | *(Sẽ cập nhật khi bot AI review PR)* | *(Pending)* | *(Tham chiếu Handout Mục 5)* | *(Mã commit thật)* | Thái An |
| *[CR-02]* | *SonarCloud* | *(Chờ mở PR)* | Maintainability | *(Sẽ cập nhật khi bot AI review PR)* | *(Pending)* | *(Tham chiếu tiêu chuẩn Clean Code)* | *(Mã commit thật)* | Charlie |
| *[CR-03]* | *Copilot* | *(Chờ mở PR)* | Performance | *(Sẽ cập nhật khi bot AI review PR)* | *(Pending)* | *(Định lượng Rebuild/Latency)* | *(Mã commit thật)* | Hoàng |
| *[CR-04]* | *CodeRabbit* | *(Chờ mở PR)* | Security | *(Sẽ cập nhật khi bot AI review PR)* | *(Pending)* | *(Tham chiếu Storage Rules)* | *(Mã commit thật)* | Thắng |
| *[CR-05]* | *SonarCloud* | *(Chờ mở PR)* | Accessibility | *(Sẽ cập nhật khi bot AI review PR)* | *(Pending)* | *(Touch target $\ge 48$dp / Semantics)* | *(Mã commit thật)* | Thái An |

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

Các dòng dưới đây được giữ làm mẫu kế hoạch; không xác nhận mọi thành viên đã dùng các tool này. Chỉ chuyển sang disclosure thực tế khi có mục đích/output hoặc worklog. Ngày 02/11, Charlie dùng Codex (đọc repo/PDF, review, Markdown điều phối) và Claude Code (viết code, test, báo cáo Dev); chưa chạy ARTEMIS, CodeRabbit, Copilot, SonarCloud hoặc model API. Ngày 03/11, Charlie chạy ARTEMIS với key Gemini của mình, và CodeRabbit review PR #7 (mục 1.1).

| Tên Công Cụ AI | Phiên bản / Môi trường | Mục đích sử dụng cụ thể trong dự án Lab 3 | Thành viên sử dụng |
|:---|:---|:---|:---:|
| **Google Gemini (Antigravity Assistant)** | Gemini Pro / Flash | Hỗ trợ thiết kế cấu trúc barebone, lập kế hoạch phân rã 112 tasks từ file Excel, soạn thảo tài liệu mẫu và phân tích đường găng. | Cả nhóm |
| **GitHub Copilot** | Copilot Chat & Completion | Gợi ý cú pháp Dart, hỗ trợ viết các hàm sinh file PDF (`pdf` package) và các test assertions trong ARTEMIS. | Charlie, Hoàng |
| **CodeRabbit AI** | GitHub PR App | Tự động review mã nguồn trên từng Pull Request của nhánh tính năng trước khi merge vào nhánh chính. | Cả nhóm |
| **SonarCloud** | Cloud Scanner | Quét phân tích tĩnh (Static Analysis), phát hiện Code Smells, trùng lặp mã và các vấn đề về maintainability. | Thắng |
| **Google ARTEMIS** | Chưa pin full SHA | AI Testing Agent tự động lái thiết bị Android từ câu lệnh tự nhiên để kiểm thử E2E các luồng nghiệp vụ. | Thái An |

## 4. Disclosure xác nhận cho gói Charlie

CodeRabbit GitHub App sinh 11 góp ý trên PR #7; Claude Code đánh giá ban đầu và viết các commit sửa; Codex audit lại quyết định/source, sửa tiếp CR-08, viết 23 kiểm tra assertions độc lập và bàn giao PR theo yêu cầu Charlie. ARTEMIS/Gemini đã được Charlie chạy trước đó như evidence riêng; Codex không chạy lại ARTEMIS/không dùng key trong gói bàn giao này. Bảng công cụ ở mục 3 là nguồn kế hoạch, không tự xác nhận mọi thành viên đã dùng mọi tool.


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
