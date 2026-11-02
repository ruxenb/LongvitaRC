# S4-15 — Push FCM thật, 02/11/2026

Tin gửi từ **Firebase Console thật** (project `longvita-8da7e`, chiến dịch nhắm app `vn.edu.fpt.longvita`) tới AVD `LocalMate_API_35`, bản debug. Đăng nhập bằng tài khoản thật của Charlie. Quyền thông báo đã cấp.

| File | Nội dung |
|---|---|
| `00-console-campaigns.jpg` | Ba chiến dịch đầu trên Console, trạng thái Completed |
| `01-foreground-in-inbox.png` | App đang mở: tin vào hộp thư Profile |
| `02-background-tray.png`, `03-background-opened.png` | App chạy nền: tin trên khay, bấm thì mở app |
| `04-terminated-tray.png`, `05-terminated-opened-inbox.png` | App đã tắt: tin trên khay, bấm thì mở app |
| `06-history-after-restart.png` | Tắt rồi mở lại app: hộp thư vẫn đủ tin |
| `07-tap-opens-profile-background.png` | Bấm tin khi app chạy nền: mở thẳng Profile |
| `08-tap-opens-profile-terminated.png` | Bấm tin khi app đã tắt: mở thẳng Profile |

## Kết quả

| Trạng thái | Nhận tin | Bấm tin |
|---|---|---|
| Foreground | Vào hộp thư khi đang mở Profile | Không có khay, không điều hướng |
| Background | Trên khay hệ thống | Mở Profile, tin có trong hộp thư |
| Terminated | Trên khay hệ thống | Mở Profile, tin có trong hộp thư |

Tin đến sau khoảng 45 giây đến 2 phút kể từ khi phát hành chiến dịch. Log không có `Unhandled Exception` hoặc `FATAL EXCEPTION`.

"Terminated" ở đây là `am kill` sau khi về Home, không phải force-stop, vì Android chặn FCM với app bị force-stop. Khi tin đến, Android có thể khởi chạy lại tiến trình để chạy handler nền, nhưng giao diện chưa mở cho đến khi bấm tin.

## Giới hạn

- **Contract tạm**, cả nhóm đã đồng ý: mọi tin bấm vào đều mở Profile, lịch sử lưu trên máy theo UID, thiếu `recipient_uid` thì hiện cho người đang đăng nhập.
- Gửi theo chiến dịch tới cả app, chưa gửi theo user vì chưa lưu token.
- Khi app đang mở ở màn khác Profile, tin vào hộp thư nhưng chưa có thông báo trên màn đó.
- Tin từ Console không có `target_type`. Tin có đích và đích lỗi chỉ test bằng fake.
- Phần Storage của S4-15 vẫn chờ DEC-01.
- Chưa thử trên máy thật.
