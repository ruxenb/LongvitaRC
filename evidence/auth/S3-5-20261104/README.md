# S3-5 — Đăng xuất và cách ly phiên, 04/11/2026

- **Code:** `main` `96c9f57` (sau khi merge PR #9). Đợt này không đổi code: không tái hiện được lỗi nào.
- **Thiết bị:** AVD `LocalMate_API_35`, Android 15.
- **Bản build:** debug, app thật (entrypoint `lib/main.dart`), build với `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2`. Xuất PDF tải lên Firebase Storage Emulator trên máy, không lên Storage thật. Không dùng QA host Sign-in của S4-14.
- **Tài khoản:** hai tài khoản Google thật trên cùng emulator. Charlie tự đăng nhập; không có mật khẩu hay token nào trong evidence.
  - **A:** `minhpvse183365@fpt.edu.vn`, UID `vFIifNJKUcfOvrOVqoZL3m85diu2`.
  - **B:** tài khoản Gmail cá nhân của Charlie, UID `k6sBvDYQ7oXW2hy4ddJdhGz0Qh93`. Email B đã được làm mờ trong ảnh 08, 09, 12. Quyết định giữ email trong evidence ngày 02/11 chỉ nói về tài khoản trường.
- **Cách kiểm file:** liệt kê `app_flutter/reports/` và `app_flutter/notifications/` bằng `adb shell run-as vn.edu.fpt.longvita ls` (được vì là bản debug). Chỉ xem tên và kích thước file; không xóa tay, không reset dữ liệu app.

## Marker

| Phiên | Marker |
|---|---|
| A | Thực đơn mẫu; export `plan_1793726751351` cùng URL Storage Emulator trên màn; 7 PDF cũ trên máy (tổng 8); hộp thư có tin "ARTEMIS TC10 review", "ARTEMIS TC10 lan 2"…; lịch sử `notifications/vFIif….json` 2601 byte |
| B | Hộp thư trống; lịch sử `notifications/k6sB….json` là `[]`; export `plan_1793727154298` |

## Kết quả

| # | Ca | Ảnh | Thực tế | Kỳ vọng |
|:-:|---|---|---|---|
| 1 | A: Profile → Đăng xuất → **Hủy** | 03, 04 | Vẫn A, export và URL vẫn hiện, 8 PDF vẫn trên máy | Đạt |
| 2 | A: Profile → Đăng xuất → **Đồng ý** | 05 | Về Sign-in. `reports/vFIif…/` hết 8 PDF. `notifications/vFIif….json` còn nguyên. Bản cloud `reports/vFIif…/plan_1793726751351.pdf` trên Storage Emulator vẫn tải được, bắt đầu bằng `%PDF-` | Đạt |
| 3 | **Back** sau khi đăng xuất | 06 | Về launcher (NexusLauncher), không vào Home hay Profile | Đạt |
| 4 | **Tắt hẳn (force-stop) rồi mở lại** sau khi đăng xuất | 07 | Vẫn ở Sign-in, không tự khôi phục phiên | Đạt |
| 5 | A → đăng xuất → **B** | 08, 09, 10 | B thấy "Chưa có thực đơn để xuất", không URL, không export, hộp thư "Chưa có thông báo nào.". Duyệt hết Profile của B không thấy marker nào của A (tên, email, UID, tin ARTEMIS, export) | Đạt |
| 6 | B đăng xuất **từ Home** | 11, 12, 13 | Nút Đăng xuất của Home đăng xuất ngay, không hỏi xác nhận (thiết kế hiện có, không đổi). Về Sign-in. `plan_1793727154298` của B bị xóa khỏi máy; lịch sử của cả A và B vẫn giữ | Đạt |
| 7 | B → đăng xuất → **A** (cùng UID A đăng nhập lại) | 14, 15, 16 | A thấy "Chưa có thực đơn để xuất", không URL hay export cũ, `reports/` trống. Hộp thư hiện lại tin của A từ lịch sử trên máy (file vẫn 2601 byte) | Đạt. Khôi phục lịch sử của chính A là đúng contract tạm, không phải state cũ chưa dọn |

## Dữ liệu khi kết thúc phiên

| Dữ liệu | Hành vi hiện tại | Đã kiểm | Trạng thái quyết định |
|---|---|---|---|
| Thực đơn, danh sách đã lưu, trạng thái tạo (MealPlan VM) | Xóa khỏi RAM; kết quả async muộn bị bỏ qua (`SessionEpoch`) | Native ca 5, 7; test `session_isolation`, `session_race` (PM-S3-5-02) | Code A3 của Hoàng, **chờ Hoàng duyệt** |
| Nguyên liệu và bộ nhớ Undo (Ingredient VM) | Xóa khỏi RAM (đồng bộ, không có việc async) | Test `session_isolation` (`canUndo` false) | Code A3 của Hoàng, **chờ Hoàng duyệt** |
| Export, URL, tiến trình, upload đang chạy (Profile VM) | Xóa khỏi RAM; yêu cầu hủy upload; kết quả, tiến trình, lỗi muộn bị bỏ qua | Native ca 2, 5, 7; test `session_race` (PM-S3-5-01), `profile_export` | Đã chốt |
| PDF trên máy `app_flutter/reports/<uid>/` | **Xóa** cả thư mục của UID vừa đăng xuất; thư mục UID khác và ngoài `reports/` không đụng | Native ca 2, 6; test `report_service` (`deleteAll` chỉ xóa UID đó, chặn path traversal) | Có trong code; **chính sách lưu giữ PDF còn chờ nhóm chốt** |
| Bản PDF trên Cloud Storage | **Giữ** | Native ca 2 (Storage Emulator) | Đã chốt: đăng xuất không xóa dữ liệu cloud |
| Hộp thư thông báo trong RAM, tin vừa đến, yêu cầu mở | Xóa khỏi RAM | Native ca 5; test FCM, PM-FCM-02 | Đã chốt |
| Lịch sử thông báo `app_flutter/notifications/<uid>.json` | **Giữ trên máy theo UID**; người sau chỉ tải file của mình | Native ca 2, 5, 6, 7 | Contract tạm của nhóm |
| Tin đến lúc chưa ai đăng nhập (không có `recipient_uid`) | Giữ lại rồi giao cho người đăng nhập kế tiếp; tin có `recipient_uid` khác bị loại | Test FCM | **Câu hỏi mở của An/Thắng**, S3-5 không quyết |
| Analytics user ID, Crashlytics user ID và `user_role` | Reset khi kết thúc phiên | Test `auth_viewmodel` (fake). Chưa xem trên DebugView/Crashlytics Console | Đã chốt |
| Phiên Firebase/Google | `signOut` của Google (lỗi thì bỏ qua) rồi của Firebase | Native ca 2–4 | Đã chốt |

Câu task gốc ghi "xóa toàn bộ dữ liệu người dùng cục bộ". Hiện tại lịch sử thông báo được giữ theo contract tạm, và chính sách PDF còn chờ chốt. Vì vậy S3-5 chưa đạt nguyên văn câu đó.

## Phân biệt các hành vi bất đồng bộ

- **Gọi hủy upload:** `clearSession` gọi `cancelActiveUpload()` nếu đang tải lên. Khi mạng chậm, SDK có thể chỉ dừng ở lần thử lại kế tiếp.
- **SDK xác nhận hủy:** không chờ. Nếu upload cũ vẫn hoàn tất, bản cloud nằm dưới `reports/<uid cũ>/`, vẫn là dữ liệu của chính người đó.
- **Vô hiệu hóa kết quả:** mọi kết quả, tiến trình và lỗi muộn của phiên cũ bị bỏ qua nhờ `_activeOperation` và `SessionEpoch`, kể cả khi cùng UID đăng nhập lại. Test: `session_race_test`.
- **Đăng xuất giữa lúc lưu PDF:** file vừa lưu bị xóa và upload không bắt đầu. Test: `profile_export_test` (`logout during save…`).

Native chỉ kiểm đăng xuất sau khi upload đã xong. Các race trên dùng test có điều khiển (fake), không phải bằng chứng native.

## Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 279/279 pass. Riêng `test/auth`, `test/fcm` và `test/report/profile_export_test.dart`: 148/148 pass.
- Không có test mới: không tìm thấy lỗi tái hiện được, và các ca trong ma trận đã có test.

## Giới hạn

- **SDK đăng xuất lỗi:** nếu `FirebaseAuth.signOut` ném lỗi, app vẫn dọn local và hiện Sign-in (test `sign-out SDK failure still clears local session`). Nhưng phiên Firebase có thể còn, nên lần mở app sau sẽ tự đăng nhập lại A. Trên máy không gây được lỗi này nên chưa kiểm native; đây là hành vi hiện có, ghi lại để PM biết.
- **Đăng xuất giữa lúc xuất/tải lên:** chưa thử native, chỉ có test.
- Analytics và Crashlytics user ID chưa xem trên Console.
- Chưa thử trên máy thật.
- **A3 của Hoàng chưa có duyệt:** các guard trong MealPlan/Ingredient VM do Charlie viết (PR #1). Không tìm thấy review hay comment của Hoàng trên GitHub. Merge hoặc CodeRabbit không được tính là Hoàng đã duyệt.
- **Quan sát, chưa tái hiện, chưa mở finding:** việc xóa thư mục PDF chạy nền (không chờ). Về lý thuyết, nếu cùng UID đăng nhập lại và xuất PDF trước khi việc xóa xong, file mới có thể bị xóa theo. Trên máy, đăng nhập Google mất vài giây còn việc xóa xong gần như ngay, nên không gặp.
