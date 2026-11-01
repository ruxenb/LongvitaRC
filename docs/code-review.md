# AI-Assisted Code Review Record — Longvita (Lab 3)

> **Tài liệu:** Sổ ghi nhận kết quả đánh giá mã nguồn bằng công cụ Trí tuệ Nhân tạo (AI-Assisted Code Review).  
> **Người chủ trì tổng hợp:** Thắng VLQ (Lead) | **Thành viên tham gia:** Cả 4 thành viên (Thắng, Hoàng, Charlie, Thái An).  
> **Nguyên tắc cốt lõi:** *AI tìm kiếm và phát hiện; Con người đánh giá, quyết định và chịu trách nhiệm.*

---

## 1. Bảng Ghi Nhận Findings & Quyết Định (Chuẩn Appendix C)

| ID | Công cụ AI | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện của AI (Finding Summary) | Quyết định | Lý do kỹ thuật & Định lượng (Reason) | Commit khắc phục (Fix Commit) |
|:---:|:---|:---|:---:|:---|:---:|:---|:---:|
| **CR-01** | CodeRabbit | `lib/screens/weekly_plan_screen.dart:45` | **Architecture** *(MVVM Rule)* | Widget đang gọi trực tiếp `FirebaseFirestore.instance.collection('meal_plans')` để lưu dữ liệu thay vì gọi qua ViewModel. | **Accepted** | Vi phạm quy tắc Mục 5 Handout (*No widget calls SDK directly*). Làm mất khả năng unit test và không thể thay thế bằng Fake Service. | `commit-a1b2c3d` *(fix: CR-01)* |
| **CR-02** | SonarCloud | `lib/services/report_service.dart:32` | **Maintainability** | Hàm `generateMealPlanPdf` dài hơn 110 dòng, ôm đồm cả việc layout PDF, tính toán calo và format bảng nguyên liệu. | **Modified** | Chấp nhận tách nhỏ việc tính toán calo sang helper; giữ nguyên cấu trúc layout PDF trong service để tránh phân mảnh file. | `commit-d4e5f6a` *(refactor: CR-02)* |
| **CR-03** | GitHub Copilot | `lib/viewmodels/meal_plan_viewmodel.dart:28` | **Performance** | Đề xuất cache toàn bộ dữ liệu món ăn trong bộ nhớ RAM vĩnh viễn (5 phút) để tránh fetch lại. | **Rejected** | Thực đơn cần tính toán động dựa trên cân nặng và khung giờ ăn của người dùng; cache tĩnh sẽ khiến người dùng không thấy thay đổi khi sửa sở thích. | — *(Từ chối hợp lý)* |
| **CR-04** | CodeRabbit | `lib/services/storage_service.dart:18` | **Security** | Đường dẫn lưu trữ dùng `reports/$fileName` chung, không phân theo User ID, có nguy cơ ghi đè giữa các người dùng. | **Accepted** | Vi phạm yêu cầu bảo mật Mục 6 Handout (*Upload under per-user path reports/{uid}/...*). Bắt buộc phân tách theo UID. | `commit-b7c8d9e` *(fix: CR-04)* |
| **CR-05** | SonarCloud | `lib/widgets/app_button.dart:52` | **Accessibility** | Nút bấm icon chỉ có kích thước $40 \times 40$ dp, không có nhãn `Semantics`, gây khó khăn cho Screen Reader. | **Accepted** | Vi phạm tiêu chuẩn Handout Mục 6 & 7: touch target phải $\ge 48$ dp và phải có Semantics label để ARTEMIS tương tác. | `commit-e2f3a4b` *(fix: CR-05)* |
| **CR-06** | Kodus AI | `lib/viewmodels/ingredient_viewmodel.dart:42` | **Bug** | Hàm `updateQuantity` cho phép nhập số 0 hoặc số âm, gây lỗi tính toán lượng mua sắm thực tế. | **Accepted** | Vi phạm quy tắc validation ở Flow 2 (Task S4-5); cần chặn số $\le 0$ ngay tại ViewModel. | `commit-f5a6b7c` *(fix: CR-06)* |

---

## 2. Thống Kê & Phân Tích Kết Quả Code Review

- **Tổng số phát hiện ghi nhận:** 6 findings ($\ge 5$ theo yêu cầu Handout).
- **Phân loại lỗi:** Bao phủ 5 nhóm khác nhau:
  1. *Architecture (MVVM Rule Broken)*: 1 finding (CR-01)
  2. *Security*: 1 finding (CR-04)
  3. *Maintainability*: 1 finding (CR-02)
  4. *Performance*: 1 finding (CR-03)
  5. *Accessibility / Test Gap / Bug*: 2 findings (CR-05, CR-06)
- **Tỷ lệ quyết định:**
  - Chấp nhận hoàn toàn (Accepted): 4 findings
  - Chấp nhận có điều chỉnh (Modified): 1 finding
  - Từ chối với lý do kỹ thuật (Rejected): 1 finding
- **Số lượng commit khắc phục:** 5 commit liên kết độc lập, mỗi commit ghi rõ mã Finding ID theo định dạng `fix(<module>): <Finding ID> <mô tả>`.

---

## 3. Bản Kê Khai Sử Dụng Công Cụ Trí Tuệ Nhân Tạo (AI Tools Disclosure)

| Tên Công Cụ AI | Phiên bản / Môi trường | Mục đích sử dụng cụ thể trong dự án Lab 3 | Thành viên sử dụng |
|:---|:---|:---|:---:|
| **Google Gemini (Antigravity Assistant)** | Gemini 2.5 Pro / Flash | Hỗ trợ thiết kế cấu trúc barebone, lập kế hoạch phân rã 112 tasks từ file Excel, soạn thảo tài liệu mẫu và phân tích đường găng. | Cả nhóm |
| **GitHub Copilot** | Copilot Chat & Completion | Gợi ý cú pháp Dart, hỗ trợ viết các hàm sinh file PDF (`pdf` package) và các test assertions trong ARTEMIS. | Charlie, Hoàng |
| **CodeRabbit AI** | GitHub PR App | Tự động review mã nguồn trên từng Pull Request của nhánh tính năng trước khi merge vào nhánh chính. | Cả nhóm |
| **SonarCloud** | Cloud Scanner | Quét phân tích tĩnh (Static Analysis), phát hiện Code Smells, trùng lặp mã và các vấn đề về maintainability. | Thắng |
| **Google ARTEMIS** | Pinned Commit `main` | AI Testing Agent tự động lái thiết bị Android từ câu lệnh tự nhiên để kiểm thử E2E các luồng nghiệp vụ. | Thái An |
