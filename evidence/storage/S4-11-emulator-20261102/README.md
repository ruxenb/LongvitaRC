# S4-11 — Upload PDF trên Storage Emulator, 02/11/2026

**Đây là bằng chứng trên emulator, không phải trên project thật.** Project `longvita-8da7e` chưa có Storage vì DEC-01 chưa chốt. Bằng chứng này không thay cho S4-15 (file trên Console).

Nhánh `feature/charlie-storage-01`. App debug chạy trên AVD `LocalMate_API_35` (320dp), dùng Firebase Storage SDK thật, Firebase Auth thật với tài khoản của Charlie, Storage Emulator trên máy. Ảnh có UID thật của Charlie trong URL.

## Kết quả

| # | Tình huống | Kết quả | Ảnh |
|---|---|---|---|
| 1 | Upload thành công | Có URL tải; file tải về trùng byte với file trên máy (SHA-256 `03fc7f655d399ab2…`) | `01-upload-success.png` |
| 2 | Upload khi tắt mạng | Hiện tiến độ 0% và nút Hủy | `02-upload-progress-offline.png` |
| 3 | Bấm Hủy khi tắt mạng | Báo đã hủy ngay, nút Thử lại xuất hiện, file còn trên máy | `03-upload-cancelled.png` |
| 4 | Thử lại khi vẫn tắt mạng | Sau khoảng 60 giây báo mất kết nối, không tạo file mới | `04-upload-offline-failed.png` |
| 5 | Thử lại khi có mạng | Có URL, số file trên máy không đổi | `05-retry-success.png` |
| 6 | Rules từ chối ghi | Báo chưa có quyền, có nút Thử lại | `06-upload-denied.png` |
| 7 | Đăng xuất giữa lúc upload | Về Sign-in, số PDF trên máy từ 9 về 0 | `07-signed-out-during-upload.png` |

Log thiết bị không có `Unhandled Exception` hoặc `FATAL EXCEPTION`.

`report-page-1.png` là trang PDF tải về từ emulator. PDF chỉ có một trang, phần ghi chú nằm ở chân trang.

## Tái lập

Trong `firebase/`:

```bash
npm run emulator:storage
```

Ở thư mục gốc repo:

```bash
flutter run --dart-define=STORAGE_EMULATOR_HOST=10.0.2.2
```

Tắt và bật mạng trên emulator:

```bash
adb shell svc wifi disable
adb shell svc data disable
```

## Cách kiểm tra

- Ca 6 tạm bỏ quyền ghi trong `firebase/storage.rules` rồi trả lại nguyên bản, chỉ trên emulator.
- Không chứng kiến được tiến độ tăng dần trên thiết bị: file 19 KB qua emulator xong gần như tức thì. Phần này có test bằng fake.

## Chưa kiểm chứng

- Upload lên project thật, rules đã deploy, file trên Console.
- Lỗi hết dung lượng và lỗi project chưa có bucket chỉ test bằng fake.
- Đăng xuất chỉ hủy upload và xóa file trên máy, không xóa bản đã lên Storage. Đây là chủ ý.
- Máy thật.

Kết quả `flutter analyze` và `flutter test` nằm cùng thư mục. Test rules ở [`evidence/rules/S3-7-20261102/`](../../rules/S3-7-20261102/).
