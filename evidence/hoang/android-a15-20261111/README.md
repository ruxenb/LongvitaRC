# Bằng chứng Android thật — không có PII

Ngày 11/11/2026, Samsung Galaxy A15 SM-A155F, Android 16.

- profile-vietnamese-no-pii.png: ảnh thật sau clean build và cài APK. Đã **cắt hoàn toàn vùng tên, email và ảnh đại diện**. Thể hiện tiêu đề Tiện ích Firebase, PDF ở trạng thái chưa có thực đơn và hòm thư rỗng.
- Flutter Analyze 0 vấn đề, Flutter Test 483/483 đạt, APK build và adb install -r thành công; log gốc chỉ lưu trên máy tính cá nhân.
- Chỉ chứng minh hiển thị; không chứng minh PDF đã xuất, inbox realtime, recipe đã kiểm duyệt hoặc luồng liên vai trò.

Không đưa ảnh gốc chứa thông tin tài khoản và secret lên Git.


## Bằng chứng Native QA mới (11/11/2026)

Ảnh đã cắt vùng chứa danh tính và lưu trong thư mục này:
- s02-options-no-pii.png: màn S02 thực
- s03-setup-no-pii.png: màn S03 thực
- s04-generated-preview-before-polish.png: thực đơn tạo từ dữ liệu hệ thống, **ảnh trước sửa bố cục**
- s06-empty-and-retry.png: trạng thái không có món thay thế
- s06-recovery-to-s02-no-pii.png: nhánh trở lại tùy chọn
- firestore-save-confirmation.png: phản hồi đã lưu kế hoạch lên Firestore từ client
- inbox-web-admin-notification-no-pii.png: thông báo cũ từ Web, chưa đo thông báo realtime mới

Raw ảnh chứa thông tin cá nhân không đẩy GitHub. Lượt sửa S04/S05 gần nhất chưa có ảnh native mới vì ADB mất kết nối, dù 487/487 Flutter tests đã đạt.

## Nghiệm thu thiết bị thật bổ sung ngày 11/11/2026 (17:02–17:30)

Samsung A15 SM-A155F, Android 16, ADB đã xác thực. Cài lại APK giữ dữ liệu (install -r Success). Ảnh đã cắt vùng tên, email và status bar; S10 che cân nặng. Ảnh raw lưu riêng ở D:\PRM393\Longvita_phone_evidence, không đưa lên Git.

| Ảnh (file native-*.png) | Nội dung |
| --- | --- |
| native-s10-reopen-redacted.png | S10 sau cai lai: ban nhap ngay 11/11, 7 ngay, da che can nang |
| native-s04-after-merge.png | S04: ngay, ten mon, kcal, dam, nguon tom tat |
| native-s05-full-source.png | S05: toan van nguon va danh sach nguyen lieu |
| native-s07-ingredients.png | S07: nguyen lieu gop va nut chinh sua |
| native-s07-zero-blocked.png | S07: so luong 0 bi chan bang loi tieng Viet |
| native-s07-valid-1361.png | S07: 1360 g thanh 1361 g, ung dung xac nhan luu |
| native-s07-valid-persisted.png | S07: 1361 g van con sau dieu huong |
| native-s07-original-restored.png | S07: luu lai 1360 g nhu ban dau |
| native-s08-unchecked.png | S08: truoc danh dau |
| native-s08-checked.png | S08: danh dau mot nguyen lieu |
| native-s08-reopened-checked.png | S08: dau kiem con sau khi roi va vao lai |
| native-s08-restored.png | S08: tra trang thai ban dau |
| native-pdf-export-success.png | Profile: app bao da luu PDF va dong bo bao cao |

Quan sát bổ sung ngoài ảnh: Android Print Preview mở PDF thực đơn 7 ngày dài 2 trang; ảnh raw không commit vì chứa dữ liệu hồ sơ. Những kết quả này là QA ứng dụng thật, không được gộp vào ARTEMIS 3 lượt/ca hay phê duyệt nguồn nutrition.

## S09 và bản main mới (17:38 ngày 11/11)

- native-s09-book-knowledge.png: ảnh Android thật đã cắt status bar. S09 hiện tiêu đề Kiến thức sách, các nguyên tắc giàu thực vật, đạm, dầu ô liu, cá ít thủy ngân; phần Nguồn tham khảo ghi rõ URL nguồn và cảnh báo ước tính USDA.
- App đã được cài lại với APK build từ main 95b1c31, giữ dữ liệu. Mobile/Core/Web Analyze không lỗi, Flutter Test tổng 576/576 đạt và build APK debug đạt.
- Trang tra cứu trên thiết bị đang trả 2 công thức thực từ môi trường Firebase. Commit catalog 29 công thức trên main không đồng nghĩa toàn bộ đã được phê duyệt/seed lên collection thật.
