# Failure-case matrix — S5-10

> **Cập nhật 03/11/2026 — ĐANG LÀM.** Bảng phân biệt rõ kiểm chứng tự động,
> emulator, Firebase project thật và phần còn bị chặn. Không dùng test bằng fake
> để tuyên bố cloud runtime đã đạt.

| Dịch vụ | Failure case | Kết quả hiện có | Loại bằng chứng | Trạng thái còn thiếu |
|---|---|---|---|---|
| Auth | Hủy Google account picker | Quay về Sign-in, có thông báo, không crash | Android emulator thật: `evidence/auth/S3-9-20261102/cancelled.png`; widget tests | Chạy lại bằng debug certificate của Thắng sau khi Firebase thêm SHA |
| Auth | Mất mạng / credential lỗi | Hiện lỗi mạng hoặc credential và nút thử lại | Fake service + `test/auth/auth_screens_test.dart`, `auth_error_mapper_test.dart` | Chưa tái hiện mất mạng với Firebase Auth thật trên máy Thắng |
| Auth/Firestore | Đăng nhập thành công nhưng profile lỗi | Mở recovery, cho retry hoặc sign-out; không báo nhầm cancel | Fake service + widget tests | Chưa ép lỗi profile trên project thật |
| Storage | Hủy upload | Hủy thật, file PDF local còn, có thể retry | Storage Emulator: `evidence/storage/S4-11-emulator-20261102/03-upload-cancelled.png`; unit/widget tests | Project thật chưa có Storage theo DEC-01 |
| Storage | Rules từ chối | Hiện permission denied và nút retry | Storage Emulator: `06-upload-denied.png`; 14 rules tests | Chưa xác minh Console/project thật |
| FCM | Từ chối quyền notification | Profile giải thích trạng thái, app không crash | Fake messaging + widget tests | Chưa thao tác từ chối quyền thủ công trên máy Thắng |
| FCM | Tin đến khi phiên kết thúc | Snackbar/tác vụ cũ bị loại; không rò sang user kế tiếp | Widget/unit tests; evidence thiết bị ngày 03/11 | A→B và A→logout→A chưa kiểm thủ công trên máy Thắng |
| Analytics | Không có mạng khi log event | Code không chặn luồng nghiệp vụ; login/logout đã thấy trên DebugView | Implementation review + DebugView `evidence/analytics/S5-4-debugview-20261102/` | Chưa kiểm offline→online delivery; `export_report` chưa có DebugView thật |
| Crashlytics | Người dùng hủy test crash | Đóng dialog, không crash | Widget test + `evidence/ui/S4-13-profile-20261102/04-crash-confirm.png` | Cần non-fatal từ luồng thật và dashboard có user ID/custom key |
| Crashlytics | Xác nhận test crash | Crash đã lên Console project thật | `evidence/crashlytics/S4-13-test-crash-20261102/` | Cần hoàn thiện non-fatal failure evidence |
| Remote Config | Fetch không áp dụng giá trị mới / lỗi | Không báo thành công sai; UI giữ defaults/current values | Widget tests | Chưa đổi ≥2 giá trị trên Console và thử offline trên máy Thắng |

## Điều kiện đóng S5-10

- Chạy thủ công trên Android ít nhất một failure case cho từng dịch vụ trong sáu
  dịch vụ: Auth, Storage, FCM, Analytics, Crashlytics và Remote Config.
- Ghi observed result, thời gian, build/commit và evidence path; không thay bằng
  expected result hoặc fake test.
- Storage project thật/DEC-01, Firebase SHA của máy Thắng và Remote Config Console
  vẫn là blockers bên ngoài bảng kiểm thử tự động hiện có.
