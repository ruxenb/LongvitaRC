# S9-5-TA — Kịch bản ôn luyện vấn đáp 5 phút của Thái An

> **Thành viên:** Thái An  
> **Vai trò:** Team Leader & QA Lead (Điều phối chất lượng, Firebase Analytics/Crashlytics/Remote Config, Google ARTEMIS E2E, AI Code Review)  
> **Mục tiêu:** Kịch bản phân bổ thời gian chính xác từng phút để trả lời tự tin, mạch lạc khi Giảng viên gọi vấn đáp ngẫu nhiên (Mục 11 Handout).

---

## ⏱️ Phân bổ thời lượng chi tiết (5 Phút)

### Phút 0:00 – 1:00 | Giới thiệu vai trò & Kiến trúc phân tầng dịch vụ Firebase
- **Lời thoại mở đầu:**
  > *"Em chào Thầy/Cô. Trong đồ án Longvita Lab 3, em đảm nhiệm vai trò Team Leader và QA Lead. Trách nhiệm kỹ thuật chính của em là kiến trúc và triển khai 3 dịch vụ Firebase: Analytics, Crashlytics, Remote Config; đồng thời chịu trách nhiệm thiết lập và vận hành hệ thống kiểm thử tự động E2E bằng Google ARTEMIS."*
- **Trình bày kiến trúc:**
  - Mở [`lib/firebase/`](../../lib/firebase/) và [`lib/services/`](../../lib/services/).
  - Nhấn mạnh nguyên tắc MVVM cốt lõi: *"Toàn bộ các dịch vụ Firebase đều được em đóng gói sau các Service Interface riêng biệt (`AnalyticsService`, `CrashlyticsService`, `RemoteConfigService`). Các Widget trên tầng UI tuyệt đối không bao giờ gọi trực tiếp SDK Firebase (`FirebaseAnalytics.instance` hay `FirebaseCrashlytics.instance`), giúp ứng dụng độc lập hoàn toàn, dễ dàng test bằng Mock/Fake và không rò rỉ ngoại lệ lên giao diện."*

---

### Phút 1:00 – 2:00 | Trình diễn trực tiếp Remote Config Live (Không cần Rebuild)
- **Thao tác trực tiếp trước mắt giảng viên:**
  1. Mở màn hình ứng dụng trên thiết bị (hoặc emulator), điều hướng vào màn hình **Hồ sơ (Profile)** $\to$ trỏ vào mục **Firebase Demo Area**.
  2. Chỉ cho Thầy/Cô thấy dòng: *"Số món gợi ý tối đa: 5 món"*.
  3. Mở tab trình duyệt chứa **Firebase Console** (Project `longvita-8da7e`) $\to$ mục **Remote Config**.
  4. Sửa tham số `max_meal_recommendations` từ **5** thành **10** $\to$ Bấm **Publish changes**.
  5. Quay lại màn hình điện thoại, bấm nút **"Cập nhật Remote Config"** (hoặc vuốt làm mới) $\to$ Nhãn giao diện đổi ngay lập tức thành **10 món**.
- **Lời giải thích then chốt:**
  > *"Như Thầy/Cô thấy, giá trị mới đã được nạp và áp dụng ngay lập tức vào ViewState của ProfileViewModel mà hoàn toàn không cần biên dịch lại mã nguồn hay cài lại APK. Đồng thời, nếu thiết bị mất mạng, dịch vụ sẽ tự động fallback về `remote-config-defaults.json` đã được em đóng gói sẵn trong app để đảm bảo không bao giờ bị crash."*

---

### Phút 2:00 – 3:00 | Giải thích quyết định AI Code Review (Appendix C)
- **Mở tài liệu:** [`docs/code-review.md`](../code-review.md) trên repo GitHub.
- **Trình bày một quyết định cụ thể:**
  - Lấy ví dụ finding **PR7-CR-08** (hoặc **PR6-01**):
  > *"Khi sử dụng công cụ CodeRabbit để review Pull Request, AI đã phát hiện một lỗ hổng trong bộ kiểm thử E2E: Output của các bước trước bị gộp chung vào màn hình sau, dẫn đến việc assertion kiểm tra màn hình xem PDF bị 'pass giả' (false-pass) do bắt nhầm từ khóa Longvita có sẵn từ trước.*
  > *Với tư cách là QA Lead, em đã **Chấp nhận (Accepted)** phát hiện này và thực hiện commit sửa `59b77a3` để phân tách chuỗi quan sát độc lập theo từng hành động.*
  > *Nguyên tắc cốt lõi của nhóm em là: AI chỉ là công cụ hỗ trợ phát hiện; con người phải trực tiếp đối chiếu code, ra quyết định kỹ thuật và chịu trách nhiệm hoàn toàn."*

---

### Phút 3:00 – 4:00 | Trình diễn kiểm thử tự động Google ARTEMIS E2E
- **Thao tác terminal:**
  ```powershell
  cd e2e_test
  .\.venv\Scripts\pytest -v test_auth.py::test_tc01b_cancelled_sign_in_stays_on_sign_in
  ```
- **Thuyết minh luồng chạy:**
  > *"Đây là kịch bản TC-01b kiểm tra việc người dùng mở Google Account Picker nhưng bấm nút Back để hủy. Thầy/Cô có thể thấy mô hình Gemini Multimodal Vision của Google ARTEMIS đọc kịch bản ngôn ngữ tự nhiên từ file test, chụp màn hình thiết bị qua ADB, nhận diện nút 'Đăng nhập bằng Google', tự động bấm nút, nhận diện hộp thoại native của Android và bấm Back để hủy.*
  > *Toàn bộ 11 test cases của nhóm em đều được chạy lặp lại $\ge 3$ lần/test trên profile `flash`, đạt tỷ lệ Pass Rate 100% và lưu vết minh bạch tại file `runs.jsonl`."*

---

### Phút 4:00 – 5:00 | Sẵn sàng trả lời câu hỏi chuyên sâu (Q&A Readiness)
Chuẩn bị sẵn câu trả lời súc tích cho 3 câu hỏi giảng viên hay hỏi nhất:
1. **"Làm sao em chứng minh Analytics không vi phạm chính sách quyền riêng tư (No PII)?"**
   - *Trả lời:* *"Dạ thưa Thầy/Cô, trong `docs/analytics-plan.md` và mã nguồn `AnalyticsService`, toàn bộ 8 sự kiện chỉ chứa các trường định lượng như `recipe_id`, `result_count`, `file_size_bytes`. Nhóm tuyệt đối không đính kèm email, tên thật hay plain UID vào parameters. Khi người dùng đăng xuất, app gọi `resetAnalyticsData()` để xóa session."*
2. **"Trong Crashlytics, em gắn Custom Keys và User ID như thế nào?"**
   - *Trả lời:* *"Dạ, khi người dùng đăng nhập thành công, em gọi `setCustomKey('error_category', ...)` và `setUserId(uid)`. Khi phát sinh ngoại lệ được xử lý trong khối catch, hàm `recordHandledError()` sẽ đính kèm ngữ cảnh màn hình (`last_screen`) và đẩy lên Crashlytics Dashboard giúp đội ngũ phát triển tái hiện lỗi chính xác mà app không bị sập."*
3. **"Nếu Firebase Console bị lỗi kết nối hoặc quota Spark plan bị cạn thì app xử lý ra sao?"**
   - *Trả lời:* *"Dạ, toàn bộ các hàm gọi Firebase đều được bọc trong khối `try/catch` có xử lý lỗi mạng (`SocketException`, `FirebaseException`). Khi mất mạng, app hiển thị thông báo lỗi thân thiện (như SnackBar hoặc ErrorStateView có nút Thử lại) chứ không bao giờ để xảy ra crash đột ngột."*

---

## 📋 Checklist tự rà soát trước khi lên vấn đáp
- [x] Đã thuộc lòng vị trí file `AnalyticsService`, `CrashlyticsService`, `RemoteConfigService`.
- [x] Thiết bị Android đã bật sẵn và chạy app Longvita mượt mà.
- [x] Đã đăng nhập sẵn Firebase Console project `longvita-8da7e` trên trình duyệt.
- [x] Môi trường `e2e_test/.venv` chạy được lệnh `pytest` không báo lỗi thư viện.
- [x] Nắm chắc lý do kỹ thuật của ít nhất 1 finding trong `docs/code-review.md`.

