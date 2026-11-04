# S5-10 — Failure cases chạy thủ công trên máy Thắng, 04/11/2026

> Trạng thái: **2 case manual pass, task chưa hoàn tất**. Không dùng hai case này
> để suy ra sáu dịch vụ Firebase đều đã đạt.

## Môi trường

- Commit kiểm tra: `90d9fd0` (`main`, sau khi merge nhánh `Thang`).
- Thiết bị: AVD `Longvita_API_36`, Android 16 / API 36, `emulator-5554`.
- Package: `vn.edu.fpt.longvita`.
- Phiên Firebase Auth có sẵn được khôi phục; không nhập lại credential.

## Kết quả

| Case | Thao tác và quan sát | Kết quả | Evidence |
|---|---|---|---|
| Remote Config offline | Tắt cả Wi-Fi và mobile data; `ping 8.8.8.8` trả `Network is unreachable`; tại Profile bấm **Cập nhật Remote Config**. UI giữ các giá trị hiện tại và hiện “Không có giá trị mới hoặc chưa tải được. Vẫn dùng giá trị hiện có.”, không báo áp dụng thành công giả. | **PASS** | [`01-remote-config-offline.png`](01-remote-config-offline.png) |
| Crashlytics — hủy test crash | Mở hộp thoại **Gây crash thử?**, chọn **Hủy**. Ứng dụng trở về Profile và tiến trình package vẫn tồn tại (`pidof` trả PID). Không kích hoạt crash thật. | **PASS** | [`02-crash-cancel-dialog.png`](02-crash-cancel-dialog.png), [`03-crash-cancelled-app-stable.png`](03-crash-cancelled-app-stable.png) |

## Case chưa được tính pass

- **FCM / từ chối quyền notification:** đã tạm revoke quyền và mở lại ứng dụng;
  Android hiển thị permission gate. Phiên tự động không bấm lựa chọn trên hộp
  thoại quyền riêng tư, vì vậy không ghi case này là manual pass. Quyền đã được
  grant lại và Wi-Fi/mobile data đã bật lại sau kiểm tra.
- **Auth offline:** không sign-out phiên thật chỉ để tái hiện lỗi vì thao tác đó
  sẽ yêu cầu người dùng đăng nhập lại; cần thực hiện khi có người sở hữu tài
  khoản tham gia buổi test.
- **Storage denied/cancel:** đã có Storage Emulator evidence từ trước, nhưng chưa
  chạy lại trong phiên này và project thật vẫn bị chặn bởi DEC-01.
- **Analytics offline delivery, Crashlytics non-fatal và Remote Config live:**
  cần DebugView/Crashlytics/Remote Config Console của đúng Firebase project.

## Khôi phục sau kiểm thử

- Wi-Fi: bật.
- Mobile data: bật.
- `android.permission.POST_NOTIFICATIONS`: `granted=true`.
- Ứng dụng Longvita được mở lại sau khi khôi phục.
