# Kịch bản clip S8-12 — Sign-in, push, export

> Clip của Charlie, gửi Thắng ghép ở S8-15. Mỗi cảnh là thao tác thật trên app debug (AVD Android 15) cùng màn hình Firebase Console tương ứng. Thời gian chờ tin FCM (1 đến 2,5 phút) được cắt khi dựng. Tổng mục tiêu khoảng 3 phút cho phần của Charlie; Thắng chốt lại theo tổng thời lượng của nhóm.

## Cách quay

- **Màn hình thiết bị:** `adb shell screenrecord --time-limit 180 /sdcard/<cảnh>.mp4`, mỗi cảnh một file (giới hạn 3 phút một file), rồi `adb pull`. Claude chạy phần này.
- **Màn hình Console:** quay bằng công cụ quay màn hình trên máy của Charlie, hoặc dùng ảnh chụp Console đã có trong `evidence/` nếu không quay được.
- **Lời nói và dữ liệu cá nhân:** Charlie đọc khi dựng, theo phần "Nói" của từng cảnh. Không đọc hoặc để lộ email, UID, tên đầy đủ hay định danh tài khoản. Bắt buộc che/cắt các dữ liệu này trước khi đưa ảnh, slide hoặc video vào repo và bản nộp; với cảnh Authentication → Users, ưu tiên quay vùng giao diện không chứa định danh.

## Cảnh

| # | Cảnh | Thao tác | Console | Nói | Dài |
|---|---|---|---|---|---|
| 1 | Đăng nhập Google | Mở app ở Sign-in → "Đăng nhập bằng Google" → chọn tài khoản → Home → mở Hồ sơ | Authentication → Users: tài khoản vừa đăng nhập | App dùng Google Sign-In qua Firebase Auth. Lần đầu đăng nhập, app tạo hồ sơ `users/{uid}` với role user; rules không cho người dùng tự đổi role. Hủy chọn tài khoản chỉ là thông báo, không phải lỗi. | 30 giây |
| 2 | Push khi app đang mở | Đang ở Home; tin đến → thanh "Thông báo mới" → bấm "Xem" → hộp thư trên Hồ sơ | Messaging → tạo chiến dịch → Publish | Khi app đang mở, Android không đưa tin lên khay, nên app hiện thanh thông báo trên màn đang xem. Thanh này gắn với phiên nhận tin: đăng xuất thì nó biến mất. | 40 giây |
| 3 | Push khi app chạy nền | Về màn hình chính → tin trên khay → bấm → app mở thẳng Hồ sơ | Chiến dịch thứ hai | Tin nhận khi app ở nền được ghi lại và đưa vào hộp thư khi app quay lại. Bấm tin luôn mở hộp thư (contract tạm của nhóm). | 30 giây |
| 4 | Push khi app đã tắt | Tắt app → tin trên khay → bấm → app khởi động, mở Hồ sơ, tin có trong hộp thư | Chiến dịch thứ ba | Ba trạng thái đều nhận được. Một tin đi qua nhiều đường chỉ có một mục, và tin của người khác bị loại. | 30 giây |
| 5 | Xuất PDF và tải lên | Hồ sơ → "Xuất báo cáo PDF" → tiến độ → đường dẫn → mở PDF | **Chưa có**: project chưa có Storage (DEC-01) | Nếu quay trên Storage Emulator thì phải ghi rõ trên màn hình "Storage Emulator". PDF được lưu trên máy trước, tải lên lỗi thì thử lại không tạo file mới. | 40 giây |
| 6 | Đăng xuất | Hồ sơ → Đăng xuất → xác nhận → Sign-in | Không | Đăng xuất xóa dữ liệu phiên và PDF trên máy, hủy upload đang chạy; bản trên cloud không bị xóa. | 15 giây |

## Cần chuẩn bị

- Charlie đăng nhập trên emulator khi quay cảnh 1 (Claude không nhập mật khẩu).
- Ba chiến dịch Console, mỗi cảnh 2, 3, 4 một chiến dịch, gửi trước khoảng 2 phút cho mỗi cảnh.
- Cảnh 5: chờ DEC-01, hoặc nhóm đồng ý quay trên Storage Emulator có ghi chú rõ. Nếu cả hai đều không được thì bỏ cảnh 5 và ghi giới hạn này vào báo cáo.
- Ảnh dự phòng cho phần Console: `evidence/auth/S3-9-20261102/console-auth-users.jpg`, `evidence/fcm/S4-15-push-20261102/00-console-campaigns.jpg`, `evidence/fcm/S4-12-foreground-20261103/00-console-campaigns.jpg`.

## Giới hạn sẽ ghi kèm clip

- Quay trên emulator, chưa phải máy thật.
- Push gửi theo chiến dịch tới cả app, chưa gửi theo từng người dùng.
- Phần upload chỉ có trên Storage Emulator cho đến khi có DEC-01.
