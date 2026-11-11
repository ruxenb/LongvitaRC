# Tổng Hợp Toàn Bộ Yêu Cầu Final Assignment — PRM393 (Tài Liệu Làm Slide & Báo Cáo)

> **Căn cứ tài liệu gốc:** Handout *PRM393 — Final Assignment: One Complete System on Firebase (No-Cost Plan)* — Giảng viên: Lâm Phương (Oct 21, 2026).  
> **Mục tiêu cốt lõi:** Hợp nhất thiết kế Lab 2 và ứng dụng Lab 3 thành **MỘT hệ thống hoàn chỉnh (One Complete System)**: bao gồm ứng dụng di động (Flutter Mobile), trang quản trị web (Flutter Web Admin), một backend Cloud Firestore dùng chung và một tính năng Trí tuệ nhân tạo (Google Gemini AI Feature).  
> **Tôn chỉ đánh giá:** Điểm số tưởng thưởng cho việc **hoàn thiện trọn vẹn, tích hợp đồng bộ và chứng minh hệ thống hoạt động thông suốt từ đầu đến cuối (end-to-end)**, không chấm điểm cho việc vẽ thêm tính năng mới nằm ngoài phạm vi.

---

## 1. Cơ Cấu Điểm & Quy Định Bàn Giao (Grading Rubric — Thang Điểm 10 + 0.5 Bonus)

Điểm số phân bổ nghiêm ngặt giữa **Chất lượng hệ thống (The System - 8.0 điểm)** và **Kỹ năng truyền thông/trình bày (Slides & Demo Video - 2.0 điểm)**:

```text
TỔNG ĐIỂM: 10.0 ĐIỂM (+ TỐI ĐA 0.5 ĐIỂM BONUS)
├── 1. HỆ THỐNG HOÀN THIỆN (The System): 8.0 điểm
│   ├── Ứng dụng Mobile (Mobile App): 2.0 điểm
│   │   ├── Hoàn tất phạm vi Lab 2 & Lab 3 (Lab 2 & Lab 3 scope finished): 1.25 điểm
│   │   └── Dữ liệu Firestore & Hộp thư đến (Real data & Inbox): 0.75 điểm
│   ├── Trang quản trị Web (Web Admin): 2.0 điểm
│   │   ├── 4 màn hình & Form thông báo (Screens & Actions): 1.25 điểm
│   │   └── Design system & Triển khai Hosting (Design system & Deployment): 0.75 điểm
│   ├── Backend & Tích hợp liên vai trò (Backend & Integration): 2.0 điểm
│   │   ├── Data model & Security Rules (Role-based, deny by default): 1.0 điểm
│   │   └── Luồng liên vai trò thời gian thực (Cross-role flow live): 1.0 điểm
│   ├── Tính năng Trí tuệ nhân tạo (AI Feature - Gemini Level 2): 1.0 điểm
│   │   └── Level 2 Structured Output, Remote Config, App Check, Fallback, Zero PII: 1.0 điểm
│   └── Kiểm thử & Chất lượng mã nguồn (Testing & Code Quality): 1.0 điểm
│       ├── Bộ test ARTEMIS, Rules Emulator & Web checklist: 0.5 điểm
│       └── Kiến trúc MVVM, Shared package packages/core/ & AI code review (≥ 3 findings): 0.5 điểm
│
├── 2. TRÌNH BÀY & TRUYỀN THÔNG (Presentation): 2.0 điểm
│   ├── Bộ Slide thuyết trình (Slides PDF, 12–15 slide, bằng chứng trên từng slide): 1.0 điểm
│   └── Demo Video (8–12 phút, live demo cả 2 màn hình đồng thời): 1.0 điểm
│
└── 3. ĐIỂM THƯỞNG (Bonus - Tối đa +0.5 điểm, tổng không quá 10.0):
    └── Nâng cấp AI Level 3 (Function calling over user data) HOẶC luồng Cross-role thứ hai: +0.5 điểm
```

---

## 2. Toàn Bộ Nội Dung Kỹ Thuật Yêu Cầu Của Final Assignment

Dưới đây là chi tiết từng phần việc bắt buộc theo 6 khối nội dung của Handout để bạn đưa vào các trang slide tương ứng:

### KHỐI 1: Kiến Trúc Hệ Thống & Gói Chia Sẻ (System Architecture & Monorepo)
*Căn cứ Section 4 của Handout — Tương ứng Slide 3, Slide 4 trong dàn ý slide.*

1. **Kiến trúc One Firestore, Two Clients:**
   - **Không có máy chủ tùy biến (No Custom Server):** Toàn bộ logic nghiệp vụ chạy trực tiếp trên các client (Mobile và Web). Cloud Firestore đóng vai trò là nguồn sự thật duy nhất (Single Source of Truth).
   - **Bảo mật bằng Security Rules & App Check:** Quyền hạn đọc/ghi dữ liệu được quyết định hoàn toàn bởi Firestore Security Rules và xác thực nguồn gốc ứng dụng qua App Check.
2. **Gói chia sẻ dùng chung (`packages/core/`):**
   - Cả Mobile Client và Web Admin cùng import một package Dart duy nhất:
     - `models/`: Chứa Plain Dart Data Classes (`UserModel`, `MealPlan`, `Recipe`, `Ingredient`, `AiMealRecommendation`).
     - `services/`: Interfaces và Cloud Firestore Services (`DataService`, `AuthService`, `RemoteConfigService`).
     - `theme/`: Design tokens từ Lab 2 (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`).
     - `widgets/`: 9 nhóm UI components dùng chung (Buttons, Cards, Dialogs, State Views...).
3. **Ranh giới công nghệ (Scope Guard):**
   - **Dịch vụ được dùng:** Firebase Authentication (Google Sign-In), Cloud Firestore, Firebase Hosting, Firebase Remote Config, Firebase Cloud Messaging (FCM), Firebase Crashlytics, Firebase Analytics, Gemini Developer API.
   - **Nằm ngoài phạm vi (Out of Scope):** **Cloud Functions, Cloud Storage, App Hosting, Cloud Run** (để giữ hệ thống hoàn toàn trên gói miễn phí No-Cost / Spark Plan). File PDF báo cáo của Lab 3 được tạo cục bộ, lưu trên bộ nhớ máy và chỉ đồng bộ metadata lên Firestore.

---

### KHỐI 2: Backend, Mô Hình Dữ Liệu & Phân Quyền (Backend Requirements)
*Căn cứ Section 6, Appendix A & B của Handout — Tương ứng Slide 4, Slide 5 trong dàn ý slide.*

1. **Phân quyền dựa trên vai trò (Role-Based Access Control - RBAC):**
   - Vai trò người dùng được lưu trữ bất biến tại trường `role` trong document `users/{uid}`.
   - **3 vai trò chuẩn:**
     - `user`: Dùng ứng dụng Mobile (tạo, lưu, gửi thực đơn, quản lý nguyên liệu, đọc thông báo).
     - `staff`: Dùng Web Admin (chuyên gia dinh dưỡng: quản lý công thức, duyệt/từ chối thực đơn, đăng thông báo).
     - `admin`: Dùng Web Admin (toàn quyền staff + quản lý danh sách người dùng và thay đổi role người khác).
   - **Nguyên tắc phân quyền:**
     - Người dùng Mobile đăng nhập lần đầu tự động nhận `role = 'user'`. Client không thể tự nâng role.
     - **Admin đầu tiên (First Admin):** Được cấu hình thủ công trong Firebase Console và ghi rõ danh tính/email trong `README.md`.
     - Chỉ Admin mới có quyền đổi role của **người khác**. Không một ai (kể cả admin) được tự đổi role của chính mình.
     - Mỗi client bắt buộc phải chặn tài khoản sai role và hiển thị thông báo từ chối rõ ràng (Role gate).
2. **Mô hình dữ liệu chuẩn (`docs/data-model.md`):**
   - Tài liệu hóa toàn diện 6 collections Firestore: `users`, `recipes`, `meal_plans`, `shopping_lists`, `announcements`, `report_exports`.
   - Mỗi collection nêu rõ: Danh sách fields, kiểu dữ liệu, các màn hình sử dụng, quyền Create / Read / Update / Delete theo từng role, và các trạng thái cho phép chuyển đổi.
3. **Security Rules Deny-by-default:**
   - Áp dụng nguyên tắc chặn mặc định (`match /{document=**} { allow read, write: if false; }`). Tuyệt đối không có bất kỳ rule nào chứa `if true`.
   - Kiểm tra định dạng dữ liệu (data shape) và giới hạn trường cập nhật qua `affectedKeys()`.
   - **Bộ test Emulator Suite (Appendix B):** Viết test tự động trên Firestore Emulator bao phủ tối thiểu 1 ca cho phép (Allowed) và 1 ca bị từ chối (Denied) cho từng role trên mỗi collection (ma trận R-01 đến R-33 đạt 100% pass).

---

### KHỐI 3: Luồng Liên Vai Trò Thời Gian Thực (Cross-Role Flow)
*Căn cứ Section 3, Appendix C của Handout — Tương ứng Slide 8 trong dàn ý slide.*

1. **Bản chất của Cross-Role Flow:**
   - Một hành động bắt đầu từ người dùng trên Mobile được gửi lên Firestore, chuyển giao cho Staff/Admin trên Web xử lý, và kết quả đồng bộ ngược lại tức thì (Real-time) về Mobile mà không cần tải lại trang.
2. **Kịch bản chuẩn của Longvita:**
   - **Bước 1 (Mobile — `user`):** Người dùng tạo thực đơn 7 ngày, chuyển trạng thái từ `draft` $\to$ `submitted` (Bấm *"Gửi chuyên gia phê duyệt"*).
   - **Bước 2 (Web Admin — `staff`/`admin`):** Hàng đợi Review Queue nhận sự kiện real-time, hiển thị thực đơn cần duyệt. Staff xem xét và bấm:
     - *Duyệt (Approve):* Chuyển trạng thái sang `approved`.
     - *Từ chối (Reject):* Chuyển trạng thái sang `rejected` và bắt buộc nhập lý do từ chối (`reviewerReason` $\le 500$ ký tự).
   - **Bước 3 (Mobile Real-time Update):** Màn hình Mobile tự động cập nhật trạng thái mới (Đã duyệt / Bị từ chối kèm lý do) qua Firestore Snapshot Listener, đồng thời tạo thông báo phản hồi trong hộp thư đến.
3. **Tài liệu & Bằng chứng bắt buộc (`docs/cross-role-flow.md`):**
   - Sơ đồ tuần tự (Mermaid Sequence Diagram) chi tiết các bước.
   - Bảng ánh xạ collections, fields và security rules cho từng bước.
   - **Bảng đo thời gian trễ thực tế (Latency Measurement):** Bắt buộc chạy thử nghiệm **3 lần liên tiếp** trên hệ thống đã deploy thực tế, đo số giây từ lúc bấm gửi trên client này đến khi client kia nhận được bản cập nhật.

---

### KHỐI 4: Trang Quản Trị Web Admin Trên Firebase Hosting (Web Admin Requirements)
*Căn cứ Section 7 của Handout — Tương ứng Slide 6, Slide 7 trong dàn ý slide.*

1. **Triển khai thực tế (Deployment):**
   - Xây dựng bằng Flutter Web, deploy lên **Firebase Hosting**.
   - URL công khai (Public Deployed URL) phải mở và hoạt động ổn định trên **cửa sổ ẩn danh (Incognito)** tại thời điểm chấm bài.
2. **Yêu cầu 4 màn hình chính + Form thông báo:**
   - **Màn hình 1 — Sign-In & Role Gate:** Đăng nhập bằng Google. Chấp thuận tài khoản `staff` hoặc `admin`; từ chối tài khoản `user` với thông báo lỗi quyền hạn rõ ràng.
   - **Màn hình 2 — Quản lý công thức (Recipe Management):** Danh sách công thức, tìm kiếm, xem chi tiết, tạo mới, chỉnh sửa và lưu trữ (archive/restore thay vì xóa cứng để giữ toàn vẹn dữ liệu).
   - **Màn hình 3 — Hàng đợi xét duyệt (Review Queue):** Danh sách các thực đơn có `status == 'submitted'`. Nút Duyệt (Approve) và Từ chối (Reject - yêu cầu dialog nhập lý do).
   - **Màn hình 4 — Bảng điều khiển (Dashboard):** Hiển thị tối thiểu **3 chỉ số tổng hợp (figures from aggregation queries)** và **1 biểu đồ trực quan (chart)** có khả năng co giãn responsive trên màn hình rộng.
   - **Form Thông báo (Announcement Form):** Form soạn tiêu đề, nội dung và gửi thông báo chung. Khi gửi thành công, thông báo sẽ hiển thị trực tiếp trong hộp thư (Inbox) của ứng dụng Mobile.
3. **Chất lượng giao diện & Trạng thái (UI States):**
   - Kế thừa toàn bộ Design tokens từ Lab 2 (màu sắc, typography, components).
   - Thể hiện đầy đủ 4 trạng thái giao diện: **Loading, Empty, Error, Data/Success**.
   - Bảng kiểm tra chất lượng giao diện hoàn tất tại [`docs/web-admin-checklist.md`](web-admin-checklist.md) với ảnh chụp từng màn hình.

---

### KHỐI 5: Tính Năng AI Gemini — Đạt Cấp Độ Level 2 (AI Requirements)
*Căn cứ Section 8 của Handout — Tương ứng Slide 9, Slide 10 trong dàn ý slide.*

1. **Tích hợp Google Gemini Developer API:**
   - Tính năng AI hỗ trợ trực tiếp một bước trong luồng Lab 2 (Gợi ý bữa ăn trường thọ cá nhân hóa tại S03/S06).
2. **Cấp độ đánh giá (AI Levels):**
   - *Level 1 (Partial mark):* Sinh văn bản thuần túy dạng luồng (text streamed).
   - *Level 2 (Full mark — BẮT BUỘC):* **Dữ liệu có cấu trúc (Structured Output: JSON $\to$ Dart Model)**, hiển thị trên giao diện và cho phép người dùng xác nhận/chỉnh sửa trước khi lưu.
   - *Level 3 (Bonus +0.5):* Function Calling truy vấn trực tiếp trên dữ liệu người dùng.
3. **Các quy tắc tuân thủ an toàn:**
   - **Bảo mật danh tính (Zero PII):** Tuyệt đối không gửi họ tên, email, ảnh cá nhân hay plain UID lên API AI.
   - **Cấu hình qua Firebase Remote Config:** Quản lý tên model (`gemini_model_name`), system prompt và **cờ bật/tắt tính năng (`ai_feature_enabled`)**. Khi tắt cờ trên Console, ứng dụng tự động dùng fallback mà không cần build lại.
   - **Cơ chế dự phòng khi lỗi (Graceful Fallback):** Khi mất mạng, timeout hoặc chạm hạn mức API (HTTP 429 Quota Exceeded), hệ thống lập tức chuyển sang thuật toán Fallback nội bộ để trả về món ăn mẫu chuẩn sách TS. Valter Longo. Ứng dụng **không bao giờ bị crash hay đơ giao diện**.
   - **Gắn nhãn & Cho phép chỉnh sửa:** Giao diện có badge *"AI-Generated"* và mở Sheet cho phép người dùng chỉnh sửa tên món, nguyên liệu, calo trước khi chấp nhận.
   - **Ghi nhận sự kiện Analytics:** Đo lường 3 sự kiện chuẩn: `ai_request`, `ai_result_accepted`, `ai_error`.
4. **Tài liệu minh chứng (`docs/ai-feature.md`):**
   - Báo cáo chi tiết **3 cặp Input / Output thực tế** (Breakfast, Lunch, Dinner).
   - Báo cáo chi tiết **1 kịch bản xử lý lỗi thực tế** (Handled Failure Scenario) kèm log và ảnh chụp.

---

### KHỐI 6: Kiểm Thử Toàn Diện & AI-Assisted Code Review (Testing & Quality)
*Căn cứ Section 9, 10 của Handout — Tương ứng Slide 11, Slide 12, Slide 13 trong dàn ý slide.*

1. **Kiểm thử tự động E2E Mobile (Google ARTEMIS):**
   - Bao phủ toàn bộ các luồng Lab 2, các bước mobile của Cross-role flow và tính năng Gemini AI.
   - Mỗi test case chạy tối thiểu **3 lần liên tiếp** trên thiết bị thật/máy ảo để đo tỷ lệ đạt (**pass rate**), phát hiện và giải thích nguyên nhân flaky test.
2. **Kiểm thử Security Rules trên Firestore Emulator:**
   - Chạy toàn bộ test suite ma trận quyền (`firestore.rules.matrix.test.js`), đạt 100% pass cho cả các ca Allowed và Denied.
3. **Kiểm thử giao diện Web Admin:**
   - Thực hiện kiểm chứng 18 tiêu chí (WEB-01 đến WEB-18) trong `web-admin-checklist.md`, kiểm tra phản hồi responsive trên desktop (1440x900) và mobile viewport.
4. **Đo đạc thực tế Cross-role Flow:**
   - Chạy thực tế 3 lần trên hệ thống production đã deploy, ghi nhận log và thời gian trễ đồng bộ.
5. **AI-Assisted Code Review trên mã nguồn mới:**
   - Chạy công cụ AI Code Review (CodeRabbit / Codex) trên các Pull Request tính năng mới của Final Assignment (Web Admin, Cross-role, AI Service).
   - Ghi nhận tối thiểu **3 findings thực tế** có vị trí `file:line`, quyết định kỹ thuật (Accepted / Modified / Rejected) và commit sửa lỗi liên kết. Lưu tại `docs/test-report.md`.

---

## 3. Dàn Ý Chuẩn 15 Slide Thuyết Trình Final Assignment

Bộ slide nộp dưới dạng PDF (12–15 slide), tên file: `slides/Final_<StudentID>_slides.pdf`:

| Slide | Tiêu đề Slide | Thông điệp trọng tâm & Nội dung chi tiết | Minh chứng / Link đối chiếu |
|:---:|:---|:---|:---|
| **1** | **Title & System Overview** | - Tên đề tài: **Longvita — Hệ thống dinh dưỡng trường thọ toàn diện**.<br/>- Giới thiệu sinh viên/nhóm, môn học PRM393, giảng viên hướng dẫn.<br/>- Bàn giao cốt lõi: Link GitHub Repo, URL Web Admin đã deploy, Link Demo Video. | - Link `README.md`<br/>- Web URL: `https://longvita-8da7e.web.app` |
| **2** | **Lab 2 & Lab 3 Recap** | - Nhắc lại Persona (Minh Anh, 28 tuổi), Success Criterion, 3 User flows.<br/>- Đóng gói kết quả Lab 3: Mã nguồn hoàn thiện, các review findings đã đóng, chuyển đổi sang kiến trúc Monorepo. | - Link `docs/gap-review.md`<br/>- Ảnh tổng thể Persona & Flows |
| **3** | **System Architecture: One Firestore, Two Clients** | - Sơ đồ kiến trúc tổng thể toàn hệ thống.<br/>- 1 Firestore dùng chung; 2 client độc lập (Mobile Flutter & Web Admin Flutter Web).<br/>- Gói dùng chung `packages/core/` (Models, Services, Theme, Widgets).<br/>- Xác định ranh giới No-Cost: Không dùng Cloud Functions / Cloud Storage. | - Sơ đồ kiến trúc Monorepo<br/>- Link `docs/architecture.md`<br/>- Cấu trúc thư mục `packages/core/` |
| **4** | **Data Model & Role-Based Access Control** | - 6 collections Firestore (`users`, `recipes`, `meal_plans`, `shopping_lists`, `announcements`, `report_exports`).<br/>- 3 vai trò: `user`, `staff`, `admin`. Admin đầu tiên cấu hình từ Console.<br/>- Hợp đồng chuyển đổi trạng thái thực đơn (`draft` $\to$ `submitted` $\to$ `approved` / `rejected`). | - Bảng dữ liệu Appendix A<br/>- Link `docs/data-model.md`<br/>- Ảnh Firestore Console collections |
| **5** | **Security Rules & Emulator Testing** | - Nguyên tắc Deny-by-default; xác thực role trên mỗi lượt ghi.<br/>- Kiểm tra định dạng dữ liệu, chống client tự nâng role.<br/>- Kết quả chạy test Emulator: Ma trận R-01 đến R-33 đạt 100% Pass (Allowed & Denied mỗi role). | - File `firebase/firestore.rules`<br/>- Bảng ma trận test rules Appendix B<br/>- Log chạy `npm run test:rules` pass |
| **6** | **Mobile Client: Complete Scope & Real-Time Inbox** | - Toàn bộ 10+2 màn hình hoạt động trơn tru với dữ liệu thật Firestore.<br/>- Hộp thư đến (Inbox) tiếp nhận thông báo thời gian thực từ Staff/Admin Web.<br/>- Trải nghiệm ngoại tuyến: Lưu trữ thực đơn cục bộ, xuất báo cáo PDF. | - Ảnh chụp màn hình Mobile<br/>- Ảnh Inbox nhận thông báo real-time<br/>- Link `mobile/` |
| **7** | **Web Admin: Deployed Management & Dashboard** | - Giới thiệu URL đã deploy trên Firebase Hosting.<br/>- 4 màn hình: Sign-in Role gate, Quản lý Recipes (CRUD + Archive), Review Queue, Dashboard (3 aggregation figures + Responsive chart).<br/>- Form đăng thông báo toàn hệ thống. | - URL Hosting kiểm tra ẩn danh<br/>- Ảnh 4 màn hình Web trên Desktop & Mobile viewport<br/>- Link `docs/web-admin-checklist.md` |
| **8** | **Cross-Role Flow: Mobile $\longleftrightarrow$ Web Admin** | - **Sơ đồ tuần tự (Mermaid Sequence Diagram)** luồng tương tác 3 bước.<br/>- User gửi thực đơn trên Mobile $\to$ Staff duyệt/từ chối trên Web $\to$ Mobile nhận kết quả tức thì.<br/>- Bảng số liệu đo thời gian trễ thực tế qua 3 lần chạy trên production. | - Sơ đồ tuần tự tương tác<br/>- Bảng đo thời gian 3 lượt live<br/>- Link `docs/cross-role-flow.md` |
| **9** | **Gemini AI Feature: Level 2 Structured Output** | - Tích hợp Google Gemini Developer API gợi ý bữa ăn trường thọ tại bước lập kế hoạch.<br/>- Phân tích JSON có cấu trúc thành Dart Model (`AiMealRecommendation`).<br/>- Badge "AI-Generated" và Bottom Sheet cho phép người dùng xem xét, chỉnh sửa trước khi lưu.<br/>- Cam kết bảo mật Zero PII tuyệt đối. | - 3 ví dụ Input/Output thực tế<br/>- Ảnh giao diện AI Sheet có thể chỉnh sửa<br/>- Link `docs/ai-feature.md` |
| **10** | **AI Failure Handling & Remote Config Control** | - Xử lý lỗi linh hoạt (Graceful Failure): Tự động fallback về thực đơn Valter Longo chuẩn khi mất mạng hoặc dính HTTP 429 Quota.<br/>- Điều khiển từ xa qua Remote Config: Cờ bật/tắt `ai_feature_enabled`, đổi model AI.<br/>- Ghi nhận đầy đủ 3 sự kiện Analytics: `ai_request`, `ai_result_accepted`, `ai_error`. | - Sơ đồ luồng Fallback<br/>- Ảnh trước/sau khi tắt AI từ Console<br/>- Log sự kiện Analytics DebugView |
| **11** | **Automated E2E Testing with ARTEMIS** | - Bộ test tự động điều khiển thiết bị bằng Google ARTEMIS Agent.<br/>- Bao phủ toàn bộ các luồng Lab 2, bước mobile cross-role và tính năng AI.<br/>- Bảng Pass-rate ($\ge 3$ runs/test), phân tích xử lý test flaky, trace IDs và replay log. | - Bảng kết quả pass-rate tổng hợp<br/>- File log runs: `evidence/artemis/raw/`<br/>- Link `docs/test-report.md` |
| **12** | **Web Admin Verification Checklist** | - Báo cáo nghiệm thu 18 tiêu chí (WEB-01 đến WEB-18) của Web Admin.<br/>- Bằng chứng xử lý các trạng thái: Loading, Empty, Error, Role gate rejection.<br/>- Kiểm chứng hiển thị co giãn responsive trên màn hình rộng 1440x900 và mobile viewport 412x915. | - Ma trận checklist 18 tiêu chí<br/>- Ảnh chứng minh các trạng thái lỗi & responsive<br/>- Link `docs/web-admin-checklist.md` |
| **13** | **AI-Assisted Code Review on New Features** | - Đánh giá mã nguồn trên Pull Request cho các tính năng mới của Final.<br/>- Thống kê các phát hiện: Kiến trúc Monorepo, bảo mật API key, kiểm soát concurrency.<br/>- Bảng $\ge 3$ findings tiêu biểu kèm lý do kỹ thuật và link fix commit cụ thể. | - Bảng findings & decisions<br/>- Link các commit sửa lỗi trên GitHub<br/>- Link `docs/code-review.md` |
| **14** | **Challenges & Lessons Learned** | - Thách thức kỹ thuật: Xây dựng Monorepo với Dart Pub Workspace, thiết kế Firestore Security Rules phức tạp không dùng custom backend, hạn mức miễn phí của Gemini API.<br/>- Bài học kinh nghiệm: Tầm quan trọng của deny-by-default, tái sử dụng Design tokens giữa Web/Mobile, nguyên tắc Graceful Degradation. | - Các bài học thực tế đúc kết từ quá trình thực hiện |
| **15** | **Summary, Demo Accounts & AI Disclosure** | - Tổng kết hệ thống hoàn chỉnh đạt 100% tiêu chí Final Assignment.<br/>- Danh sách tài khoản demo theo từng vai trò (`user`, `staff`, `admin`).<br/>- **Bảng công bố công cụ AI (AI Disclosure):** Công cụ đã dùng, phạm vi và mục đích.<br/>- Lời cảm ơn và mở phiên vấn đáp (Q&A). | - Bảng tài khoản demo<br/>- Bảng AI Disclosure từ `README.md`<br/>- Link Demo Video & Báo cáo PDF |

---

## 4. Bảng Mã Màu Dự Án Phục Vụ Thiết Kế Slide (Project Color Palette)

Đồng bộ màu sắc slide theo đúng nhận diện thương hiệu Longvita tại [`packages/core/lib/theme/app_colors.dart`](../packages/core/lib/theme/app_colors.dart):

| Thành phần Slide | Token Code | Mã HEX | Giá trị RGB | Ứng dụng cụ thể trên Slide |
|---|:---|:---:|:---:|---|
| **Nền Slide chính (Background)** | `bgCanvas` | **`#F6F1E7`** | `246, 241, 231` | Nền toàn bộ slide. Tone kem ấm/linen sang trọng, dịu mắt khi trình chiếu. |
| **Tiêu đề & Điểm nhấn chính** | `actionPrimary` | **`#476429`** | `71, 100, 41` | Tiêu đề Slide (Headings), số thứ tự, icon thương hiệu, viền active. Xanh ô-liu trường thọ. |
| **Chữ nội dung chính (Body Text)** | `textPrimary` | **`#2F3B2A`** | `47, 59, 42` | Văn bản chính, bullet points. Tương phản vượt trội **10.48:1** trên nền kem. |
| **Chữ phụ & Chú thích ảnh** | `textSecondary` | **`#5C6B53`** | `92, 107, 83` | Subtitles, nguồn tài liệu `docs/`, chú thích ảnh chụp màn hình (Tương phản **5.06:1**). |
| **Khung thẻ nội dung (Card Container)**| `bgSurface` | **`#FFFFFF`** | `255, 255, 255` | Thẻ trắng bo góc đặt trên nền kem để chứa bảng dữ liệu hoặc khung ảnh minh chứng. |
| **Highlight & Badge thành tựu** | `bgSelected` | **`#E4F2DA`** | `228, 242, 218` | Pill tags, nhãn trạng thái (Approved, 100% Pass, Done), highlight số liệu quan trọng. |
| **Hộp lưu ý đặc biệt / Trích dẫn** | `bgPeach` | **`#F2DFCE`** | `242, 223, 206` | Callout box màu đào ấm dùng cho trích dẫn sách TS. Longo, lưu ý kiến trúc đặc biệt. |
| **Đường viền ngăn cách (Borders)** | `borderDecorative`| **`#DCCDB0`** | `220, 205, 176` | Đường kẻ chia cột, viền bảng số liệu, đường viền nhẹ quanh ảnh evidence. |
| **Cảnh báo lỗi & Từ chối** | `feedbackError` | **`#BA1A1A`** | `186, 26, 26` | Nhãn lỗi, trạng thái Rejected, ca kiểm thử Denied, cảnh báo bảo mật. |

**Font chữ đề xuất:**
- **Tiêu đề Bìa (Brand Title):** **Fraunces** *(hoặc Serif hiện đại như Playfair Display)*.
- **Tiêu đề trang (Headings):** **Newsreader** *(hoặc Georgia, Merriweather)*.
- **Nội dung & Bảng biểu (Body):** **Quicksand** *(hoặc Montserrat, Nunito)*.

---

## 5. Quy Cách Video Demo (8–12 Phút) & Phiên Vấn Đáp (Section 10 & 12)

### Yêu cầu Video Demo (8–12 phút, quay live không cắt ghép dàn dựng):
- **Hiển thị song song hai màn hình (Side-by-side):** Khi thực hiện luồng Cross-role, video phải quay đồng thời cả màn hình Mobile và Web Admin để chứng minh tính năng cập nhật thời gian thực (Real-time).
- **Thứ tự các nội dung cần demo:**
  1. Trình diễn các luồng chính trên ứng dụng Mobile với dữ liệu thật Firestore.
  2. Mở từng màn hình của Web Admin (Sign-in với Google, Recipes Management, Review Queue, Dashboard responsive, Announcement Form).
  3. Thao tác luồng Cross-role trực tiếp: Gửi thực đơn từ Mobile $\to$ Web nhận real-time và Duyệt/Từ chối $\to$ Mobile tự cập nhật kết quả và hiển thị thông báo.
  4. Trình diễn tính năng Gemini AI (Level 2 Structured Output), chỉnh sửa kết quả, và thao tác tắt Remote Config trên Console để xem app tự động fallback.
  5. Chiếu một lượt chạy test tự động trên thiết bị.

### Phiên vấn đáp trực tiếp (Verification Review ~10 phút):
Giảng viên có thể yêu cầu sinh viên thực hiện trực tiếp tại chỗ:
1. Thao tác chạy trực tiếp luồng liên vai trò (Cross-role flow).
2. Đổi một giá trị Remote Config trên Firebase Console và kiểm tra phản ứng của app.
3. Giải thích logic của một Security Rule trong `firestore.rules`.
4. Giải thích quyết định kỹ thuật của một finding trong AI Code Review.

---

## 6. Checklist Kiểm Duyệt Trước Khi Nộp Bài (Submission Checklist)

Đối chiếu đầy đủ 8 tiêu chuẩn cốt lõi của Final Assignment:

- [ ] **1. Gap Review Closed:** Hoàn tất rà soát và đóng toàn bộ các tồn đọng của Lab 2 & Lab 3 tại `docs/gap-review.md`.
- [ ] **2. Data Model & Rules:** `docs/data-model.md` đầy đủ 6 collections; `firestore.rules` deny-by-default; 100% test Emulator pass.
- [ ] **3. Mobile App:** Hoạt động ổn định trên Firestore, nhận thông báo thời gian thực từ Web vào Inbox.
- [ ] **4. Web Admin:** Đủ 4 màn hình + Announcement form; deploy thành công lên Firebase Hosting; URL mở được ở chế độ ẩn danh.
- [ ] **5. Cross-Role Flow:** Hoạt động live thời gian thực giữa Mobile và Web; tài liệu hóa và có số liệu đo 3 lượt tại `docs/cross-role-flow.md`.
- [ ] **6. Gemini AI Feature:** Đạt chuẩn Level 2 Structured Output, có Remote Config toggle, App Check, cơ chế Graceful Fallback và Zero PII tại `docs/ai-feature.md`.
- [ ] **7. Test & AI Code Review:** Bằng chứng kiểm thử ARTEMIS, rules matrix, web checklist và $\ge 3$ findings AI review tại `docs/test-report.md`.
- [ ] **8. Deliverables & Incognito Check:** `README.md`, Báo cáo PDF (10–15 trang), Slide PDF (12–15 slide), Link Demo Video và Web URL đều mở được bình thường trong cửa sổ ẩn danh.
