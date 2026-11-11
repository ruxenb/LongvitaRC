# Bằng chứng Android thật — không có PII

Ngày 11/11/2026, Samsung Galaxy A15 SM-A155F, Android 16.

- profile-vietnamese-no-pii.png: ảnh thật sau clean build và cài APK. Đã **cắt hoàn toàn vùng tên, email và ảnh đại diện**. Thể hiện tiêu đề Tiện ích Firebase, PDF ở trạng thái chưa có thực đơn và hòm thư rỗng.
- Flutter Analyze 0 vấn đề, Flutter Test 483/483 đạt, APK build và adb install -r thành công; log gốc chỉ lưu trên máy tính cá nhân.
- Chỉ chứng minh hiển thị; không chứng minh PDF đã xuất, inbox realtime, recipe đã kiểm duyệt hoặc luồng liên vai trò.

Không đưa ảnh gốc chứa thông tin tài khoản và secret lên Git.


## Bằng chứng Native QA mới (11/11/2026)

Ảnh đã cắt vùng chứa danh tính và lưu trong thư mục này:
- s02-options-no-pii.png: màn S02 thực
- s03-setup-no-pii.png: màn S03 thực
- s04-generated-preview-before-polish.png: thực đơn tạo từ dữ liệu hệ thống, **ảnh trước sửa bố cục**
- s06-empty-and-retry.png: trạng thái không có món thay thế
- s06-recovery-to-s02-no-pii.png: nhánh trở lại tùy chọn
- firestore-save-confirmation.png: phản hồi đã lưu kế hoạch lên Firestore từ client
- inbox-web-admin-notification-no-pii.png: thông báo cũ từ Web, chưa đo thông báo realtime mới

Raw ảnh chứa thông tin cá nhân không đẩy GitHub. Lượt sửa S04/S05 gần nhất chưa có ảnh native mới vì ADB mất kết nối, dù 487/487 Flutter tests đã đạt.
