# Đặc Tả & Dàn Ý Bộ Slide Thuyết Trình Lab 3 — Longvita

> **Tài liệu:** Hướng dẫn, cấu trúc nội dung và tiêu chuẩn dàn trang bộ Slide thuyết trình Lab 3 (*Cloud-Enabled Mobile App*).  
> **Căn cứ:** Handout PRM393 Lab 3 — Section 9 (*Presentation Slide Deck*) & Section 11 (*Verification Review*).  
> **Mã công việc:** S8-10 (Tổng hợp và xuất bản Slide Deck).  
> **Người phụ trách:** Thắng VLQ (Technical Architect & Lead Slides).  
> **Phối hợp nội dung:** Thái An (Instrumentation & Test), Charlie (Firebase & System), Hoàng (UI & Data Flows).  
> **Quy cách nộp:** File PDF từ 12–15 slide, lưu tại `slides/Lab03_<StudentID>_slides.pdf`.

---

## 1. Yêu Cầu Chung Của Bộ Slide

Theo quy định tại Section 9 của Handout, bộ slide phải đảm bảo các tiêu chí sau:
- **Độ dài bắt buộc:** Đúng **12–15 slide**, xuất file định dạng **PDF**.
- **Tính tự giải thích (Self-explanatory):** Người xem **chưa từng đọc code** vẫn hiểu bạn đã làm gì, hệ thống hoạt động như thế nào và **vì sao biết nó chạy đúng**.
- **Nguyên tắc trực quan:** Mỗi slide tập trung vào **một thông điệp chính**, đọc lướt nhanh được; tuyệt đối không nhồi nhét khối chữ lớn (no wall of text).
- **Khẳng định phải có minh chứng (Evidence-based):** Mọi khẳng định “app chạy được / Firebase hoạt động / test pass” đều bắt buộc phải kèm **ảnh chụp thực tế từ app, Firebase Console, DebugView, Crashlytics hoặc kết quả chạy kiểm thử ARTEMIS**.
- **Ảnh chụp có chú thích:** Mọi hình ảnh/ảnh chụp màn hình đều phải có caption hoặc callout chỉ rõ chi tiết cần quan sát, không đưa ảnh mơ hồ, vô nghĩa.
- **Dẫn link tài liệu:** Sử dụng **đường dẫn (link) tới các file trong `docs/`** thay vì sao chép toàn bộ văn bản dài vào slide.
- **Minh bạch AI (AI Disclosure):** Khai báo rõ ràng danh sách **các công cụ AI đã dùng để làm slide, viết code, sinh test và review**.
- **Phục vụ Verification Review:** Slide được dùng trực tiếp cho phiên vấn đáp kiểm chứng ở Section 11, do đó bố cục phải dễ mở, dễ trình chiếu và đối chiếu trực tiếp với mã nguồn và Console.

---

## 2. Danh Sách Nội Dung Bắt Buộc Tối Thiểu

Handout quy định bộ slide phải bao hàm tối thiểu 11 nhóm nội dung cốt lõi:

1. **Topic, Persona và Success Criterion** kế thừa từ Lab 2.
2. **Các màn hình chính đặt cạnh nhau: Figma vs App**, kèm **các sai lệch (deviations)** so với thiết kế gốc.
3. **Architecture** — Sơ đồ phân tầng MVVM với luồng phụ thuộc một chiều.
4. **Design System trong mã nguồn**: Design Tokens → `ThemeData`; UI Components → Reusable Widgets.
5. **Firebase Architecture & Design**: Mỗi dịch vụ Firebase 1 slide riêng biệt, kèm **cơ chế xử lý tình huống lỗi (failure case)**.
6. **Analytics Event Plan** kèm **bằng chứng quan sát DebugView**.
7. **Crashlytics + Remote Config Evidence**.
8. **Kế hoạch kiểm thử ARTEMIS E2E** và bảng kết quả tỷ lệ đạt (**pass rate**).
9. **AI-Assisted Code Review findings** và các quyết định kỹ thuật (**Accepted / Modified / Rejected**).
10. **Thách thức kỹ thuật (Challenges) và bài học kinh nghiệm (Lessons Learned)**.
11. **Danh sách công cụ AI đã sử dụng** trong suốt quá trình thực hiện bài nộp.

---

## 3. Quy Chuẩn Thị Giác & Bảng Mã Màu Dự Án (Color Palette & Visual Identity Cho Slide)

Để bộ Slide có tính nhận diện thương hiệu đồng nhất với ứng dụng Longvita và đạt độ tương phản chuẩn Accessibility (WCAG), slide nên được thiết kế theo đúng bảng mã màu từ file mã nguồn [`packages/core/lib/theme/app_colors.dart`](../packages/core/lib/theme/app_colors.dart):

### Bảng mã màu chuẩn (Project Color Palette):

| Vai trò thiết kế Slide | Token Code | Mã HEX | Màu RGB | Tác dụng & Vị trí áp dụng trên Slide |
|---|:---|:---:|:---:|---|
| **Nền Slide chính (Background)** | `bgCanvas` | **`#F6F1E7`** | `246, 241, 231` | Nền toàn bộ các trang slide (Tone kem ấm, tự nhiên, dịu mắt, tránh màu trắng chói). |
| **Tiêu đề chính & Điểm nhấn** | `actionPrimary` | **`#476429`** | `71, 100, 41` | Tiêu đề từng slide (Heading), số thứ tự bước, icon nổi bật, đường kẻ line nhấn. |
| **Chữ nội dung chính (Body Text)** | `textPrimary` | **`#2F3B2A`** | `47, 59, 42` | Toàn bộ chữ nội dung, bullet points. Đạt tỷ lệ tương phản cực cao **10.48:1** trên nền kem. |
| **Chữ phụ & Chú thích (Subtitles)** | `textSecondary` | **`#5C6B53`** | `92, 107, 83` | Chú thích ảnh chụp, nguồn tài liệu `docs/`, thông số kỹ thuật phụ (Tương phản **5.06:1**). |
| **Khung chứa nội dung (Card Container)**| `bgSurface` | **`#FFFFFF`** | `255, 255, 255` | Hộp thẻ (Cards) đặt trên nền kem để chứa văn bản, bảng số liệu hoặc khung ảnh minh chứng. |
| **Highlight & Badge thành công** | `bgSelected` | **`#E4F2DA`** | `228, 242, 218` | Nền pill badge trạng thái (Pass, Resolved, Handled), ô tổng kết thành tựu. |
| **Thẻ ghi chú đặc biệt / Trích dẫn** | `bgPeach` | **`#F2DFCE`** | `242, 223, 206` | Nền hộp ghi chú về sách TS. Valter Longo, quy tắc đạm hoặc lưu ý quan trọng. |
| **Đường viền ngăn cách (Borders)** | `borderDecorative`| **`#DCCDB0`** | `220, 205, 176` | Đường kẻ phân chia cột, viền nhẹ quanh ảnh chụp màn hình để tách biệt với nền. |
| **Cảnh báo lỗi & Failure Case** | `feedbackError` | **`#BA1A1A`** | `186, 26, 26` | Dùng cho nhãn lỗi, kịch bản Failure Case, Bug finding của AI review, trạng thái Denied. |

### Bộ Font chữ gợi ý (Typography System):
- **Slide Title / Cover Brand:** **Fraunces** (hoặc Serif cổ điển/hiện đại tương đương) — Tạo cảm giác sang trọng, gắn với sách dinh dưỡng.
- **Heading Slide:** **Newsreader** (hoặc Georgia, Playfair Display) — Serif thanh lịch, dễ đọc khi trình chiếu.
- **Body & Data Table:** **Quicksand** (hoặc Montserrat, Nunito) — Sans-serif bo tròn nhẹ, hiện đại, rõ nét ở mọi tỷ lệ thu phóng.

---

## 4. Dàn Ý Chi Tiết 15 Slide Đề Xuất (Outline chuẩn 15 Slide)

| Slide | Tiêu đề slide | Thông điệp trọng tâm & Nội dung chi tiết | Bằng chứng & Link đối chiếu trong Repo |
|:---:|:---|:---|:---|
| **1** | **Title & Project Overview** | - Tên đề tài: **Longvita — Ứng dụng dinh dưỡng trường thọ (Valter Longo)**.<br/>- Thông tin cá nhân/nhóm: StudentID, Họ tên, Khóa học PRM393, Giảng viên hướng dẫn.<br/>- Mã nguồn & Bàn giao: Link GitHub repo, Demo Video URL (YouTube/Drive). | - Link [`README.md`](../README.md)<br/>- Link GitHub repository |
| **2** | **Lab 2 Recap & Persona** | - **Persona:** Minh Anh (28 tuổi, nhân viên văn phòng).<br/>- **Success Criterion:** Tạo thực đơn 7 ngày chuẩn đạm Longo trong $< 3$ phút và có danh sách mua sắm tiện lợi.<br/>- Tóm tắt 3 User Flows: Lập kế hoạch (Flow 1), Tổng hợp nguyên liệu (Flow 2), Tra cứu/đổi món (Flow 3). | - Link [`docs/design-traceability.md`](design-traceability.md)<br/>- Ảnh tổng quan Figma Page 01–06 |
| **3** | **Key Screens: Figma vs. App** | - Đặt ảnh thiết kế Figma và giao diện Flutter App thực tế song song.<br/>- Liệt kê các sai lệch (deviations) hợp lý trong quá trình code (ví dụ: tối ưu thẻ món ăn, cải thiện contrast, hỗ trợ Dark Mode/A11y).<br/>- Lý do kỹ thuật cho từng thay đổi giao diện. | - Ảnh side-by-side tại `evidence/ui/`<br/>- Link [`docs/design-traceability.md`](design-traceability.md)<br/>- Link [`docs/hoang-figma-deviation-audit.md`](hoang-figma-deviation-audit.md) |
| **4** | **Architecture: MVVM Layering** | - Mô hình kiến trúc MVVM với Provider Dependency Injection.<br/>- Chiều phụ thuộc 1 chiều: `View` $\to$ `ViewModel` $\to$ `Service` $\to$ `Cloud Firestore / Firebase`.<br/>- Tuyệt đối không gọi Firebase SDK trong Widget; tách biệt Business Logic khỏi `build()`. | - Sơ đồ Mermaid Layer Diagram<br/>- Link [`docs/architecture.md`](architecture.md) |
| **5** | **Design System in Code** | - Chuyển hóa Design Tokens thành `ThemeData` (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`).<br/>- 9 Reusable Widgets dùng chung (`AppButton`, `AppCard`, `AppTextField`, `AppDialog`...).<br/>- Tiêu chuẩn A11y: Touch target $\ge 48 \times 48$ dp, text contrast $\ge 4.5:1$, nhãn Semantics. | - Link [`packages/core/lib/theme/`](../packages/core/lib/theme/)<br/>- Link [`packages/core/lib/widgets/`](../packages/core/lib/widgets/)<br/>- Ảnh audit TalkBack tại `evidence/a11y/` |
| **6** | **Firebase Auth & Session** | - Google Sign-In với Firebase Authentication; tự động cấp `role = 'user'`.<br/>- Chuyển hướng AuthGate linh hoạt; Session epoch dọn sạch dữ liệu khi đổi tài khoản.<br/>- **Failure Handling:** Hủy chọn Google picker hiển thị SnackBar cảnh báo; mất mạng hiển thị Retry. | - Ảnh đăng nhập & Firebase Console Users: `evidence/auth/S3-9-20261102/`<br/>- Link [`docs/architecture.md`](architecture.md) |
| **7** | **Cloud Storage (PDF Export)** | - Cơ chế xuất báo cáo PDF thực đơn và upload theo đường dẫn `reports/{uid}/{exportId}.pdf`.<br/>- Hiển thị thanh tiến trình Upload và cung cấp link tải/xem lại.<br/>- **Failure Handling:** Rules bảo vệ chỉ cho phép user đọc/ghi thư mục của chính mình; hỗ trợ xuất offline khi mất kết nối. | - File rules: `firebase/storage.rules`<br/>- Ảnh Storage Emulator upload: `evidence/storage/S4-11-emulator-20261102/`<br/>- Link [`docs/data-model.md`](data-model.md) |
| **8** | **Firebase Cloud Messaging (FCM)** | - Tiếp nhận thông báo push trên cả 3 trạng thái: Foreground (in-app Banner), Background (System Tray), Terminated (Cold-start).<br/>- Xin quyền Notification runtime trên Android 13+.<br/>- Chạm vào thông báo điều hướng chính xác vào màn hình Profile / Hộp thư.<br/>- **Failure Handling:** Lọc tin theo `recipient_uid`, chặn hiển thị tin trùng lặp. | - Ảnh test message từ Console:<br/>  `evidence/fcm/S4-12-foreground-20261103/`<br/>  `evidence/fcm/S4-15-push-20261102/` |
| **9** | **Analytics Event Plan & DebugView** | - 8 sự kiện đo lường chuẩn hóa cover trọn vẹn phễu người dùng.<br/>- Thông số (params) có kiểu rõ ràng; cam kết Zero PII (không gửi họ tên, email, UID plain text).<br/>- **Minh chứng:** Luồng sự kiện theo thời gian thực hiển thị trên Firebase Console DebugView. | - Bảng thông số sự kiện<br/>- Ảnh chụp màn hình DebugView:<br/>  `evidence/analytics/S5-4-debugview-20261102/`<br/>- Link [`docs/analytics-plan.md`](analytics-plan.md) |
| **10** | **Crashlytics Monitoring** | - Bắt và ghi nhận ngoại lệ luồng thật (Handled Non-Fatal Error) kèm stack trace.<br/>- Gán ngữ cảnh phân loại: User Identifier, `current_flow`, `current_screen`.<br/>- Nút kích hoạt Test Crash phục vụ nghiệm thu.<br/>- **Evidence:** Ảnh chụp Crashlytics Dashboard trên Console hiển thị crash và non-fatal. | - Ảnh console Crashlytics:<br/>  `evidence/crashlytics/S4-13-test-crash-20261102/`<br/>  `evidence/failure-cases/S5-10-THANG-20261106/` |
| **11** | **Remote Config Dynamic Control** | - Quản trị từ xa ít nhất 2 tham số nhìn thấy được (`max_meal_recommendations`, `enable_longevity_score`, `banner_announcement`).<br/>- Nạp sẵn In-App Defaults đồng bộ với `firebase/remote-config-defaults.json`.<br/>- Thay đổi trên Console cập nhật UI tức thì không cần rebuild app.<br/>- **Failure Handling:** Tự động fallback về defaults an toàn khi fetch lỗi hoặc offline. | - Ảnh UI Before / After:<br/>  `evidence/failure-cases/S5-10-THANG-20261106/`<br/>- File [`firebase/remote-config-defaults.json`](../firebase/remote-config-defaults.json) |
| **12** | **ARTEMIS Automated E2E Testing** | - 11 test cases E2E tự động bằng Google ARTEMIS Agent.<br/>- Bao phủ Happy Path, Error Recovery, Native Interaction, Exploratory Session.<br/>- Quantitative assertions dựa trên cấu trúc giao diện thật thay vì chỉ kiểm tra status code.<br/>- **Kết quả:** Bảng tỷ lệ đạt (pass rate), trace ID, replay run log, giải thích cơ chế xử lý flaky test. | - File runs log: `evidence/artemis/raw/runs.jsonl`<br/>- Bảng kết quả batch pass: `evidence/artemis/README.md`<br/>- Link [`docs/test-plan.md`](test-plan.md) |
| **13** | **AI-Assisted Code Review** | - Quy trình review bằng AI trên Pull Request (CodeRabbit & Codex).<br/>- Thống kê findings: Security, Bug, Performance, Maintainability.<br/>- Bảng minh họa các findings tiêu biểu: Vị trí `file:line`, phân loại, quyết định kỹ thuật (Accepted / Modified / Rejected) và commit sửa lỗi thực tế. | - Bảng minh họa findings & fixes<br/>- Link [`docs/code-review.md`](code-review.md)<br/>- Hồ sơ review: `evidence/review/` |
| **14** | **Challenges & Lessons Learned** | - Các thách thức thực tế gặp phải: Xử lý SessionEpoch khi đổi user, hạn chế hạn mức Google AI/Gemini free tier, giải quyết flaky do độ trễ mạng trong ARTEMIS, đồng bộ mono-repo.<br/>- Bài học kinh nghiệm: Quy tắc phòng thủ Null-safety, phân tầng độc lập Interface - Implementation, tầm quan trọng của việc ghim version môi trường. | - Minh chứng lỗi & giải pháp thực tế<br/>- Dẫn chứng từ worklogs các thành viên |
| **15** | **Summary & AI Disclosure** | - Tổng kết kết quả bàn giao Lab 3 đạt 100% tiêu chí Handout.<br/>- **Bảng công bố công cụ AI (AI Disclosure):** Công cụ sử dụng (OpenAI Codex, CodeRabbit, Google ARTEMIS + Gemini), mục đích, phạm vi và nguyên tắc kiểm soát của con người.<br/>- Liên kết mở: Demo Video, GitHub Repository, Tài liệu `docs/`. | - Link [`README.md`](../README.md) (Section 7)<br/>- Danh sách thành viên và phân công |

---

## 5. Lưu Ý Riêng Cho Từng Slide Firebase (Slide 6 – 11)

Theo quy định bắt buộc của Handout Mục 6, 7 & 9, mỗi dịch vụ Firebase phải được trình bày trên **một slide độc lập**, đảm bảo đủ 4 yếu tố:
1. **Hành vi tối thiểu (Minimum Behaviour):** Nêu rõ tính năng cốt lõi đã hoàn thành theo yêu cầu.
2. **Xử lý tình huống lỗi (Failure Case Handling):** Phải làm rõ app phản ứng thế nào khi mất mạng, bị từ chối quyền, user bấm hủy hoặc backend trả lỗi — **phải có thông báo rõ ràng cho người dùng, tuyệt đối không văng lỗi/crash**.
3. **Minh chứng thực tế (Evidence):** Phải nhúng ảnh chụp màn hình thực tế (App UI, Firebase Console, DebugView hoặc Crashlytics Dashboard).
4. **Tính nhất quán của Project ID:** Ảnh chụp từ Firebase Console bắt buộc phải nhìn thấy rõ **Firebase Project ID** khớp hoàn toàn với cấu hình dự án (`longvita-8da7e`).

---

## 6. Checklist Kiểm Tra Trước Khi Xuất Bản Slide (PDF)

Trước khi chuyển giao hoặc nộp file `slides/Lab03_<StudentID>_slides.pdf`, người phụ trách phải đối chiếu danh sách kiểm tra sau:

- [ ] Đủ số lượng trang: đúng **12–15 slide**, định dạng **PDF**.
- [ ] Có đầy đủ **Topic, Persona, Success Criterion** của Lab 2 tại các slide đầu.
- [ ] Có ảnh đối chiếu **Figma vs App side-by-side** và ghi rõ lý do các thay đổi giao diện.
- [ ] Có sơ đồ kiến trúc phân tầng **MVVM Layer Diagram** rõ ràng.
- [ ] Có phần giải thích Design System trong code: **Tokens $\to$ `ThemeData`** và **Components $\to$ Reusable Widgets**.
- [ ] Đủ **6 slide riêng biệt cho 6 dịch vụ Firebase** (Auth, Storage, FCM, Analytics, Crashlytics, Remote Config), mỗi slide đều có cơ chế xử lý lỗi (Failure Case).
- [ ] Có ảnh chụp **Firebase Analytics DebugView** kèm bảng sự kiện và parameters.
- [ ] Có ảnh chụp **Firebase Crashlytics Dashboard** và ảnh đối chứng **Remote Config Before/After**.
- [ ] Có báo cáo kết quả kiểm thử **ARTEMIS E2E**, bảng tỷ lệ pass rate và giải thích flaky.
- [ ] Có trích dẫn các **Code Review findings** tiêu biểu kèm link fix commit cụ thể.
- [ ] Có phần đúc kết **Challenges & Lessons Learned** từ kinh nghiệm thực tế.
- [ ] Có bảng **Khai báo công cụ AI (AI Disclosure)** minh bạch phạm vi sử dụng.
- [ ] Mọi tuyên bố "đã chạy được" đều có ảnh chụp hoặc link dẫn chứng xác thực.
- [ ] Dẫn liên kết tới các file tài liệu trong thư mục `docs/` thay vì sao chép văn bản dài.
- [ ] Không nhồi nhét chữ; tuân thủ nguyên tắc **mỗi slide một thông điệp chính**.

---

> [!TIP]
> **Phương án co gọn 12 slide (nếu cần):**
> Trong trường hợp cần tối giản về 12 slide, nhóm có thể:
> - Gộp Slide 1 & Slide 2 thành: *“Title, Topic & Persona Recap”*.
> - Gộp Slide 14 & Slide 15 thành: *“Lessons Learned, AI Disclosure & Summary”*.
> - **Tuyệt đối không gộp 6 slide Firebase (Slide 6 – 11)** vì đây là tiêu chí chấm điểm độc lập của từng dịch vụ Cloud trong rubric.
