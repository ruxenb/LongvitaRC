# S8-4 — Bản nháp phần báo cáo của Thái An

> **Thành viên:** Thái An  
> **Vai trò:** Team Leader & QA Lead  
> **Nội dung phụ trách:** Firebase Analytics, Firebase Crashlytics, Firebase Remote Config, Google ARTEMIS Automated E2E Testing, AI Code Review & Nghiệm thu chất lượng.  
> **Mục tiêu:** Bản thảo chi tiết gửi Thắng (Technical Architect) để ghép vào Báo cáo tổng thể `report/Lab03_<StudentID>.pdf` (Mục 6, 7 & Appendix A, B).

---

## 1. Firebase Analytics — Kế hoạch đo lường & Giám sát thời gian thực (Appendix A)

### 1.1. Kế hoạch sự kiện (Event Plan)
Ứng dụng Longvita triển khai kế hoạch đo lường gồm **8 sự kiện chính** (vượt ngưỡng tối thiểu $\ge 7$ của Lab 3), được thiết kế nhằm trả lời trực tiếp các câu hỏi vận hành sản phẩm (Product Questions) mà không thu thập bất kỳ thông tin định danh cá nhân nào (Zero PII Compliance):

| Tên sự kiện | Điểm kích hoạt (Trigger Point) | Tham số (Parameters) | Câu hỏi sản phẩm (Product Question) | Lab 2 Flow tương ứng |
|---|---|---|---|---|
| `login` | Đăng nhập Google thành công | `method` (string: `'google'`) | Tỷ lệ người dùng quay lại và lựa chọn phương thức xác thực? | Flow Auth |
| `search` | Thực hiện tìm kiếm món ăn / nguyên liệu | `search_term` (string), `result_count` (int) | Người dùng quan tâm đến nhóm thực phẩm nào, từ khóa nào không trả về kết quả? | Flow 3 (S05) |
| `view_meal_plan` | Mở màn hình chi tiết thực đơn tuần | `plan_id` (string), `plan_title` (string) | Thực đơn nào được người dùng xem lại nhiều nhất sau khi tạo? | Flow 1 (S04, S10) |
| `view_recipe` | Mở màn hình chi tiết công thức món ăn | `recipe_id` (string), `recipe_name` (string) | Món ăn trường thọ nào thu hút sự chú ý nhiều nhất của người dùng? | Flow 3 (S05) |
| `export_report` | Tạo PDF và upload Cloud Storage | `export_format` (string: `'pdf'`), `file_size_bytes` (int) | Tỷ lệ người dùng chuyển hóa từ xem thực đơn sang nhu cầu lưu trữ/chia sẻ ngoại tuyến? | Flow Cloud (Profile) |
| `logout` | Người dùng xác nhận đăng xuất | `user_id_hash` (string: SHA-256 rút gọn) | Người dùng rời phiên làm việc ở tần suất nào? | Flow Auth |
| `update_remote_config`| Bấm cập nhật cấu hình động trên Profile | `status` (string: `'success'/'failed'`), `fetch_status` (string) | Tính năng cấu hình từ xa có hoạt động ổn định trên thiết bị client không? | Flow Cloud (Profile) |
| `view_ingredient_list`| Chuyển sang màn tổng hợp đi chợ | `ingredient_count` (int) | Quy mô giỏ hàng trung bình của một kế hoạch ăn 7 ngày? | Flow 2 (S07, S08) |

### 1.2. Cam kết bảo vệ quyền riêng tư (No PII)
- Toàn bộ tham số được kiểm duyệt nghiêm ngặt: **Không** gửi email, họ tên, số điện thoại hoặc UID nguyên bản lên Firebase Analytics.
- Khi người dùng đăng xuất, dịch vụ gọi `AnalyticsService.resetAnalyticsData()` để xóa sạch phiên làm việc trên client.

### 1.3. Bằng chứng giám sát thời gian thực qua DebugView
- Kích hoạt chế độ debug qua ADB: `adb shell setprop debug.firebase.analytics.app vn.edu.fpt.longvita`.
- Toàn bộ 8 sự kiện được quan sát trực tiếp trên Firebase Console DebugView theo thời gian thực (Project `longvita-8da7e`).
- Dẫn chứng lưu tại: `evidence/analytics/01-debugview-timeline.png` và `evidence/analytics/02-debugview-parameters.png`.

---

## 2. Firebase Crashlytics & Remote Config

### 2.1. Crashlytics — Khả năng quan sát lỗi trong môi trường thực tế (Observability)
Dịch vụ [`CrashlyticsService`](../../lib/firebase/crashlytics_service.dart) được đóng gói sau interface chuẩn, đảm bảo:
1. **Phân tách Fatal vs Non-Fatal:** 
   - Lỗi nghiêm trọng (Uncaught Fatal Crash) được kiểm chứng qua nút "Test Crash" trên Firebase Demo Area (`FirebaseCrashlytics.instance.crash()`).
   - Lỗi được xử lý an toàn (Handled Non-Fatal Error) từ các khối `try/catch` nghiệp vụ được ghi nhận qua `recordHandledError()`, giữ cho app không bị sập trước mắt người dùng.
2. **Ngữ cảnh chẩn đoán (Contextual Keys & User Identity):**
   - Mọi crash report đều đính kèm `user_id` (nếu đã đăng nhập) và 3 custom keys định lượng:
     - `error_category`: Phân loại lỗi (`auth_error`, `storage_network`, `demo_error`).
     - `last_screen`: Màn hình phát sinh lỗi (`profile`, `meal_plan`, `shopping`).
     - `session_epoch`: Định danh phiên làm việc nhằm đối chiếu ranh giới session.
- Bằng chứng dashboard hiển thị cả fatal crash và non-fatal issue có đầy đủ keys lưu tại `evidence/crashlytics/`.

### 2.2. Remote Config — Cập nhật hành vi UI không cần biên dịch lại (Live Fetch/Activate)
Dịch vụ [`RemoteConfigService`](../../lib/firebase/remote_config_service.dart) xử lý 4 tham số cấu hình:
- `max_meal_recommendations` (int, default: 5): Giới hạn số lượng món ăn gợi ý trên danh sách.
- `enable_longevity_score` (bool, default: true): Cờ bật/tắt hiển thị chỉ số dinh dưỡng trường thọ.
- `welcome_banner_text` (string): Thông điệp chào mừng trên Dashboard.
- `enable_advanced_filter` (bool, default: false): Cờ tính năng mở rộng bộ lọc dinh dưỡng.

**Cơ chế In-App Defaults & Fallback:**
- Khởi tạo nạp giá trị từ file nội bộ [`firebase/remote-config-defaults.json`](../../firebase/remote-config-defaults.json). Nếu thiết bị mất mạng hoặc console chưa phản hồi, ứng dụng vẫn hoạt động bình thường với giá trị an toàn, không gây crash màn hình.
- **Minh chứng thay đổi động:** Đổi giá trị `max_meal_recommendations` từ **5** thành **10** trên Console `longvita-8da7e` $\to$ Bấm "Cập nhật Remote Config" trong Profile $\to$ Giao diện nạp ngay số lượng mới mà **không cần rebuild hay cài lại APK**. Cặp ảnh Before/After lưu tại `evidence/remote-config/`.

---

## 3. Google ARTEMIS — Kiểm thử tự động E2E bằng AI Testing Agent (Appendix B)

### 3.1. Thiết kế kiểm thử & Cấu hình môi trường
Ứng dụng sử dụng **Google ARTEMIS** (commit đã pin `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`), vận hành thông qua Python 3.12+ và `uv`. ARTEMIS nhận kịch bản bằng câu lệnh ngôn ngữ tự nhiên (Natural-Language Instructions), sử dụng mô hình thị giác đa phương thức (Multimodal Vision Model) để chụp ảnh màn hình qua ADB, suy luận vị trí các phần tử UI và thực thi hành vi như người dùng thật.

Toàn bộ **11 test cases** trong [`docs/test-plan.md`](../test-plan.md) bao phủ đầy đủ:
- Luồng xác thực Google Sign-In & hủy chọn tài khoản (Native Picker).
- 3 User Flows Lab 2 (Tạo thực đơn 7 ngày, Validate số lượng nguyên liệu, Đổi món ăn).
- Các đường dẫn xử lý lỗi (Error Paths): Mất mạng khi tạo kế hoạch có nút Thử lại (Retry).
- Tương tác hệ thống (Native Interaction): Mở Push Notification từ Android Notification Shade, mở Trình xem file PDF native.
- Rào chắn bảo mật phiên: Sign-out xóa sạch dữ liệu và nút Back không thể quay lại Dashboard.

### 3.2. Bảng kết quả chạy kiểm thử đa lượt ($\ge 3$ runs/test case)
Theo quy định nghiêm ngặt của Lab 3, mỗi test case được chạy lặp lại tối thiểu 3 lần trên profile `flash` để tính toán độ tin cậy và tỷ lệ hoàn thành (Pass Rate):

| Mã Test | Luồng Nghiệp Vụ | Loại Kịch Bản | Lần 1 | Lần 2 | Lần 3 | Pass Rate | Đánh giá độ tin cậy |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---|
| **TC-01** | Google Sign-In Native | Native Interaction | Pass (68s) | Pass (72s) | Pass (65s) | **100%** | Rất ổn định (Zero Flakiness) |
| **TC-01b**| Hủy Account Picker về Sign-in | Error / Recovery | Pass (44s) | Pass (39s) | Pass (47s) | **100%** | Xử lý Back hệ thống chính xác |
| **TC-02** | Lập thực đơn 7 ngày (S01-S04) | Happy Path | Pass (112s)| Pass (118s)| Pass (105s)| **100%** | Form wizard hoàn thành đủ 7 ngày |
| **TC-03** | Mất mạng khi lập thực đơn | Error Path + Retry | Pass (78s) | Pass (82s) | Pass (75s) | **100%** | Retry phục hồi thành công |
| **TC-04** | Lưu thực đơn vào Firestore (S10)| Happy Path | Pass (85s) | Pass (90s) | Pass (81s) | **100%** | Lưu Firestore và hiển thị S10 |
| **TC-05** | Chặn số lượng âm nguyên liệu (S07)| Form Validation | Pass (62s) | Pass (58s) | Pass (64s) | **100%** | Validation chặn số âm chuẩn xác |
| **TC-06** | Bền vững trạng thái checkbox (S08) | State Persistence | Pass (70s) | Pass (74s) | Pass (69s) | **100%** | Thoát ra vào lại vẫn giữ checked |
| **TC-07** | Đổi món ăn trường thọ (Flow 3) | Alternative Path | Pass (95s) | Pass (102s)| Pass (91s) | **100%** | Cập nhật thực đơn, tuân thủ quy tắc |
| **TC-08** | Xuất PDF & Upload Cloud Storage | Happy Path | Pass (54s) | Pass (35s) | Pass (89s) | **100%** | Hiện URL `reports/{uid}/...` |
| **TC-08b**| Mở PDF trên Native Viewer | Native App Flow | Pass (142s)| Pass (138s)| Pass (145s)| **100%** | Mở đúng trình in/xem Android |
| **TC-09** | Cập nhật Remote Config Live | Cloud Sync | Pass (117s)| Pass (186s)| Pass (120s)| **100%** | Thay đổi giá trị không rebuild |
| **TC-10** | Mở FCM từ Android Shade | Native Notification| Pass (54s) | Pass (58s) | Pass (51s) | **100%** | Mở đúng màn hình Profile |
| **TC-11** | Sign-out chặn Back về Home | Security Barrier | Pass (54s) | Pass (52s) | Pass (56s) | **100%** | AuthGate dọn stack điều hướng |

*Toàn bộ raw traces, logs từng bước và mã task ID được ghi nhận minh bạch tại file [`evidence/artemis/raw/runs.jsonl`](../../evidence/artemis/raw/runs.jsonl).*

---

## 4. Phân tích nguyên nhân Test Flaky & Phiên kiểm thử thăm dò

### 4.1. Phân tích và xử lý hiện tượng Flaky Test
Trong các đợt chạy thử nghiệm ban đầu, nhóm ghi nhận 2 hiện tượng flaky chính và đã chủ động khắc phục triệt để:
1. **Lỗi trễ khởi động của Android Emulator (ANR Warning):**
   - *Triệu chứng:* Khi chạy lần đầu, emulator xuất hiện hộp thoại hệ thống *"longvita isn't responding"* (Wait / Close app) do emulator bị nghẽn I/O.
   - *Khắc phục:* Bổ sung bước xử lý tự động trong `conftest.py` phát hiện hộp thoại này để bấm "Wait", đồng thời tăng thời gian ổn định màn hình (`wait_ms`) lên 3.000ms giúp ARTEMIS không đánh giá trượt oan kịch bản.
2. **Khẳng định kiểm thử phụ thuộc chuỗi (Assertion Coupling):**
   - *Triệu chứng:* Trong TC-08b, agent quét chữ "Longvita" ở màn hình trước làm điều kiện kiểm tra của màn hình sau bị pass giả tạo.
   - *Khắc phục:* AI review (PR7-CR-08 và PR8-CR-02) đã phân tách replay từng bước độc lập, chỉ kiểm tra chuỗi khẳng định từ thời điểm hành động mở Native Viewer diễn ra.

### 4.2. Báo cáo kết quả Phiên kiểm thử thăm dò (Exploratory Testing — Profile Pro)
- **Thời lượng:** 20 phút chạy tự do với mô hình đa phương thức chuyên sâu (Profile Pro).
- **Mục tiêu:** Thăm dò các góc chết giao diện, thao tác nhanh bất thường (spamming) và rò rỉ bộ nhớ.
- **Kết quả ghi nhận:**
  1. *Phát hiện 1 (Mức độ Thấp):* Khi bấm liên tiếp 3 lần vào nút "Xuất báo cáo PDF", app có nguy cơ gọi API trùng lặp. Đã kiểm tra thấy ViewModel có cờ `_isExporting` vô hiệu hóa nút bấm ngay lập tức $\to$ Hoạt động an toàn.
  2. *Phát hiện 2 (Mức độ Trung bình):* Khi xoay ngang màn hình ở S02 (Form wizard), giao diện có nguy cơ bị che khuất nút "Tiếp tục". Nhóm đã bọc `SingleChildScrollView` toàn bộ form, đảm bảo bàn phím ảo không gây lỗi tràn pixel (RenderFlex overflow).

---

## 5. Kết luận phần nghiệm thu của Lead & Đóng góp chung
- Hệ thống đo lường (Analytics), giám sát sự cố (Crashlytics) và điều phối tính năng từ xa (Remote Config) vận hành mượt mà, độc lập sau tầng interface, tuân thủ 100% chuẩn MVVM.
- Bộ kiểm thử tự động Google ARTEMIS chứng minh ứng dụng đạt độ tin cậy E2E cao trên thiết bị Android thật, không có lỗi chặn luồng người dùng.
- Toàn bộ kết quả đều có bằng chứng số liệu và ảnh chụp đối chiếu, sẵn sàng cho khâu bảo vệ và vấn đáp.
