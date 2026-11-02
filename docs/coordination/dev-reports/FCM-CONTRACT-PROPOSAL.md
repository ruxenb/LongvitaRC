# S4-12 FCM — đề xuất contract, chờ chốt

Đề xuất của Dev theo PM review mục 7, 02/11/2026. **Chưa được duyệt, chưa tích hợp router, chưa chạy push thật.** Các giá trị dưới đây có thể đổi khi owner chốt.

| Contract | Đề xuất | Đã có trong code | Cần ai chốt |
|---|---|---|---|
| **Payload** | Trường `data`: `schema_version` (`"1"`), `message_id`, `target_type`, `target_id`, `recipient_uid` (có khi tin dành riêng một user). Không nhận route string từ push | Parser `AppNotification.parse`, có test | Thắng, Thái An |
| **Thiếu/sai target** | Tin vẫn vào inbox, không điều hướng, có lý do: sai version, loại lạ, thiếu ID. Không có ID tin nhắn thì bỏ vì không chống trùng được | Có test | Thắng: thông báo hiển thị khi đích lỗi |
| **Loại target** | `meal_plan`, `announcement` (đề xuất tạm) | Danh sách `notificationTargetTypes` | Thắng, Hoàng |
| **Không có quyền xem đích** | Router/màn đích kiểm tra và báo lỗi; rules là lớp chặn cuối | Chưa | Thắng, Hoàng |
| **Router** | `NotificationService.takePendingTarget()` trả target một lần. Router gọi khi đã sẵn sàng, gồm cả sau khi qua auth/profile recovery | Có API, **chưa nối router** | Thắng: route intent, thời điểm ready, fallback |
| **History** | Chưa chọn local theo UID hay Firestore. Nếu Firestore thì cần schema, rules, test trước khi ghi | Chỉ trong RAM, **mất khi mở lại app** | Hoàng, Thắng |
| **Read state, retention** | Chưa có | Chưa | Hoàng, Thắng |
| **Chống trùng** | Theo `message_id`, trong từng phiên user | Có test | Khi chọn history cần làm bền qua lần mở lại |
| **Session** | Đăng xuất xóa inbox và tin đang chờ. Tin có `recipient_uid` khác user hiện tại bị bỏ. Tin đến khi chưa đăng nhập chờ tới lần đăng nhập kế | Có test | Thái An/Thắng: tin **không có** `recipient_uid` sẽ đến người đăng nhập kế tiếp, cần chốt có chấp nhận không |
| **Token** | Chưa lưu token theo UID, chưa xử lý refresh, chưa xóa khi đăng xuất. Chưa có cách gửi tới từng user nếu không có | Chưa | Thái An, Thắng |
| **Background/terminated** | Handler riêng, không điều hướng, không lưu gì vì chưa chốt history | Đã đăng ký, **chưa chạy thật** | Theo History |
| **Evidence** | Foreground/background/terminated không force-stop, tap đúng đích, cho phép/từ chối quyền, target lỗi, chống trùng, A/B. Gửi từ Console là thao tác có người hỗ trợ | Chưa có evidence thật | Charlie, Thái An |

## Câu hỏi cần trả lời để tiếp tục

1. **Thắng:** route intent cho `meal_plan`, `announcement` là gì, và router gọi `takePendingTarget()` ở đâu?
2. **Hoàng, Thắng:** history lưu local theo UID hay Firestore?
3. **Thái An, Thắng:** gửi push theo token từng user hay topic chung? Câu này quyết định cần lưu token và `recipient_uid` thế nào.

## Giới hạn

Các test dùng gateway giả, nên chỉ chứng minh logic parser, chống trùng, session và cách nối lifecycle. Chúng **không** chứng minh Android nhận được push ở ba trạng thái.
