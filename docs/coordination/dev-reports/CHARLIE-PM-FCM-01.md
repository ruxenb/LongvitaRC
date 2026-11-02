# PM-FCM-01 — Tin bị từ chối ghi đè cache thông báo

Trả lời PM re-review tại `914508c` (`docs/coordination/PM_REREVIEW_914508c.md`), 02/11/2026. **Trạng thái đề nghị: Ready for PM review.** Commit `2d547c7`, phạm vi task S4-12. Không đụng hai lỗi session đã đóng.

## Nguyên nhân và cách sửa

`NotificationService` có hai nơi lưu: `_raw` (ghi trước) và inbox (quyết định sau), nên hai nơi có thể lệch nhau.

**Cách sửa:** bỏ hẳn `_raw`. Payload gốc đi cùng entry qua trường `AppNotification.source`, và `messages` đọc từ các entry của inbox. Chỉ còn một nơi lưu nên không còn cache nào để lệch; tin bị từ chối không được lưu, tin chờ trước đăng nhập vẫn giữ payload, và xóa phiên thì xóa cả payload.

**Quy tắc:** khi trùng `message_id` trong một phiên, **tin được chấp nhận đầu tiên thắng**. Đây là quyết định của Dev, cần xem cùng contract FCM.

## Lỗi cùng gốc do Dev phát hiện thêm

Tin trùng ID khác nội dung, nếu được tap, điều hướng theo target của tin trùng thay vì tin đã được chấp nhận. Đã sửa trong `NotificationInbox.receive`, có test riêng.

## Điều kiện đóng của PM

| Điều kiện | Kết quả | Test |
|---|---|---|
| Ca tái hiện của PM, không đổi expected | Pass | `pm-repro-result.txt`, chạy từ file tạm rồi xóa |
| Trùng ID khác nội dung | Pass | `a duplicate with other content keeps the first accepted`, `a tapped duplicate routes to the accepted target` |
| Sai recipient sau khi bind | Pass | `a late message for A does not overwrite B`, `a rejected message first does not block the accepted one`, `a tapped message for A gives B no route` |
| Sai recipient trước khi bind | Pass | `held messages keep their payload until sign-in`, `a held message for A arriving last does not overwrite B` |
| Clear/logout rồi B đăng nhập | Pass | `A -> logout -> B: no payload of A remains`, `the same id can be delivered to B after A signed out` |
| Đổi user không qua clear | Pass | `binding B directly over A drops the payload of A` |
| `inbox` và `messages` cùng recipient, nội dung | Pass | Hàm `expectAgree` trong các ca trên |
| Giữ cold start và foreground rồi tap | Pass | `a held tap keeps its payload and routes after sign-in`, `foreground then tap keeps one payload and still routes` |

Trong đó 4 ca fail trên code cũ (`before-fix.txt`); các ca còn lại là chốt hành vi cần giữ, pass cả trước và sau khi sửa.

## Kiểm tra tại `2d547c7`

Log: `evidence/review/PM-FCM-01/`.

| Check | Kết quả |
|---|---|
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub test` | **133/133 pass** (121 cũ, 12 mới) |
| `flutter build apk --debug` | Thành công |
| Test rules | **Không chạy lại.** `git diff 914508c -- firebase` rỗng, 41/41 là kết quả trước đó |

## Giới hạn

- Tất cả dùng gateway giả. **Chưa có push thật**, chưa chạy lại trên thiết bị sau bản sửa này.
- Tin **không có** `recipient_uid` vẫn đến người đăng nhập kế tiếp. Đây là câu hỏi còn mở trong [FCM-CONTRACT-PROPOSAL](FCM-CONTRACT-PROPOSAL.md), bản sửa này không chốt thay.
- Lịch sử vẫn chỉ ở RAM, chưa nối router và Profile.
- `source` có kiểu `Object?` vì model không phụ thuộc Firebase. Khi chọn cách lưu history, trường này sẽ cần xem lại.
