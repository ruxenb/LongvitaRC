# AI-Assisted Code Review Record — Longvita (Lab 3)

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

## 3. Bản Kê Khai Sử Dụng Công Cụ Trí Tuệ Nhân Tạo (AI Tools Disclosure)

| Tên Công Cụ AI | Phiên bản / Môi trường | Mục đích sử dụng cụ thể trong dự án Lab 3 | Thành viên sử dụng |
|:---|:---|:---|:---:|
| **Google Gemini (Antigravity Assistant)** | Gemini Pro / Flash | Hỗ trợ thiết kế cấu trúc barebone, lập kế hoạch phân rã 112 tasks từ file Excel, soạn thảo tài liệu mẫu và phân tích đường găng. | Cả nhóm |
| **GitHub Copilot** | Copilot Chat & Completion | Gợi ý cú pháp Dart, hỗ trợ viết các hàm sinh file PDF (`pdf` package) và các test assertions trong ARTEMIS. | Charlie, Hoàng |
| **CodeRabbit AI** | GitHub PR App | Tự động review mã nguồn trên từng Pull Request của nhánh tính năng trước khi merge vào nhánh chính. | Cả nhóm |
| **SonarCloud** | Cloud Scanner | Quét phân tích tĩnh (Static Analysis), phát hiện Code Smells, trùng lặp mã và các vấn đề về maintainability. | Thắng |
| **Google ARTEMIS** | Pinned Commit `main` | AI Testing Agent tự động lái thiết bị Android từ câu lệnh tự nhiên để kiểm thử E2E các luồng nghiệp vụ. | Thái An |
