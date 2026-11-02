# S3-9 — Bằng chứng Auth, 02/11/2026

Project `longvita-8da7e`, app `vn.edu.fpt.longvita`, AVD `LocalMate_API_35` (hiển thị 320×640), bản debug. Tài khoản Google thật của Charlie do Charlie tự nhập.

| File | Nội dung |
|---|---|
| `signed-out.png` | Màn Sign-in sau khi đăng xuất |
| `signed-in.png` | Màn chính sau khi đăng nhập, `ROLE: USER` |
| `cancelled.png` | Quay về Sign-in sau khi hủy chọn tài khoản, có thông báo hủy |
| `console-auth-users.jpg` | Tab Users, 1 user provider Google |
| `console-firestore-user-doc.jpg` | `users/{uid}` với `role: "user"` |
| `console-project-settings.jpg` | Project ID `longvita-8da7e`, khớp `project_id` trong `android/app/google-services.json` |

## Tái lập

1. Thêm SHA-1 debug của máy vào app Android trên Console, tải lại `google-services.json`.
2. Chạy `flutter run` trên thiết bị có Google Play.
3. Bấm "Đăng nhập bằng Google", bấm Back để hủy: về Sign-in, có thông báo.
4. Đăng nhập lại: vào màn chính, kiểm tra tab Users và `users/{uid}` trên Console.
5. Tắt hẳn rồi mở lại app: vẫn ở màn chính.
6. Bấm "Đăng xuất": về Sign-in.

## Giới hạn

- Các ảnh có email và UID thật của Charlie.
- Độ phân giải thấp, chưa theo viewport 1080×2400.
- Chưa test lỗi mạng hoặc SHA sai trên thiết bị thật.
