# Thắng — Fresh Google Sign-In và Auth/FCM failure cases, 05/11/2026

> Kết quả trên AVD `Longvita_API_36`, Android 16 / API 36, package
> `vn.edu.fpt.longvita`, commit `dcbdedf`. Ảnh account picker và Dashboard có
> tên/email chỉ được dùng để người dùng quan sát trong phiên, **không đưa vào
> repo**. Evidence lưu bên dưới không chứa định danh tài khoản.

## Cấu hình được kiểm

- SHA-1 debug của máy Thắng:
  `9D:9C:D3:03:14:86:02:C5:5A:3A:5E:68:97:22:35:4C:19:F6:D5:71`.
- SHA-256 debug:
  `DF:E1:24:36:77:DE:ED:4C:85:17:B4:7A:DC:16:4B:14:5B:7E:6A:EE:5B:3B:75:C2:2B:55:29:3F:0D:A9:9A:0A`.
- Firebase project `longvita-8da7e`; Console/OAuth registration đã được ghi tại
  [`../S3-2-20261104/README.md`](../S3-2-20261104/README.md).
- Người dùng tự chọn tài khoản trong Google account picker; agent không thao tác
  xác thực và không lưu credential.

## Kết quả

| Case | Thao tác và quan sát | Kết quả | Evidence |
|---|---|---|---|
| Fresh Google Sign-In bằng SHA của Thắng | Đăng xuất phiên cũ, mở Google account picker, người dùng tự chọn tài khoản; app vào Dashboard đúng phiên. Log không có `ApiException: 10`, `sign_in_failed` hoặc `PlatformException` cấu hình. Các cảnh báo `Phenotype.API ... DEVELOPER_ERROR` thuộc Google Play Services trên emulator, không phải Google Sign-In. | **PASS** | Quan sát runtime + log đã khử PII; không commit ảnh Dashboard/account picker |
| Hủy Google account picker | Từ Sign-in mở account picker rồi nhấn Back. App trở về Sign-in, hiện “Bạn đã đóng cửa sổ chọn tài khoản. Đăng nhập lại khi bạn sẵn sàng.” và không crash. | **PASS** | [`01-auth-account-picker-cancelled.png`](01-auth-account-picker-cancelled.png) |
| FCM permission denied | Revoke `POST_NOTIFICATIONS`, mở lại app; người dùng tự chọn **Don’t allow**. `dumpsys package` xác nhận `granted=false`, cờ `USER_FIXED`; app vẫn chạy và Profile giải thích “Thông báo đang tắt…”. Sau test quyền đã được grant lại. | **PASS** | [`02-fcm-permission-denied-profile.png`](02-fcm-permission-denied-profile.png) |
| Google Sign-In khi offline | Tắt Wi-Fi và mobile data; `ping 8.8.8.8` trả `Network is unreachable`. Người dùng tự chọn tài khoản; app trở về Sign-in, hiện lỗi “Không có kết nối mạng. Kiểm tra mạng rồi thử lại.”, không crash. Log ánh xạ `ApiException: 7` thành `AuthFailureKind.network`. Sau test mạng đã bật lại. | **PASS** | [`03-auth-offline-network-error.png`](03-auth-offline-network-error.png) |

## Giới hạn

- Không dùng kết quả này để khẳng định Storage, Analytics, Crashlytics non-fatal,
  Remote Config live hoặc toàn bộ FCM cloud flow đã đạt.
- S5-10 vẫn đang làm vì điều kiện đóng yêu cầu ít nhất một failure case thủ công
  cho cả sáu dịch vụ Firebase và evidence cloud còn thiếu.
