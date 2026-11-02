# Nháp báo cáo S8-3 — Firebase Authentication

> Bản nháp của Charlie gửi Thắng ghép ở S8-5. Mới có phần Auth. Storage và FCM viết sau khi có bằng chứng thật (S4-15).

## 1. Vai trò trong ứng dụng

Longvita dùng Firebase Authentication với nhà cung cấp Google. Mỗi người dùng có một `uid`, dùng làm khóa cho hồ sơ `users/{uid}` và cho Firestore Security Rules. Project là `longvita-8da7e`, ứng dụng Android là `vn.edu.fpt.longvita`.

## 2. Luồng tích hợp

1. `FirebaseBootstrap` khởi tạo Firebase từ `google-services.json`. Nếu lỗi, app hiện màn lỗi có nút thử lại thay vì chạy tiếp.
2. Người dùng bấm "Đăng nhập bằng Google". `AuthService` mở cửa sổ chọn tài khoản, đổi token Google thành credential Firebase và đăng nhập.
3. `AuthViewModel` lấy luồng `authStateChanges` làm nguồn sự thật về trạng thái đăng nhập, rồi tải `users/{uid}`.
4. Lần đăng nhập đầu, app tạo hồ sơ với `role: 'user'`. Rules chỉ cho chủ tài khoản tạo hồ sơ với role này, nên người dùng không tự cấp quyền cho mình được.
5. `AuthGate` chọn màn theo trạng thái. Chỉ khi hồ sơ đã tải xong app mới vào màn chính.
6. Khi đăng xuất, app xóa dữ liệu phiên trong các ViewModel, gỡ user ID khỏi Analytics và Crashlytics, xóa các màn đã mở khỏi stack rồi về Sign-in.

Giao diện không gọi Firebase SDK trực tiếp: `SignInScreen` chỉ gọi `AuthViewModel`, còn `AuthViewModel` gọi `IAuthService`.

## 3. Xử lý lỗi

| Tình huống | Hành vi | Trạng thái kiểm chứng |
|---|---|---|
| Hủy chọn tài khoản | Về Sign-in, có thông báo thông tin, không dùng màu lỗi | Emulator và test |
| Mất mạng khi đăng nhập | Báo mất mạng, nút "Thử lại với Google" | Test bằng fake |
| Sai cấu hình SHA hoặc OAuth | Báo thiết bị chưa được cấu hình | Test bộ ánh xạ lỗi |
| Google không xác nhận được tài khoản | Báo chọn tài khoản khác hoặc thử lại | Test bộ ánh xạ lỗi |
| Đăng nhập được nhưng đọc hoặc tạo hồ sơ lỗi | Màn khôi phục có Thử lại và Đăng xuất, không báo nhầm là hủy đăng nhập | Test bằng fake |
| Firebase không khởi tạo được | Màn lỗi khởi động có Thử lại | Test bằng fake |
| Kết quả về muộn sau khi đã đổi tài khoản | Bị bỏ qua nhờ `SessionEpoch`, không lọt sang phiên sau | Test bằng fake |
| Lệnh đăng xuất của SDK lỗi | Vẫn xóa dữ liệu trên máy và về Sign-in, lỗi được ghi vào Crashlytics | Test bằng fake |

## 4. Bảo vệ dữ liệu

`firebase/firestore.rules` mặc định từ chối mọi truy cập. Người dùng chỉ đọc được hồ sơ của mình, trừ staff và admin, và không tự đổi được role. Bộ test rules chạy trên emulator đạt 41/41. Rules cũ trượt 16 ca với cùng bộ test.

## 5. Kiểm thử

- **Chạy thật trên emulator** với tài khoản Google thật: đăng nhập, hủy, mở lại app vẫn giữ phiên, đăng xuất, đăng nhập lại.
- **Kiểm tra tự động:** `test/auth/` phủ view model, màn hình, ánh xạ lỗi, bootstrap, cô lập dữ liệu giữa các phiên và lỗi đổi phiên giữa chừng.
- **Rules:** `npm run test:rules` trong `firebase/`.

## 6. Bằng chứng

Thư mục `evidence/auth/S3-9-20261102/`:

- `signed-out.png`, `signed-in.png`, `cancelled.png`: các trạng thái trên app.
- `console-auth-users.jpg`: tab Users trên Console.
- `console-firestore-user-doc.jpg`: `users/{uid}` với `role: "user"`.
- `console-project-settings.jpg`: Project ID khớp `google-services.json`.

Kết quả rules ở `evidence/rules/AUD-11-20261102/`.

## 7. Giới hạn

- Mới có SHA của máy Charlie. Ba máy còn lại chưa đăng nhập được cho đến khi thêm SHA (S3-2).
- Chưa chạy trên máy thật. Lỗi mạng và lỗi SHA chưa tái hiện trên thiết bị, mới test bằng fake.
- Chưa thử đổi tài khoản A/B bằng hai tài khoản trên thiết bị.
- Rules đã publish lên project. Thắng và Hoàng chưa chốt các chính sách B1–B5 của AUD-11, nên rules có thể còn đổi.
- Các ảnh hiện tại có độ phân giải thấp và chứa email, UID thật. Nên chụp lại nếu báo cáo cần ảnh rõ hơn hoặc che thông tin.
