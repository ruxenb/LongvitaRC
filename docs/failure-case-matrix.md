# Failure-case matrix — S5-10

> **Cập nhật 05/11/2026 — ĐANG LÀM.** Bảng phân biệt rõ kiểm chứng tự động,
> emulator, Firebase project thật và phần còn bị chặn. Không dùng test bằng fake
> để tuyên bố cloud runtime đã đạt.

| Dịch vụ | Failure case | Kết quả hiện có | Loại bằng chứng | Trạng thái còn thiếu |
|---|---|---|---|---|
| Auth | Hủy Google account picker | Ngày 05/11 dùng SHA/certificate của Thắng: quay về Sign-in, có thông báo, không crash | Manual AVD: `evidence/auth/S3-2-S5-10-THANG-20261105/01-auth-account-picker-cancelled.png`; widget tests | **Manual PASS** |
| Auth | Mất mạng / credential lỗi | Ngày 05/11 tắt Wi-Fi/mobile data; chọn tài khoản xong app hiện lỗi mạng và cho thử lại, không crash; log ánh xạ `ApiException: 7` thành network failure | Manual AVD: `evidence/auth/S3-2-S5-10-THANG-20261105/03-auth-offline-network-error.png`; widget tests | Offline case **PASS**; credential-invalid riêng chưa ép trên project thật |
| Auth/Firestore | Đăng nhập thành công nhưng profile lỗi | Mở recovery, cho retry hoặc sign-out; không báo nhầm cancel | Fake service + widget tests | Chưa ép lỗi profile trên project thật |
| Storage | Hủy upload | Hủy thật, file PDF local còn, có thể retry | Storage Emulator: `evidence/storage/S4-11-emulator-20261102/03-upload-cancelled.png`; unit/widget tests | Project thật chưa có Storage theo DEC-01 |
| Storage | Rules từ chối | Hiện permission denied và nút retry | Storage Emulator: `06-upload-denied.png`; 14 rules tests | Chưa xác minh Console/project thật |
| FCM | Từ chối quyền notification | Ngày 05/11 người dùng chọn Don't allow; hệ thống xác nhận `granted=false`, app vẫn chạy và Profile giải thích cách bật lại | Manual AVD: `evidence/auth/S3-2-S5-10-THANG-20261105/02-fcm-permission-denied-profile.png`; widget tests | **Manual PASS**; quyền đã được grant lại sau test |
| FCM | Tin đến khi phiên kết thúc | Snackbar/tác vụ cũ bị loại; không rò sang user kế tiếp | Widget/unit tests; evidence thiết bị ngày 03/11 | A→B và A→logout→A chưa kiểm thủ công trên máy Thắng |
| Analytics | Không có mạng khi log event | Code không chặn luồng nghiệp vụ; login/logout đã thấy trên DebugView | Implementation review + DebugView `evidence/analytics/S5-4-debugview-20261102/` | Chưa kiểm offline→online delivery; `export_report` chưa có DebugView thật |
| Crashlytics | Người dùng hủy test crash | Ngày 04/11 mở dialog rồi hủy; app trở về Profile và tiến trình vẫn chạy | Manual AVD: `evidence/failure-cases/S5-10-THANG-20261104/02-crash-cancel-dialog.png`, `03-crash-cancelled-app-stable.png`; widget test | Case hủy đã pass; vẫn cần non-fatal từ luồng thật và dashboard có user ID/custom key |
| Crashlytics | Xác nhận test crash | Crash đã lên Console project thật | `evidence/crashlytics/S4-13-test-crash-20261102/` | Cần hoàn thiện non-fatal failure evidence |
| Remote Config | Fetch không áp dụng giá trị mới / lỗi | Ngày 04/11 tắt Wi-Fi/mobile data; refresh giữ giá trị hiện tại và hiện thông báo không tải được, không báo thành công giả | Manual AVD: `evidence/failure-cases/S5-10-THANG-20261104/01-remote-config-offline.png`; widget tests | Offline case đã pass; chưa đổi ≥2 giá trị trên Console |

## Điều kiện đóng S5-10

- Chạy thủ công trên Android ít nhất một failure case cho từng dịch vụ trong sáu
  dịch vụ: Auth, Storage, FCM, Analytics, Crashlytics và Remote Config.
- Ghi observed result, thời gian, build/commit và evidence path; không thay bằng
  expected result hoặc fake test.
- Storage project thật/DEC-01, Firebase SHA của máy Thắng và Remote Config Console
  vẫn là blockers bên ngoài bảng kiểm thử tự động hiện có.
- Lượt 04/11 đã manual-pass Remote Config offline và Crashlytics cancel; xem
  [`evidence/failure-cases/S5-10-THANG-20261104/`](../evidence/failure-cases/S5-10-THANG-20261104/).
- Lượt 05/11 đã manual-pass fresh Google Sign-In, Auth cancel, Auth offline và
  FCM permission-denied; xem
  [`evidence/auth/S3-2-S5-10-THANG-20261105/`](../evidence/auth/S3-2-S5-10-THANG-20261105/).
