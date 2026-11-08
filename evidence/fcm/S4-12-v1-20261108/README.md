# S4-12 — Contract FCM v1, 08/11/2026

Kiểm commit `ada76da` (nhánh `feature/charlie-fcm-safe-01`, từ main `b7507ec`). Contract: [`docs/tasks/charlie-progress.md`](../../../docs/tasks/charlie-progress.md), mục "Contract FCM v1".

## Thay đổi được kiểm

- Tin chỉ được nhận khi `recipient_uid` khớp chính xác user đang đăng nhập. Tin thiếu, rỗng, sai kiểu hoặc khác user không vào inbox, lịch sử hay hàng chờ; không hiện thanh thông báo trong app; không mở Profile.
- Lịch sử khôi phục được kiểm lại người nhận từng mục. Mục đọc lỗi chỉ bỏ riêng mục đó.
- Mỗi phiên có số thế hệ riêng, kể cả A → đăng xuất → A, nên việc đọc lịch sử, lấy tin chờ hay lưu của phiên cũ không tác động phiên mới. App không lưu trước khi đọc xong lịch sử.
- Tin nền xếp mỗi tin một file trong `notifications/pending/`, tối đa 50. App chỉ lấy tin của user đang đăng nhập và xóa file sau khi lưu thành công. File `pending.json` của bản cũ được chuyển một lần.

## Kiểm tự động

| Kiểm | Kết quả |
|---|---|
| `flutter analyze --no-pub` | Sạch ([analyze.txt](analyze.txt)) |
| `flutter test --no-pub` toàn bộ | 376/376 ([flutter-test.txt](flutter-test.txt)) |
| `test/fcm`, `test/profile` | 143/143 |
| Kiểm đột biến: gỡ từng chỗ sửa rồi chạy lại test | 9/9 bị test bắt ([mutation-check.txt](mutation-check.txt)) |

Các test dùng gateway giả; phần lưu trữ dùng thư mục tạm thật. Hai store cùng thư mục giả lập isolate nền ghi trong lúc app đang lấy tin. Thứ tự race được điều khiển bằng `Completer`, không dùng sleep.

## Kiểm trên AVD

**Môi trường:**
- AVD `LocalMate_API_35` (Android 15), APK debug từ `ada76da` (SHA-256 `cd40981322ced001249622243d7bded20d6179db64a24cabf8c3f4a15abb3224`).
- Firebase project `longvita-8da7e`. Tài khoản kiểm của Charlie đã đăng nhập sẵn.

**Cách gửi:**
- Script QA ngoài Git gọi FCM HTTP v1 bằng tài khoản `firebase login`, gửi tới token của AVD (đọc từ log debug mỗi lượt).
- Nội dung chung: title "Longvita", body "Bạn có thông báo mới. Mở ứng dụng để xem."
- `data` chỉ có `message_id` và `recipient_uid` (đúng UID của tài khoản kiểm, một UID giả `qa-other-uid-0000`, hoặc bỏ trường).

**Cách kiểm:** đọc file của app qua `run-as` (bản debug) và hierarchy qua `uiautomator`. "Terminated" là về Home rồi `am kill` (không force-stop), có kiểm tiến trình đã chết trước khi gửi.

| Ca | Kỳ vọng | Kết quả |
|---|---|---|
| Foreground, đúng người nhận | Thanh "Thông báo mới", vào lịch sử | PASS |
| Foreground, thiếu người nhận | Không gì cả | PASS |
| Foreground, sai người nhận | Không gì cả | PASS |
| Background, đúng | Khay hiện tin; handler xếp 1 file; bấm mở Profile; vào lịch sử; file chờ đã xóa | PASS |
| Background, sai | Khay vẫn hiện tin chung (do hệ điều hành); handler xếp 1 file cho UID kia; bấm thì app mở ở Dashboard, không Profile, không vào lịch sử | PASS |
| Background, thiếu | Khay hiện tin chung; handler không xếp file; bấm không mở Profile, không vào lịch sử | PASS |
| Terminated, đúng | Bấm thì app khởi động, mở Profile, vào lịch sử | PASS |
| Terminated, sai | Lần 1 (14:44): `am kill` chưa dừng được tiến trình nên ca này chưa đạt điều kiện terminated, ghi **FAIL precondition**. Hành vi app vẫn đúng: không Profile, không vào lịch sử. Retry (14:45) sau khi kill có kiểm lại: PASS | FAIL → retry PASS |

Chi tiết từng lượt: [native-results.json](native-results.json). Không ghi token hay UID.

`01-profile-inbox-v1.png`: inbox sau lượt kiểm có đúng ba tin của ca "đúng người nhận".

## Ghi chú và giới hạn

- **Lịch sử cũ trên AVD:** có 21 mục không có `recipient_uid` (tin TC-10 của S6-7). Bản mới không hiện các mục này, và chúng mất khỏi file ở lần lưu kế tiếp, theo contract. Bản sao file cũ được giữ ngoài Git.
- **Hàng chờ của UID giả:** sau lượt kiểm còn 3 file chờ của `qa-other-uid-0000`. Đây là hành vi đúng: tin của user khác được giữ, tối đa 50 file.
- **Giới hạn của bộ lọc:** `recipient_uid` chỉ lọc phía app. Khi app ở nền hoặc đã tắt, Android tự hiện tin trên khay trước khi app kiểm, nên tin gửi nhầm vẫn để lại lời nhắc chung trên khay. App chỉ chặn inbox và điều hướng.
- **Chưa kiểm trên AVD:** A → đăng xuất → A/B trong lúc đang đọc lịch sử hay lấy tin chờ mới được kiểm bằng test có điều khiển thứ tự. Tôi không đăng xuất/đăng nhập Google thật lặp lại cho phần này.
