# TV-00 — Firebase Hosting production verification (10/11/2026)

## Kết quả

- Project: `longvita-8da7e`.
- URL production: https://longvita-8da7e.web.app
- Source được deploy: `main` tại commit `0cfe905`.
- Build: `flutter build web --release` trong `web/` — pass; Wasm dry run pass.
- Deploy: `firebase deploy --only hosting --project longvita-8da7e --non-interactive`
  — release complete, 44 files.
- HTTP production: `200`, title `Longvita Web Admin`.
- Trình duyệt ẩn danh: Cốc Cốc, viewport 1920×1080 — trang đăng nhập tải được
  khi không có phiên đăng nhập cũ.
- Role `admin`: Google sign-in thành công, Dashboard đọc dữ liệu Cloud Firestore.
- Role `user`: Google sign-in thành công nhưng bị chặn bằng màn hình
  “Tài khoản không có quyền”.

## Phạm vi deploy

Lượt này chỉ deploy Firebase Hosting. Không deploy Firestore Rules và không ghi
dữ liệu production trong lệnh deploy.

## Bằng chứng ảnh do người kiểm thử cung cấp

Ảnh runtime đã được kiểm tra trong phiên làm việc ngày 10/11/2026:

1. Cửa sổ ẩn danh mở URL production và hiển thị trang đăng nhập.
2. Google account chooser xuất hiện sau khi bấm đăng nhập.
3. Role `admin` vào được Dashboard.
4. Role `user` bị chặn đúng thông báo.

Trước khi đưa ảnh vào repository/public report phải che email không dùng làm
tài khoản demo, UID, token và danh sách Google account cá nhân. File README này
ghi metadata và kết quả; ảnh gốc hiện chưa commit để tránh lộ dữ liệu cá nhân.

## Acceptance TV-00

- [x] Flutter Web build release thành công.
- [x] Firebase Hosting URL hoạt động.
- [x] URL mở được trong cửa sổ ẩn danh.
- [x] Google OAuth production mở account chooser.
- [x] Admin vào được Web Admin.
- [x] User thường bị chặn.
- [ ] Ảnh đã làm sạch PII được commit vào evidence/report cuối.
