# S4-13 — Profile và Firebase Demo Area, 02/11/2026

Nhánh `feature/charlie-profile-01`, tách từ `main` tại `6f58786`. App `vn.edu.fpt.longvita`, project `longvita-8da7e`, AVD `LocalMate_API_35`, hiển thị 320×640 ở density 160 (320dp, hẹp hơn chuẩn 360dp), bản debug, textScale 1.0. Các ảnh có tên và email thật của Charlie.

| File | Nội dung |
|---|---|
| `01-profile-no-plan-top.png` | Danh tính, vai trò, Đăng xuất; chưa có thực đơn nên nút xuất bị khóa và có lý do |
| `02-profile-no-plan-scrolled.png` | Thông báo trống, giá trị Remote Config |
| `03-remote-config-refresh.png` | Bấm cập nhật Remote Config |
| `04-crash-confirm.png` | Hộp xác nhận trước khi gây crash thử |
| `05-export-upload-failed.png` | Upload lỗi (project chưa có Storage): có thông báo, Thử lại, Mở, Chia sẻ |
| `06-open-pdf-preview.png` | Màn xem trước PDF của hệ thống |
| `07-share-sheet.png` | Cửa sổ chia sẻ của Android với file PDF |
| `08-after-sign-out.png` | Đăng xuất từ Profile: về Sign-in, không còn Profile trong stack |
| `09-sign-in-after-cancel.png` | Hủy chọn tài khoản sau đó: về Sign-in |

## Kết quả chạy trên emulator

| Thao tác | Kết quả |
|---|---|
| Home → Hồ sơ → Quay lại | Mở Profile, Back về Home |
| Xuất PDF, upload lỗi | Số PDF trên máy từ 3 lên 4; có thông báo lỗi |
| Thử tải lên lại, lỗi tiếp | Vẫn 4 file, không tạo file mới |
| Hủy ở hộp xác nhận crash | App không crash, cùng PID |
| Đăng xuất từ Profile | Về Sign-in |
| Log | Không có `Unhandled Exception` hoặc `FATAL EXCEPTION` |

## Kiểm tra tự động

`test/profile/profile_screen_test.dart`, chạy với fake: các trạng thái xuất PDF, tiến độ, URL, hộp thư, quyền bị từ chối, Remote Config, xác nhận crash, không overflow ở 360dp, 412dp, 360dp với text scale 2, nhãn Semantics.

## Chưa kiểm chứng

- Upload thành công và URL thật: project chưa có Storage, chờ DEC-01. Trên thiết bị chưa thấy tiến độ và URL.
- Push thật vào hộp thư: mới dùng gateway giả.
- Bấm "Gây crash" thật và báo cáo trên Crashlytics Console: phần Crashlytics Gradle còn phối hợp Thái An.
- Remote Config đổi giá trị từ Console: bấm cập nhật báo đã áp dụng, nhưng giá trị hiển thị không đổi vì chưa sửa gì trên Console.
- TalkBack, máy thật, viewport 360×800 trên thiết bị.
- PDF đúng thực đơn đang xem: thực đơn thử vẫn từ màn Home, chờ S4-3.

## Khác biệt và điểm cần phối hợp

- Figma chưa có frame Profile (S1-5), nên bố cục ghép từ design system, chờ Hoàng và PM xem.
- Ở 320dp, email dài bị xuống dòng giữa từ.
- Khối xuất PDF tạm trên Home chưa gỡ, nên hiện có hai nơi xuất, dùng chung `ProfileViewModel`. Gỡ khi thống nhất với Hoàng.
- Mở Profile bằng `Navigator.push` từ một nút trên Home, chờ Thắng thêm route `/profile`.
- Bấm vào thông báo chưa điều hướng, chờ contract FCM.
