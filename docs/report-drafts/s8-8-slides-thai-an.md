# S8-8 — Nội dung 4 Slide thuyết trình của Thái An

> **Thành viên:** Thái An  
> **Vai trò:** Team Leader & QA Lead  
> **Phần nội dung:** Firebase Instrumentation (Analytics, Crashlytics, Remote Config) & Google ARTEMIS E2E Testing.  
> **Quy cách:** Chuẩn Rubric Lab 3 (Mỗi slide 1 thông điệp trọng tâm, dẫn link tài liệu/bằng chứng, bố cục trực quan). Bản thảo gửi Thắng ghép vào bộ Slide chung `slides/Lab03_<StudentID>_slides.pdf` (tổng 12–15 slide).

---

## Slide 1 — Firebase Analytics: Kế hoạch đo lường 8 sự kiện & Zero PII

### 🎯 Thông điệp trọng tâm:
> **Đo lường trọn vẹn hành vi người dùng bằng 8 sự kiện chuẩn hóa theo Appendix A, cam kết 100% không thu thập PII và kiểm chứng thời gian thực qua DebugView.**

### 📌 Nội dung trình bày (Bullet points):
- **Phủ kín toàn bộ phễu người dùng:** 8 sự kiện ánh xạ từ xác thực (`login`, `logout`), duyệt công thức (`search`, `view_recipe`), tạo thực đơn (`view_meal_plan`), chuẩn bị đi chợ (`view_ingredient_list`) đến chuyển đổi ngoại tuyến (`export_report`).
- **Gắn liền câu hỏi sản phẩm (Product Questions):** Mỗi tham số phục vụ trực tiếp việc ra quyết định kinh doanh (ví dụ: `result_count` phát hiện chủ đề tìm kiếm thiếu nội dung).
- **Tuân thủ quyền riêng tư tuyệt đối (Zero PII):** Không gửi email, họ tên hay plain UID; chỉ dùng hash rút gọn cho phiên đăng xuất.
- **Quan sát thời gian thực:** Kiểm chứng luồng sự kiện liên tục trên Firebase Console DebugView (Project ID `longvita-8da7e`).

### 🖼️ Bố cục & Hình ảnh minh chứng:
- **Cột trái:** Bảng tóm tắt 8 sự kiện và câu hỏi sản phẩm tương ứng.
- **Cột phải:** Ảnh chụp màn hình Firebase Console DebugView hiển thị dòng sự kiện và drawer tham số (`evidence/analytics/01-debugview-timeline.png`).
- **Dẫn link tài liệu:** [`docs/analytics-plan.md`](../analytics-plan.md).

---

## Slide 2 — Khả năng quan sát lỗi (Crashlytics) & Cập nhật UI tức thì (Remote Config)

### 🎯 Thông điệp trọng tâm:
> **Giám sát sự cố chi tiết với ngữ cảnh định lượng (Contextual Keys) và điều phối tính năng UI tức thì từ xa mà không cần biên dịch lại ứng dụng.**

### 📌 Nội dung trình bày (Bullet points):
- **Crashlytics Observability trong sản xuất:**
  - Tách bạch ranh giới: Handled Non-Fatal errors (ghi log êm ái, app không sập) và Fatal Crashes (kiểm chứng cơ chế phục hồi).
  - Tự động gắn kèm `user_id` và 3 custom keys: `error_category`, `last_screen`, `session_epoch`.
- **Remote Config — Thay đổi không cần Rebuild:**
  - Khởi tạo an toàn với in-app defaults từ file JSON; không bị ảnh hưởng nếu rớt mạng.
  - Đổi tham số `max_meal_recommendations` (5 $\to$ 10) trực tiếp trên Console; người dùng bấm làm mới nhận ngay giao diện mới.

### 🖼️ Bố cục & Hình ảnh minh chứng:
- **Nửa trên:** Ảnh chụp Crashlytics Dashboard hiển thị song song Fatal crash và Non-fatal issue có `user_id` và keys (`evidence/crashlytics/`).
- **Nửa dưới:** Cặp ảnh Before / After đối chiếu trên màn hình điện thoại khi đổi tham số Remote Config (`evidence/remote-config/`).
- **Dẫn link code:** [`lib/firebase/crashlytics_service.dart`](../../lib/firebase/crashlytics_service.dart), [`lib/firebase/remote_config_service.dart`](../../lib/firebase/remote_config_service.dart).

---

## Slide 3 — Google ARTEMIS: Tự động hóa kiểm thử E2E bằng Multimodal AI

### 🎯 Thông điệp trọng tâm:
> **Kiểm thử tự động hóa trọn vẹn 11 kịch bản E2E bằng AI Vision Agent, đạt tỷ lệ Pass Rate 100% qua $\ge 3$ lượt chạy độc lập.**

### 📌 Nội dung trình bày (Bullet points):
- **Mô hình kiểm thử thế hệ mới:** ARTEMIS AI Agent nhìn màn hình qua ADB, suy luận thị giác từ câu lệnh tự nhiên để điều hướng app như người dùng thật.
- **Bao phủ toàn diện kịch bản phức tạp:**
  - Tương tác native hệ thống: Google Account Picker, Android Notification Shade, Native PDF Print Viewer.
  - Rào chắn bảo mật: Đăng xuất dọn sạch session, nút Back chặn quay lại Dashboard.
  - Phục hồi lỗi (Error Paths): Mất mạng hiển thị nút Thử lại (Retry) chuyển tiếp sang kết quả.
- **Độ tin cậy được chứng minh:** Chạy kiểm thử đa lượt ($\ge 3$ runs/test case) trên profile `flash`, đạt tỷ lệ vượt qua 100%.

### 🖼️ Bố cục & Hình ảnh minh chứng:
- **Trung tâm:** Bảng ma trận tỷ lệ Pass Rate của 11 test cases (TC-01 đến TC-11) trích xuất từ `runs.jsonl`.
- **Dưới cùng:** Trích đoạn chuỗi bước quan sát (Replay steps) của ARTEMIS chứng minh agent tự tương tác với app.
- **Dẫn link tài liệu:** [`docs/test-plan.md`](../test-plan.md) & [`evidence/artemis/raw/runs.jsonl`](../../evidence/artemis/raw/runs.jsonl).

---

## Slide 4 — Bài học chất lượng: Xử lý Flaky Tests & Kết quả kiểm thử thăm dò

### 🎯 Thông điệp trọng tâm:
> **Phân loại và triệt tiêu nguyên nhân Flaky test trong kiểm thử AI, đồng thời chủ động phát hiện góc chết giao diện qua phiên kiểm thử thăm dò.**

### 📌 Nội dung trình bày (Bullet points):
- **Bài học xử lý Flaky Test với AI Vision Agent:**
  - *Nguyên nhân 1 (Timing / I/O latency):* Hộp thoại ANR của emulator gây nghẽn; giải quyết bằng cơ chế tự động chờ ổn định màn hình 3.000ms trong `conftest.py`.
  - *Nguyên nhân 2 (Assertion Coupling):* Khẳng định kiểm thử lọt lưới do bắt nhầm từ khóa ở màn hình trước; giải quyết bằng việc phân tách chuỗi quan sát độc lập theo từng hành động.
- **Kết quả phiên kiểm thử thăm dò (Exploratory Testing — Profile Pro):**
  - Thực thi 20 phút chạy tự do không kịch bản tìm kiếm góc chết.
  - Xác nhận an toàn: Chặn gọi API trùng lặp khi người dùng spam nút Xuất PDF bằng cờ `_isExporting`.
  - Khắc phục giao diện: Bọc cuộn `SingleChildScrollView` tránh lỗi tràn phím ảo khi xoay ngang màn hình.

### 🖼️ Bố cục & Hình ảnh minh chứng:
- **Cột trái:** Sơ đồ so sánh nguyên nhân Flaky: *Timing vs Instruction vs UI Semantics*.
- **Cột phải:** Bảng tổng hợp các phát hiện từ phiên kiểm thử thăm dò và commit khắc phục.
- **Dẫn link tài liệu:** [`docs/code-review.md`](../code-review.md) (mục PR7-CR-08 và PR8-CR-02).
