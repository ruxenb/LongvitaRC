# Worklog — Charlie (Phạm Văn Minh)

Task S8-17-CM. Ghi theo commit và evidence thật, cập nhật dần. Trạng thái nghiệm thu theo [bàn giao kỹ thuật](tasks/charlie-progress.md), không theo file này.

**Công cụ AI đã dùng:** Claude Code để viết code, test và báo cáo kỹ thuật; Codex để phân tích, review và tài liệu. Charlie quyết định phạm vi, duyệt các thao tác trên Firebase và GitHub, tự đăng nhập tài khoản Google khi test.

## 02/11/2026

### Design system (S2-3, S2-4) — `6dfddf9`

- **Đã làm:** tokens, theme, typography với font có license, 9 nhóm widget dùng chung và widget phụ.
- **Quyết định:** Figma Lab 2 là tham chiếu đóng băng, cải thiện UI trực tiếp trong code.
- **Kiểm tra:** QA test và ảnh ở 360/412dp, text scale, `test/qa/`.

### Firebase Auth và session (S3-3, S3-4, S3-5) — `56b1896`, `9d76623`

- **Đã làm:** bootstrap có màn lỗi và thử lại, Google Sign-in, kết quả đăng nhập có kiểu rõ ràng, profile recovery, dọn dữ liệu khi đăng xuất.
- **Quyết định:** lỗi đọc profile tách khỏi hủy đăng nhập. Xin quyền thông báo sau khi đăng nhập, không phải lúc mở app.
- **Sửa lỗi:** kết quả upload hoặc query về muộn có thể lọt vào phiên của user sau. Sửa bằng `SessionEpoch`, phủ cả trường hợp đăng nhập lại cùng user. Trước khi sửa 16 ca test fail.
- **Kiểm tra:** đăng nhập, hủy, mở lại, đăng xuất chạy thật với tài khoản của Charlie, xem `evidence/auth/S3-9-20261102/`.
- **Còn vướng:** chưa chạy A/B bằng hai tài khoản trên thiết bị; Hoàng chưa duyệt phần sửa trong ViewModel của Hoàng.

### Firebase project và Firestore rules (S0-4, S3-1, S3-9, AUD-11) — `4e4bffd`

- **Đã làm:** tạo project `longvita-8da7e`, app `vn.edu.fpt.longvita`, SHA máy Charlie, bật Google provider, tạo Firestore `asia-southeast1`, thêm plugin `google-services`.
- **Quyết định:** cấu hình qua Console vì `firebase login` trên terminal không chạy được, nên chưa có `firebase_options.dart`.
- **AUD-11:** sửa rules (không tự đổi role, khóa owner và status, kiểm tra data shape), publish lên project trước khi Hoàng, Thắng review vì phần này chưa ai bắt đầu. Cần hai bạn review và chốt B1–B5.
- **Kiểm tra:** 41/41 test emulator; rules cũ trượt 16 ca với cùng bộ test. Đọc profile và lưu plan nháp chạy thật với rules mới.

### Tích hợp `main` và Analytics (S5-4) — `cd82637`, `9ecc806`

- **Vấn đề:** `main` không biên dịch được vì API Analytics đổi nhưng caller chưa sửa.
- **Quyết định:** không gửi `generate_meal_plan` khi chưa có `eatingWindowHours`, thay vì điền số giả. `file_size_kb` lấy từ byte PDF thật.
- **Còn vướng:** chưa kiểm DebugView; cần màn S02 của Hoàng.

### FCM chuẩn bị (S4-12) — `7a9fa8c`, `2d547c7`

- **Đã làm:** 4 callback sau một gateway, parser có version, chống trùng, inbox theo từng user.
- **Sửa lỗi:** tin bị từ chối hoặc tin trùng ID có thể ghi đè nội dung tin đã nhận, do lưu ở hai nơi. Sửa bằng cách chỉ giữ một nơi lưu.
- **Kiểm tra:** chỉ bằng gateway giả. **Chưa có push thật.**
- **Còn vướng:** route, history, token và recipient chờ nhóm chốt.

### PDF chuẩn bị (S4-10) — `40e47a1`

- **Đã làm:** font tiếng Việt Regular/Bold, `LocalReportStore` lưu theo UID.
- **Quyết định:** dùng Roboto cho PDF vì thư viện `pdf` không chọn được độ đậm từ font biến thiên. Cần chốt với Hoàng.
- **Kiểm tra:** render fixture và xem ảnh. Chưa chứng minh đúng plan đang xem.

### Pull Request (S7-1-CM) — [PR #1](https://github.com/ruxenb/LongvitaRC/pull/1)

- Mở PR vào `main`. Chưa có output AI review.
- Tài liệu làm việc nội bộ giữ ở local, không đưa vào cây file chia sẻ.

### Lưu, mở và chia sẻ PDF (S4-10) — nhánh `feature/charlie-pdf-01`

- **Đã làm:** lưu PDF trên máy trước khi upload, export ID giữ nguyên khi thử lại, mở và chia sẻ qua service riêng dùng gói `printing` có sẵn.
- **Quyết định:** làm trên nhánh riêng để PR #1 không to thêm. Hai nút mở và chia sẻ đặt tạm trên Home để test được trên Android, sẽ chuyển sang Profile ở S4-13.
- **Lỗi tìm được khi chạy thật:** upload thất bại gây `Unhandled Exception` vì stream tiến độ không có xử lý lỗi. Test giả không phát hiện được. Đã sửa trong `StorageService` và chạy lại trên emulator.
- **Kiểm tra:** 150/150 test. Emulator: file được lưu, upload lỗi vẫn còn file, mở được màn xem trước, mở được cửa sổ chia sẻ.
- **Còn vướng:** chưa có plan thật từ S4-3; project chưa có Storage nên upload thành công chưa chạy thật; cần chốt chính sách giữ file.
