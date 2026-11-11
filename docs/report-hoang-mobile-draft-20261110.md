# CHƯƠNG 1 — HOÀN THIỆN MOBILE LONGVITA (BẢN THẢO HOÀNG)

**PRM393 Final Assignment — 10/11/2026.** Phạm vi: thành viên Hoàng DV, Mobile App, 10 màn hình Lab 2/3, ba luồng nghiệp vụ và giao diện Việt hóa. Bản thảo để nhóm tổng hợp, không thay thế minh chứng chạy trên Android/Firebase thật.

## 1. Cấu trúc và thay đổi so với Lab 3
Ứng dụng Flutter tổ chức Model — ViewModel — Screen. Model ở lib/models, hợp đồng DataService ở lib/services/i_data_service.dart, implementation ở lib/services/data_service.dart, trạng thái tải/rỗng/lỗi/thành công ở ViewModel. Dữ liệu nghiệp vụ được đọc từ Cloud Firestore. Không dùng recipe giả làm dữ liệu production.

Trang chủ có lối vào lập thực đơn, kế hoạch đã lưu, nguyên liệu mua sắm, hộp thư thông báo và hồ sơ. Các màn hình dùng design tokens và component tái sử dụng; nút, nhãn, trạng thái và thông báo cố gắng nhất quán tiếng Việt. Các lệch so với Figma phải được ghi tại docs/design-traceability.md và kiểm tra lại bằng ảnh thiết bị.

## 2. Ba luồng giao diện
**Luồng 1:** S01 → S02 sở thích, S03 lập thực đơn, S04 hiển thị bảy ngày và S10 lưu/mở thực đơn. Nếu Firestore chưa có công thức, hệ thống hiện trạng thái rỗng thay vì tự tạo món giả. Lỗi ghi cho phép thử lại và vẫn giữ thực đơn trên màn hình.

**Luồng 2:** S04 → S07 tổng hợp nguyên liệu → S08 checklist mua sắm. Có chỉnh lượng với validation dương, xóa/hoàn tác và lưu trạng thái đã mua theo UID, ID thực đơn.

**Luồng 3:** S04 → S05 chi tiết → S06 món thay thế hoặc S09 kiến thức trích dẫn → quay lại S04. Chỉ hiển thị trích dẫn thực sự có trong nguồn, giữ món gốc nếu lỗi cập nhật.

## 3. Quy trình xét duyệt liên vai trò
Người dùng chỉ được gửi thực đơn đã lưu, đủ bảy ngày, còn là bản nháp và thuộc tài khoản đang đăng nhập. Trạng thái máy chủ đi từ draft → submitted → approved/rejected, còn giao diện hiển thị nhãn tiếng Việt. Chỉ cập nhật trạng thái sau khi Firestore xác nhận; khi lỗi giữ nguyên nội dung và cho phép thử lại. Subscription Firestore cập nhật kết quả xét duyệt ngay trên màn hình, không chép đè các món vừa chỉnh; listener cũ được hủy khi đổi tài khoản hoặc thoát phiên.

## 4. Testing và khả năng truy cập
Đã chạy Flutter Analyze không cảnh báo và Flutter Test 484/484 đạt trong môi trường Windows ngày 10/11/2026. Bộ kiểm thử bao gồm xử lý race giữa các phiên, gửi/duyệt thất bại rồi thử lại, cập nhật stream, 360/412 dp và phóng chữ 200%. Riêng bộ chọn S04 đã được mở rộng chiều cao theo text scale để tránh RenderFlex overflow. Nhật ký thực thi lưu ngoài repo tại D:\PRM393\hoang_final_analyze_20261110.log và D:\PRM393\hoang_final_tests_20261110.log.

## 5. Bài học kinh nghiệm
1. Không coi trạng thái UI là xác nhận ghi Firestore; cần tách pending/confirmed.
2. Không dùng dữ liệu fake để chứng minh yêu cầu nguồn dinh dưỡng production.
3. Race logout/sign-in cần xác thực UID, dừng subscription và kiểm tra kết quả async muộn.
4. Giao diện tốt ở 100% chữ không đủ chứng minh hỗ trợ phóng chữ 200%.
5. Unit/widget test không thay thế thử nghiệm Firebase thực tế, ảnh Android và ARTEMIS.

## 6. Bằng chứng còn thiếu
Android SDK platform chưa cài hoàn chỉnh; không có lượt ARTEMIS tối thiểu ba lần, video demo trên thiết bị, đối chiếu pixel Figma toàn bộ màn hình, Firebase cross-role live và minh chứng DebugView/Crashlytics. Chưa thể khẳng định dinh dưỡng của mọi recipe an toàn hoặc chính xác cho từng đối tượng chỉ từ Firestore. Các mục này vẫn phải nghiệm thu trước khi tuyên bố hoàn thành 100%.

**Nguồn review và thay đổi:** docs/hoang-hd05-figma-acceptance-20261110.md, docs/hoang-vi-figma-20261110.md, PR #29.