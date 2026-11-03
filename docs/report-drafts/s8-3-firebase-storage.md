# Nháp báo cáo S8-3 — Cloud Storage for Firebase

> Bản nháp của Charlie, gửi Thắng ghép ở S8-5. **Mọi bằng chứng chạy thật ở đây là trên Firebase Storage Emulator, không phải trên project thật.** Project `longvita-8da7e` đang dùng gói Spark và chưa có Storage bucket, vì quyết định DEC-01 (Storage cần gói Blaze) chưa chốt. Khi có Storage thật, cần deploy rules, chụp file trên Console (S4-15) và sửa phần 5 và 6.

## 1. Vai trò trong ứng dụng

Longvita cho người dùng xuất thực đơn thành file PDF có tiếng Việt và tải lên Cloud Storage, để có bản lưu trên cloud và một đường dẫn tải về. File nằm ở `reports/{uid}/{exportId}.pdf`, nên mỗi người dùng có một thư mục riêng, khớp với rules.

## 2. Luồng tích hợp

1. Người dùng bấm "Xuất báo cáo PDF" trên Profile. `ProfileViewModel` dựng PDF bằng `ReportService`, với font TTF tiếng Việt đi kèm app.
2. PDF được lưu trên máy trước, qua `LocalReportStore` (`reports/{uid}/{exportId}.pdf` trong thư mục ứng dụng). Việc ghi đi qua file tạm rồi đổi tên, nên nếu bị gián đoạn thì không để lại file dở.
3. `StorageService.uploadReportPdf` tải file lên bằng `putData` với `contentType: application/pdf`, báo tiến độ qua `snapshotEvents`, rồi lấy `getDownloadURL()`.
4. Profile hiện tiến độ, nút Hủy khi đang tải, và đường dẫn khi xong. File trên máy mở hoặc chia sẻ được qua `IReportViewer`.
5. Khi tải lên thành công, app gửi event Analytics `export_report` với dung lượng file.
6. Mỗi lúc chỉ chạy một lần xuất hoặc một lần thử lại, nên file, URL, tiến độ và trạng thái luôn thuộc cùng một lần xuất.

Giao diện không gọi Firebase SDK trực tiếp: `ProfileScreen` chỉ gọi `ProfileViewModel`, còn SDK nằm trong `StorageService`.

## 3. Xử lý lỗi

Mỗi lỗi của SDK được đổi thành một loại `UploadFailure`, và mỗi loại có thông báo riêng. Trong mọi trường hợp, PDF vẫn còn trên máy và có nút Thử lại.

| Tình huống | Hành vi | Trạng thái kiểm chứng |
|---|---|---|
| Mất mạng | Báo mất kết nối sau tối đa 60 giây (mặc định của SDK là 10 phút, trông như treo); không ghi lỗi lên Crashlytics vì đây không phải lỗi app | Emulator |
| Người dùng bấm Hủy | Báo đã hủy ngay. Khi mất mạng, SDK chỉ thật sự dừng ở lần thử lại kế tiếp, nên app báo trước và bỏ qua kết quả về sau | Emulator |
| Thử lại | Dùng lại cùng file và cùng export ID, không tạo file mới trên máy hay trên cloud | Emulator |
| Rules từ chối | Báo tài khoản chưa có quyền | Emulator (tạm bỏ quyền ghi trong rules, chỉ trên emulator) |
| Project chưa có bucket | Báo dịch vụ lưu trữ chưa sẵn sàng | Test bằng fake |
| Hết dung lượng | Báo dung lượng đã hết | Test bằng fake |
| Đăng xuất giữa lúc tải | Hủy upload, xóa PDF của người đó trên máy, về Sign-in. Bản đã lên cloud không bị xóa | Emulator |
| Kết quả về muộn sau khi đã đổi phiên | Bị bỏ qua, không lọt sang người dùng sau | Test bằng fake |

## 4. Bảo vệ dữ liệu

`firebase/storage.rules`: chỉ người đã đăng nhập mới đọc và ghi được trong `reports/{uid}/`, và `uid` phải trùng với tài khoản đang đăng nhập. Mọi đường dẫn khác bị từ chối.

Bộ test `firebase/tests/storage.rules.test.js` có 14 ca chạy trên Storage Emulator. Có các ca: A đọc, ghi, ghi đè, xóa file của mình; B không đọc, ghi hay xóa được file của A; chưa đăng nhập thì bị từ chối; không ghi được ở gốc hoặc ngay dưới `reports/`; một uid chỉ trùng phần đầu với uid khác không được quyền. Kết quả 14/14. Với rules mở toang, đúng 9 ca từ chối fail, cho thấy bộ test có tác dụng.

## 5. Kiểm thử

- **Chạy trên Storage Emulator** với app debug trên AVD Android 15, Firebase Auth thật và Storage SDK thật: tải lên thành công, mất mạng, hủy, thử lại, bị từ chối, đăng xuất giữa chừng.
- **Kiểm tra tự động:** test của `ProfileViewModel`, `ProfileScreen` và `LocalReportStore` phủ tiến độ, hủy, thử lại, từng loại lỗi, một lần xuất mỗi lúc và xóa file khi đăng xuất.
- **Rules:** `npm run test:rules` trong `firebase/`.

## 6. Bằng chứng

Thư mục `evidence/storage/S4-11-emulator-20261102/` (emulator):

- `01-upload-success.png`: có URL. File tải về trùng byte với file trên máy (SHA-256 trùng).
- `02`, `03`, `04`: mất mạng, hủy, thử lại khi vẫn mất mạng.
- `05-retry-success.png`: thử lại khi có mạng, số file trên máy không đổi.
- `06-upload-denied.png`: rules từ chối.
- `07-signed-out-during-upload.png`: đăng xuất giữa chừng, số PDF trên máy từ 9 về 0.
- `report-page-1.png`: trang PDF tải về.

Kết quả rules ở `evidence/rules/S3-7-20261102/`.

## 7. Giới hạn

- **Chưa có Storage trên project thật** (DEC-01): rules chưa deploy, chưa có file trên Console, `export_report` chưa thấy trên DebugView. Nếu nhóm quyết định không dùng Storage, cần leader chốt lại phạm vi các task S3-7, S4-11, S4-15.
- Không thấy được tiến độ tăng dần trên thiết bị vì file khoảng 19 KB tải xong gần như tức thì; phần này chỉ test bằng fake.
- PDF hiện dùng thực đơn thử, chưa phải thực đơn người dùng đang xem (chờ S4-3 và dữ liệu `recipes`).
- Xóa PDF trên máy khi đăng xuất là quyết định tạm nhóm đã đồng ý; cần chốt cho bản cuối.
- Mới chạy trên emulator Android 15, chưa thử máy thật.
