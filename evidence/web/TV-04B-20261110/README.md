# TV-04B Web Admin evidence index — 10/11/2026

Thư mục này là nơi nhận ảnh Web thật theo `docs/web-admin-checklist.md`.

## Đã xác minh trong lượt chuẩn bị

- Checklist WEB-01..18 đã được định nghĩa, gồm role gate, bốn states, hành động
  chính, responsive, Remote Config, Analytics, Announcement và Hosting.
- Sau sửa review PR #25: 21/21 test trong `test/admin/admin_web_test.dart` và
  `test/admin/pr25_integration_test.dart` pass.
- `e2e_test/conftest.py` và `e2e_test/test_auth.py` compile sạch sau khi loại
  marker `Longvita` dùng chung giữa Sign-in và Home.

## Chưa có trong thư mục này

- Chưa chụp ảnh production/live.
- Chưa có Hosting URL hoặc incognito proof.
- Chưa có DebugView thật, Remote Config toggle thật hoặc Announcement Form của
  CM-07.
- Chưa ghi production Firestore.

Mỗi ảnh bổ sung phải ghi commit SHA, môi trường, role, viewport và bước tái
hiện; không lưu email, UID hoặc token.
