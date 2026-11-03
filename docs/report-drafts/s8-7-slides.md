# Nháp slide S8-7 — Auth, FCM, Storage

> Nội dung ba slide của Charlie, gửi Thắng ghép ở S8-10. Mỗi slide một thông điệp, một ảnh bằng chứng thật và cơ chế xử lý lỗi. Chưa dựng theo template chung vì nhóm chưa chốt định dạng; khi có template thì chuyển nguyên nội dung này vào. Đường dẫn ảnh tính từ gốc repo.

---

## Slide 1 — Firebase Authentication

**Thông điệp:** Đăng nhập Google, mỗi người chỉ thấy dữ liệu của mình, kể cả khi đổi tài khoản trên cùng máy.

**Nội dung trên slide:**
- Google Sign-In → Firebase Auth → hồ sơ `users/{uid}` với `role: user`.
- Hủy chọn tài khoản là thông báo thông tin, không phải lỗi.
- Đăng xuất: xóa dữ liệu phiên, gỡ user ID khỏi Analytics và Crashlytics, xóa màn đã mở.
- Kết quả về muộn sau khi đổi phiên bị bỏ qua (`SessionEpoch`).
- Firestore rules: chỉ chủ tài khoản đọc hồ sơ, không tự đổi role. 41/41 test trên emulator.

**Ảnh:** `evidence/auth/S3-9-20261102/signed-in.png` cạnh `evidence/auth/S3-9-20261102/console-auth-users.jpg`.

**Ghi chú người nói:** Nhấn mạnh hai lỗi session đã tìm và sửa: kết quả của người dùng trước lọt sang người sau. Giới hạn: mới có SHA của một máy, chưa thử máy thật.

---

## Slide 2 — Firebase Cloud Messaging

**Thông điệp:** Tin gửi từ Console đến được ở cả ba trạng thái app, đúng người, không trùng, và không lộ sang phiên sau.

**Nội dung trên slide:**
- Foreground: thanh thông báo trên màn đang xem, nút "Xem" mở hộp thư.
- Background, terminated: tin trên khay hệ thống, bấm mở Profile.
- Một tin qua nhiều callback chỉ có một mục; tin của người khác bị loại.
- Lịch sử lưu trên máy theo UID, còn sau khi khởi động lại.
- Đăng xuất: thông báo của phiên cũ biến mất, nút "Xem" cũ vô hiệu (PM-FCM-02).

**Ảnh:** `evidence/fcm/S4-15-push-20261102/00-console-campaigns.jpg`, `evidence/fcm/S4-12-foreground-20261103/01-home-snackbar.png`, `evidence/fcm/S4-15-push-20261102/04-terminated-tray.png`.

**Ghi chú người nói:** Kể lỗi PM-FCM-02 như một ví dụ review: snackbar sống qua đăng xuất; sửa bằng cách gắn thông báo với phiên nhận tin. Giới hạn: contract tạm (mọi tin mở Profile), chưa có token theo user, mới chạy trên emulator.

---

## Slide 3 — Cloud Storage

**Thông điệp:** PDF luôn được giữ trên máy trước; tải lên lỗi thì thử lại được mà không tạo file mới, và chỉ chủ tài khoản truy cập được thư mục của mình.

**Nội dung trên slide:**
- Lưu PDF trên máy → tải lên `reports/{uid}/{exportId}.pdf` → đường dẫn tải.
- Lỗi có loại riêng: mất mạng, bị từ chối, chưa có bucket, hết dung lượng, đã hủy.
- Hủy thật, thử lại cùng ID, đăng xuất giữa chừng hủy upload và xóa file trên máy.
- Storage rules owner-only: 14/14 test; rules mở toang làm đúng 9 ca fail.
- **Chạy trên Storage Emulator**: project chưa có Storage (DEC-01).

**Ảnh:** `evidence/storage/S4-11-emulator-20261102/01-upload-success.png` cạnh `evidence/storage/S4-11-emulator-20261102/03-upload-cancelled.png`.

**Ghi chú người nói:** Ghi rõ trên slide đây là emulator. Nếu nhóm bật Blaze trước hạn nộp, thay ảnh bằng file trên Console và DebugView `export_report`.

---

## Còn thiếu trước khi chốt

- Template và định dạng của bản slide chung (Thắng).
- Ảnh Console cho Storage, nếu DEC-01 chọn dùng Storage.
- Một số ảnh nguồn có email, UID hoặc tên thật của Charlie; bắt buộc che/cắt toàn bộ định danh trước khi đưa vào slide, repo hoặc bản nộp.
