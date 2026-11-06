# S5-10 — Cloud/runtime failure evidence, 06/11/2026

**Thiết bị:** `Longvita_API_36`, Android 16/API 36, `emulator-5554`

**Ứng dụng:** `vn.edu.fpt.longvita`, version `1.0.0 (1)`

**Project:** `longvita-8da7e`

## Kết quả

| Dịch vụ | Ca kiểm tra | Kết quả |
|---|---|---|
| Remote Config | Publish hai giá trị mới, fetch/activate không rebuild, rồi hoàn nguyên | **PASS** — `max_meal_recommendations` 5 → 6 → 5; `enable_longevity_score` true → false → true; app báo “Đã áp dụng giá trị mới.” |
| Crashlytics | Test crash có xác nhận và mở lại ứng dụng | **PASS** — fatal issue xuất hiện trên Console; app mở lại đúng phiên admin |
| Analytics | Logout khi emulator offline, bật mạng, đăng nhập lại | **PASS** — DebugView nhận `logout` và `login` sau khi kết nối được khôi phục |
| Crashlytics non-fatal | Google Sign-In khi offline | **PASS** — app hiện lỗi mạng, không crash; Console nhận `AuthFailureKind.network`, `network_error`, `ApiException: 7`, reason `Google sign-in failed (network)` |

## Ảnh

- `01-remote-config-baseline.png`: in-app defaults trước thay đổi.
- `02-remote-config-live-changed.png`: giá trị 6/Tắt và snackbar áp dụng thành công.
- `03-remote-config-restored.png`: hoàn nguyên 5/Bật.
- `04-crashlytics-card.png`, `05-crash-confirmation.png`: điểm vào và xác nhận test crash.
- `06-app-recovered-admin.png`: app phục hồi; profile runtime là admin.
- `07-crashlytics-fatal-console.png`: fatal test issue trên Console.
- `08-analytics-debug-device.png`: DebugView nhận debug device.
- `09-auth-offline-error.png`, `10-auth-online-recovered.png`: lỗi mạng và phục hồi phiên.
- `11-analytics-logout-login.png`: DebugView có `logout` và `login`.
- `12-crashlytics-nonfatal-network.png`: non-fatal network issue và reason trên Console.

## Phạm vi và giới hạn

- Tài khoản và UID trong evidence được giữ theo quyết định của chủ tài khoản để
  chứng minh tài khoản nhóm với giảng viên; bộ ảnh không chứa password, API key,
  access token hay service-account secret.
- Storage failure đã được kiểm tra thủ công bằng Firebase Storage Emulator trong
  `evidence/storage/S4-11-emulator-20261102/`; project Spark dùng chung chưa có
  bằng chứng Storage cloud thành công. Không diễn giải kết quả Emulator thành
  production/cloud pass.
- Firestore project dùng chung chưa có collection `recipes`, nên tạo thực đơn mới,
  plan mới và export/upload từ tài khoản Thắng vẫn bị chặn bởi dữ liệu nghiệp vụ.
