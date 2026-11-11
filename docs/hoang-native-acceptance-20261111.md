# Hoàng — Nghiệm thu thật trên Samsung A15 (11/11/2026)

**Thiết bị:** Galaxy A15 SM-A155F, Android 16; ứng dụng Longvita trên tài khoản user đã đăng nhập. QA thao tác và chụp ảnh thật qua ADB. Không dùng công thức mock.

## Kết quả đã quan sát

| Luồng | Quan sát thực tế | Bằng chứng | Giới hạn |
| --- | --- | --- | --- |
| HD-04 Inbox | Màn Trang chủ hiển thị thông báo CM-07 có nội dung được khai là tạo từ Web Admin | evidence/hoang/android-a15-20261111/inbox-web-admin-notification-no-pii.png | Chưa gửi/đo realtime một thông báo mới |
| S02 | Tùy chọn tuổi, cân nặng và số bữa hiển thị tiếng Việt | s02-options-no-pii.png | Không chứng minh dữ liệu dinh dưỡng y khoa |
| S03 | Lựa chọn tạo thực đơn, CTA hoạt động | s03-setup-no-pii.png | Chưa thử offline trên máy |
| S04 | Tạo được thực đơn tuần từ recipe hệ thống với sourceNote và ngày; phát hiện tên món dài/nhãn Đang chờ chen nhau | s04-generated-preview-before-polish.png | Ảnh trước khi sửa UI |
| S05 | Xem được chi tiết món, danh sách nguyên liệu và cách làm | Ảnh raw s05_real.png/s05_bottom.png chỉ ở ổ D | Nhãn tiếng Anh và row cố định đã sửa trong code sau đó |
| S06 | Không có món thay thế, Empty State và Retry hiển thị | s06-empty-and-retry.png | Không bịa món thay thế |
| S06→S02 | Bấm Điều chỉnh sở thích thành công trở lại S02 | s06-recovery-to-s02-no-pii.png | Xác minh navigation thực |
| S04 Save | Client báo “Đã lưu kế hoạch lên Firestore”, CTA chuyển thành “Lưu thay đổi” | firestore-save-confirmation.png | Chưa có S10 read-back riêng sau app restart |

## Sửa lỗi sau khi kiểm tra thiết bị

1. S04: bỏ nhãn Đang chờ thiếu ngữ nghĩa thẩm định gắn vào từng recipe và hạn chế chú giải nguồn chỉ 2 dòng (đọc nguồn đầy đủ tại S05). Không sửa trạng thái duyệt thật.
2. S05: Việt hóa Ingredients, Steps, serving, protein. Hàng nguyên liệu chiều cao linh hoạt, tên dài wrap và giá trị số nằm bên phải.
3. S02/S03: hiển thị đạm/ngày thay cho protein/ngày; thông báo S06 không còn từ recipes tiếng Anh.
4. Thêm 2 widget tests S04/S05 cho tên dài tại 360dp và scale chữ 200%.
5. Chỉnh 4 assertions A11y cũ theo chuỗi tiếng Việt mới; giữ nguyên điều kiện nghiêm ngặt và test lại đầy đủ.

## Kết quả kỹ thuật sau sửa

- Flutter Analyze: **0 vấn đề**.
- Flutter Test serial: **487/487 đạt** (cả 360/412dp và chữ 100/200%).
- Android APK debug: **build thành công**.
- Log thực thi tại D:\PRM393\hoang_a15_final_analyze_recheck.log, hoang_a15_final_fulltest_recheck.log, hoang_a15_final_apk_recheck.log.
- **Cập nhật 16:20:** Samsung A15 đã kết nối trở lại. Đã cài đè APK sau sửa qua ADB (install -r Success), mở thành công PID 28804, smoke logcat 0 dòng khớp FATAL EXCEPTION/E/flutter/FlutterError. Không xóa dữ liệu. Chưa có ảnh S04/S05 sau sửa; ảnh S04 cũ không chứng minh bản sửa trên điện thoại.

## Các điều kiện nghiệm thu vẫn còn thiếu

- S10 load lại plan thực sau app restart; S07/S08 edit/undo/checkbox persistence trên thiết bị; PDF offline từ plan thật và metadata.
- User gửi duyệt → Web Staff duyệt → Mobile nhận sự kiện, đo 3 lần; thông báo Web→Mobile mới và Analytics/Crashlytics console.
- ARTEMIS 3 lượt mỗi test: hiện thiếu daemon, key, test account trên máy Hoàng; không dùng unit tests thay cho kết quả ARTEMIS.
- Bộ recipe cần duyệt khoa học/nguồn/định lượng; Figma đối chiếu cả 10 màn; video 3 flows; team review/approval cho PR.

Không đánh dấu 26/26 task Lab3 hay HD-01..08 100% nếu chưa có các bằng chứng độc lập tương ứng.

## Cập nhật sau phép kiểm cuối lúc 16:30

S05 đã được bổ sung đoạn **Nguồn tham khảo** lấy nguyên văn trường sourceNote khi có nội dung. S04 chỉ cắt ngắn nguồn thành hai dòng trên thẻ, thông tin đầy đủ còn đọc được tại S05. Widget regression đã xác minh tên nguồn đầy đủ. Sau cập nhật: **Flutter Analyze 0 vấn đề, Flutter Test 487/487 đạt, Android APK debug build thành công**. Samsung A15 tạm mất kết nối ADB lúc kiểm tra cuối; phiên bản APK S05 mới nhất **chưa được cài và chụp lại**. Không coi ảnh S05 cũ là bằng chứng mới.
