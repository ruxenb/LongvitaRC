# S8-1 — Phần báo cáo của Thắng

> **Trạng thái:** hoàn thành nội dung cá nhân ngày 07/11/2026, đối chiếu với
> `main` tại `c4e8024`. Phần này chỉ sử dụng claim có evidence; việc ghép vào PDF
> cuối thuộc S8-5.

## 1. Tổng quan và kế thừa Lab 2

Longvita chuyển thiết kế Lab 2 về dinh dưỡng trường thọ thành ứng dụng Flutter
Android tích hợp Firebase. Đầu vào được truy vết từ persona, ba user flow,
screen specification, Flutter handoff và Figma Page 01–06. Ma trận
`docs/design-traceability.md` ánh xạ 10 màn S01–S10, các trạng thái phục hồi và
hai màn bổ sung cho Lab 3 là Sign-in và Profile.

Tiêu chí thành công của sản phẩm là giúp người dùng tạo thực đơn bảy ngày, xem
công thức/thay thế món, tổng hợp danh sách mua sắm và quay lại kế hoạch đã lưu.
Repository hiện có ba nhóm flow: lập/lưu thực đơn bảy ngày, tổng hợp danh sách
mua sắm và tra cứu/đổi món. Smoke test native của Thắng xác nhận từ Dashboard có
thể mở S02, S10, Recipe và Profile; phím Back quay về đúng Dashboard, còn Back ở
Sign-in đưa ứng dụng về launcher. Evidence này xác nhận routing và navigation;
không được dùng thay cho bộ ARTEMIS chính thức ba lượt mỗi test.

## 2. Kiến trúc MVVM

Ứng dụng dùng Provider để dependency injection và tách bốn lớp: View,
ViewModel, Model, Service/Firebase wrapper. Widget không gọi trực tiếp Firebase
SDK. ViewModel nhận service qua constructor, quản lý trạng thái rõ ràng và phát
thay đổi bằng `notifyListeners`. Cách tách `ReportService` khỏi `StorageService`
cho phép sinh PDF cục bộ ngay cả khi upload cloud thất bại.

`AuthGate` chọn Sign-in hoặc Home từ auth state. Khi phiên thay đổi, protected
route bị loại khỏi navigation stack. Session epoch và hàng đợi theo UID ngăn
callback, dữ liệu PDF hoặc snackbar của user cũ xuất hiện trong phiên mới.
Dependency được đăng ký tập trung bằng Provider, giúp widget/ViewModel tests dùng
fake service mà không cần gọi Firebase thật.

Các mốc tích hợp đã có analyzer sạch và full Flutter suite đạt, gần nhất được
ghi nhận trong repo là **337/337 tests** ngày 06/11. Đây là unit/widget evidence
của baseline được ghi nhận, không phải một lượt QA mới trên `c4e8024`; do đó bản
feature-freeze vẫn phải chạy lại analyzer và toàn bộ suite.

## 3. Design system và accessibility

Theme và reusable widgets dùng token màu, typography, spacing và radius kế thừa
Lab 2. Các component chính gồm button, text field, card, navigation, app bar,
dialog và loading/empty/error states. Touch target, heading và Semantics được
kiểm tra bằng widget tests; evidence TalkBack của các màn Sign-in, Profile và
dialog nằm trong `evidence/a11y/`.

Các sai lệch có chủ đích được ghi tại Design Deviation Log, ví dụ bổ sung Auth
và Profile cho yêu cầu Firebase, tăng kích thước CTA để hỗ trợ người lớn tuổi,
và dùng Material dialog cho chỉnh số lượng nguyên liệu.

## 4. Review và bài học

Review PR #6 bằng Codex Bugbot và Security Review tạo năm findings thật thuộc
privacy/security, process, correctness và traceability. Thắng quyết định
Accept/Modify cho từng finding, loại ảnh chứa PII, thay raw traceback bằng bản
khử định danh, bắt buộc che thông tin thật trong video, sửa số chiến dịch FCM và
đồng bộ ngày tracker. Năm finding PR6-01..05 được sửa trong commit `55bdf3e`,
liên kết trong `docs/code-review.md` và merge vào `main` qua `90d9fd0`.

Bài học quan trọng là evidence phải được review nghiêm túc như source code: ảnh,
log hoặc tài liệu có thể phản ánh đúng kết quả kỹ thuật nhưng vẫn làm lộ PII,
đường dẫn máy cá nhân hoặc đưa ra claim rộng hơn phạm vi đã kiểm chứng. Bài học
thứ hai là phải tách rõ unit/widget, native smoke, Firebase Console và ARTEMIS;
mỗi loại chứng minh một tầng khác nhau và không thể thay thế lẫn nhau.

## 5. Firebase và kiểm thử failure cases

Trên AVD `Longvita_API_36`, project `longvita-8da7e`, Thắng đã kiểm tra thủ công
sáu nhóm dịch vụ: Auth, Storage, FCM, Analytics, Crashlytics và Remote Config.
Remote Config được đổi hai tham số live, ứng dụng fetch/activate không rebuild và
sau đó hoàn nguyên. Analytics nhận các event được tạo khi offline sau khi mạng
trở lại. Crashlytics nhận fatal và non-fatal từ lỗi Auth mất mạng. Storage chỉ
được xác nhận bằng Firebase Storage Emulator vì project Spark chưa có Storage
cloud; báo cáo không tuyên bố production upload đã pass.

## 6. Phạm vi và giới hạn

- Nội dung S8-1 đã hoàn thành để đưa vào report tổng; dàn trang PDF 8–12 trang,
  ảnh minh họa và liên kết deliverable cuối thuộc S8-5.
- ARTEMIS đã có lượt chạy thật trong repo nhưng chưa đạt tiêu chí formal ba lượt
  cho từng test; không công bố pass rate chính thức.
- Chưa có tag feature-freeze `v1.0-rc`; cần chạy QA lại trên đúng commit được tag.
- Google Sign-In mới bằng SHA của máy Thắng đã pass ngày 05/11; các claim của máy
  hoặc tài khoản khác phải dùng evidence riêng.

## 7. Nguồn bằng chứng chính

- Routing native: `evidence/routing/S0-3-S3-6-20261104/`.
- Failure cases đầy đủ của Thắng:
  `evidence/failure-cases/S5-10-THANG-20261106/`.
- Auth/FCM manual cases ngày 05/11:
  `evidence/auth/S3-2-S5-10-THANG-20261105/`.
- Review PR #6: `evidence/review/PR-6-THANG-20261103/`.
- Review tổng hợp và link fix: `docs/code-review.md`.
- Kiểm chứng baseline mới nhất: `docs/hoang-verification-20261106.md`.
- Audit privacy/secret giữa kỳ: `evidence/audit/S9-1-S9-4-20261103/`.
