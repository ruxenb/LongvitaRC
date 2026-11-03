# S8-1 — Bản nháp phần báo cáo của Thắng

> Trạng thái: bản nháp dựa trên code và evidence có thật ngày 03/11/2026. Không
> dùng nội dung này để khẳng định các flow S02–S10 hoặc cloud checks chưa chạy.

## 1. Tổng quan và kế thừa Lab 2

Longvita chuyển thiết kế Lab 2 về dinh dưỡng trường thọ thành ứng dụng Flutter
Android có hỗ trợ Firebase. Đầu vào được truy vết từ persona, ba user flow,
screen specification, Flutter handoff và Figma Page 01–06. Ma trận
`docs/design-traceability.md` ánh xạ 10 màn S01–S10, các trạng thái phục hồi và
hai màn bổ sung cho Lab 3 là Sign-in và Profile.

Tiêu chí thành công của sản phẩm là giúp người dùng tạo thực đơn bảy ngày, xem
công thức/thay thế món, tổng hợp danh sách mua sắm và quay lại kế hoạch đã lưu.
Tại thời điểm viết, repository mới chứng minh đầy đủ cụm Auth, Home và Profile;
không suy diễn rằng toàn bộ ba flow Lab 2 đã chạy.

## 2. Kiến trúc MVVM

Ứng dụng dùng Provider để dependency injection và tách bốn lớp: View,
ViewModel, Model, Service/Firebase wrapper. Widget không gọi trực tiếp Firebase
SDK. ViewModel nhận service qua constructor, quản lý trạng thái rõ ràng và phát
thay đổi bằng `notifyListeners`. Cách tách `ReportService` khỏi `StorageService`
cho phép sinh PDF cục bộ ngay cả khi upload cloud thất bại.

`AuthGate` chọn Sign-in hoặc Home từ auth state. Việc sign-out loại protected
route khỏi navigation stack; session epoch ngăn callback hoặc snackbar của user
cũ xuất hiện ở phiên mới. Các hành vi này đã được bao phủ trong bộ 270 Flutter
tests trên nhánh `Thang`.

## 3. Design system và accessibility

Theme và reusable widgets dùng token màu, typography, spacing và radius kế
thừa Lab 2. Các component chính gồm button, text field, card, navigation, app
bar, dialog và loading/empty/error states. Touch target và Semantics được kiểm
tra bằng widget tests; bằng chứng TalkBack nằm trong `evidence/a11y/`.

Các sai lệch có chủ đích được ghi tại Design Deviation Log, ví dụ bổ sung Auth
và Profile cho yêu cầu Firebase, tăng kích thước CTA để hỗ trợ người lớn tuổi,
và dùng Material dialog cho chỉnh số lượng nguyên liệu.

## 4. Review và bài học

Review PR #6 bằng Codex Bugbot và Security Review phát hiện năm vấn đề thuộc
privacy, process, correctness và traceability. Nhóm loại ảnh chứa PII, thay raw
traceback bằng bản khử định danh, bắt buộc che thông tin thật trong video, sửa
số chiến dịch FCM và đồng bộ ngày tracker. Bài học chính là evidence cũng phải
được review như source code: log hoặc ảnh chạy đúng vẫn có thể không phù hợp để
đưa vào repository công khai.

## 5. Phần cần bổ sung trước khi nghiệm thu

- Kết quả hoàn chỉnh S02–S10 và ba user flow.
- Google Sign-In sau khi đăng ký SHA-1/SHA-256 của máy Thắng.
- Failure test cloud còn thiếu, ARTEMIS raw runs và Remote Config live.
- Liên kết report/slide/video cuối và tối thiểu ba fix commits Stage 7.
