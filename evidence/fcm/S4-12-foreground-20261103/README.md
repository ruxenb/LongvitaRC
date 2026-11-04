# S4-12 — Tin đến khi app đang mở, 03/11/2026

Tin gửi từ **Firebase Console thật** (project `longvita-8da7e`, chiến dịch nhắm app `vn.edu.fpt.longvita`) tới AVD `LocalMate_API_35` (Android 15), bản debug của nhánh `feature/charlie-fcm-feedback-01`. Đăng nhập bằng tài khoản thật của Charlie, quyền thông báo đã cấp, app đang mở ở Home.

| File | Nội dung |
|---|---|
| `00-console-campaigns.jpg` | Hai chiến dịch ngày 03/11 trên Console, trạng thái Completed |
| `01-home-snackbar.png` | Tin "Longvita thử snackbar" đến khi đang ở Home: hiện "Thông báo mới: …" kèm nút "Xem" |
| `02-home-snackbar-xem.png` | Tin thứ hai "Longvita thử nút Xem" trên Home |
| `03-xem-opens-profile.png` | Bấm "Xem": mở Profile |
| `04-inbox-has-both.png` | Hộp thư trên Profile có cả hai tin, trên các tin của ngày 02/11 |
| `05-pm-fcm-02-before-sign-out.png` | Sau bản sửa PM-FCM-02 (`c40d884`): tin thứ ba "Longvita thử đăng xuất" hiện trên Home |
| `06-pm-fcm-02-sign-in-is-clean.png` | Bấm đăng xuất trên Home khi thanh thông báo còn hiện; 0,6 giây sau, Sign-in không còn nội dung tin hay nút "Xem" (`uiautomator dump` cũng không thấy) |
| *(ảnh 07 không lưu trong repo)* | Thử hàng đợi trên `main` `30ca6e3`: tắt mạng, phát hành hai chiến dịch, bật mạng lại; "Longvita hàng đợi 2" hiện trên Home. Ảnh gốc bị loại vì chứa tên và email thật; kết quả được đối chiếu cùng ảnh 08 và log thiết bị. |
| `08-queue-attempt-sign-in-72s.png` | Đăng xuất ngay khi tin hiện; kiểm `uiautomator dump` khoảng 3 giây một lần trong 72 giây: không lần nào có nội dung thông báo cũ |

## Kết quả

- Android không đưa tin lên khay khi app đang mở. Trước thay đổi này, tin chỉ vào hộp thư mà không có dấu hiệu gì trên Home.
- Giờ tin mới hiện thanh thông báo trên màn đang xem, kèm nút "Xem" mở hộp thư.
- Tin đến sau khoảng 1,5 đến 2,5 phút kể từ khi phát hành chiến dịch.
- Lịch sử của ngày 02/11 vẫn còn sau khi cài lại app và đăng nhập lại.

## Giới hạn

- Mới thử trên Home. Ca màn khác (route đẩy lên trên Home) chỉ được kiểm bằng widget test.
- **Lần thử hàng đợi (07, 08) chưa tái hiện được hai tin cùng chờ:** logcat chỉ có một lần nhận tin (`FLTFireMsgReceiver`, 11:56:01) trước khi đăng xuất, tin "hàng đợi 1" chưa đến máy. Nên đây vẫn là ca một tin. Ca hàng đợi chỉ được kiểm bằng widget test.
- PM-FCM-02 trên thiết bị mới thử ca đăng xuất. Ca A -> B và A -> đăng xuất -> A, và việc nút "Xem" cũ không mở Profile, được kiểm bằng widget test.
- Ca tin trùng, tin của người khác và tin sau khi đăng xuất không hiện thanh thông báo: mới kiểm bằng test.
- Contract tạm vẫn áp dụng: bấm "Xem" hay bấm tin đều mở Profile.
