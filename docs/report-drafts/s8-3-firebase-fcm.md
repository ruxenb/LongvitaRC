# Nháp báo cáo S8-3 — Firebase Cloud Messaging

> Bản nháp của Charlie, gửi Thắng ghép ở S8-5. Viết từ bằng chứng push thật ngày 02/11 và 03/11/2026 (S4-15, S4-12). Nhóm đã đồng ý dùng contract tạm cho đích và lịch sử thông báo; khi có contract chính thức thì phần 2 và 7 cần sửa theo.

## 1. Vai trò trong ứng dụng

Longvita dùng FCM để gửi thông báo tới người dùng, ví dụ nhắc thực đơn hoặc thông báo chung. Tin được gửi từ Firebase Console của project `longvita-8da7e` tới ứng dụng Android `vn.edu.fpt.longvita`. Gói Spark miễn phí đã đủ dùng FCM.

## 2. Luồng tích hợp

1. Sau khi người dùng đăng nhập, `ProfileViewModel` gọi `NotificationService.initialize()`. App chỉ xin quyền thông báo ở bước này, không xin ngay khi mở app, nên người dùng mới vào thẳng màn Sign-in.
2. `NotificationService` gắn ba nguồn tin của SDK:
   - `onMessage`: app đang mở.
   - `onMessageOpenedApp`: người dùng bấm tin khi app chạy nền.
   - `getInitialMessage()`: người dùng bấm tin khi app đã tắt.
3. Tin đến lúc app chạy nền hoặc đã tắt được handler nền (`onBackgroundMessage`, hàm top-level) ghi vào file chờ trên máy. App chuyển các tin đó vào hộp thư khi đăng nhập, khi mở Profile và khi quay lại foreground.
4. `NotificationInbox` giữ quy tắc hộp thư, không phụ thuộc Firebase nên test được:
   - Một tin đến qua nhiều nguồn chỉ có một mục và chỉ điều hướng một lần.
   - Tin có `recipient_uid` của người khác không vào hộp thư.
   - Tin đến khi chưa ai đăng nhập được giữ lại cho lần đăng nhập kế tiếp.
5. Lịch sử lưu trên máy theo UID (`notifications/{uid}.json`), nên tắt rồi mở lại app vẫn còn. Khi đăng xuất, hộp thư trong app được xóa, và người dùng sau chỉ tải lịch sử của chính họ.
6. Khi người dùng bấm tin, `AuthGate` chờ đến khi đã đăng nhập rồi mở Profile, nơi có hộp thư (contract tạm).
7. Khi app đang mở, Android không đưa tin lên khay hệ thống. Vì vậy app hiện một thanh thông báo trên màn đang xem, kèm nút "Xem" để mở hộp thư.

Giao diện không gọi Firebase SDK trực tiếp. SDK nằm sau `FcmGateway`, nên test thay được bằng gateway giả.

## 3. Xử lý lỗi

| Tình huống | Hành vi | Trạng thái kiểm chứng |
|---|---|---|
| Người dùng từ chối quyền | Profile ghi rõ chưa cấp quyền; vẫn nhận được tin khi bấm từ khay | Test bằng fake |
| Xin quyền hoặc khởi tạo lỗi | Ghi trạng thái lỗi, app không dừng | Test bằng fake |
| Một tin đến từ cả foreground và lúc bấm | Một mục trong hộp thư, mở một lần | Test bằng fake |
| Tin của người dùng khác | Không vào hộp thư | Test bằng fake |
| Đổi tài khoản trên cùng máy | Người sau không thấy tin của người trước | Test bằng fake |
| Tin có đích sai phiên bản, sai loại hoặc thiếu ID | Vẫn vào hộp thư, không điều hướng tới đích lỗi | Test bằng fake |
| Không đọc được file lịch sử | Hộp thư vẫn chạy trong bộ nhớ | Test bằng fake |

## 4. Kiểm thử

- **Chạy thật trên emulator** với tin gửi từ Firebase Console: nhận tin ở foreground, background và terminated; bấm tin mở Profile; lịch sử còn sau khi khởi động lại; tin đến khi đang ở Home hiện thanh thông báo, bấm "Xem" mở hộp thư.
- **Kiểm tra tự động:** `test/fcm/` phủ phân tích payload, chống trùng, hộp thư theo user, lịch sử và tin chờ từ nền. `test/profile/` phủ việc bấm tin mở Profile và thanh thông báo khi app đang mở.

## 5. Bằng chứng

Thư mục `evidence/fcm/S4-15-push-20261102/`:

- `00-console-campaigns.jpg`: các chiến dịch trên Console, trạng thái Completed.
- `01-foreground-in-inbox.png`: app đang mở, tin vào hộp thư.
- `02` đến `05`: tin trên khay hệ thống khi app chạy nền và đã tắt, bấm thì mở app.
- `06-history-after-restart.png`: lịch sử còn sau khi khởi động lại.
- `07`, `08`: bấm tin mở thẳng Profile.

Thư mục `evidence/fcm/S4-12-foreground-20261103/`:

- `01`, `02`: tin đến khi đang ở Home, hiện "Thông báo mới: …" kèm nút "Xem".
- `03`: bấm "Xem" mở Profile.
- `04`: hộp thư có cả tin mới lẫn tin của ngày trước.

Tin đến sau khoảng 45 giây đến 2,5 phút kể từ khi phát hành chiến dịch.

## 6. Giới hạn

- Contract đích và lịch sử là bản tạm nhóm đã đồng ý: mọi tin đều mở Profile, lịch sử chỉ lưu trên máy.
- Chưa lưu token theo user, nên chưa gửi tin cho một người cụ thể; tin gửi theo chiến dịch tới cả app.
- Tin gửi từ Console không có `target_type`. Tin có đích và đích lỗi mới test bằng fake.
- "Terminated" là `am kill` sau khi về Home. Android chặn FCM với app bị force-stop.
- Mới chạy trên emulator Android 15, chưa thử máy thật.
