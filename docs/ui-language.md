# Ngôn ngữ giao diện Longvita

Charlie xác nhận ngày 09/11/2026 đã thống nhất với nhóm: dùng **tiếng Việt cho toàn bộ UI Mobile và Web Admin**. Quyết định này thay mục DEC-05 trước đây còn chờ chốt. Figma Lab2 là mẫu bố cục/phong cách; chữ tiếng Anh trong mẫu không bắt buộc giữ nguyên trong app.

## Quy ước dùng chung

- Tiêu đề, mô tả, nút, điều hướng, hộp thoại, loading/empty/error, validation, snackbar và nhãn trợ năng viết tiếng Việt.
- Thanh điều hướng: **Trang chủ / Kế hoạch / Dinh dưỡng / Hồ sơ**. Dùng `AppNavigationBar.vietnameseDestinations` khi chuyển các màn còn lại.
- Giữ tên riêng như Longvita, Google, Firebase và PDF khi cần. Tên món/nguyên liệu trích từ dữ liệu nguồn không tự dịch hoặc ghi đè. Nhóm/đơn vị đã biết có thể ánh xạ phần hiển thị; không sửa giá trị lưu trên Firestore.
- Số lượng trong Flow 2 hiển thị dấu phẩy thập phân; editor nhận cả dấu chấm và dấu phẩy. Chỉ định dạng UI, không đổi giá trị số/đơn vị nguồn.
- Không dịch ID, key/schema, role/status lưu trong dữ liệu (`submitted`, `approved`, `user`...), route, tên event Analytics hoặc tên API. Chỉ dịch nhãn mà người dùng thấy.

## Phạm vi chuyển đổi hiện tại

Flow 2/S07/S08 được chuyển trong nhánh `feature/charlie-flow2-final-ui`. Các màn Mobile khác và WebAdmin được owner chuyển theo cùng quy ước; tài liệu này không khẳng định toàn bộ dự án đã Việt hóa xong.

`VietnameseUi` bổ sung Material/Cupertino/Widgets localizations của Flutter cho phần UI đã chuyển, gồm cả context-menu Overlay của ô nhập số. Việc áp dụng còn scoped ở Flow 2 trong gói này; khi cả app chuyển xong có thể cấu hình locale/delegates ở MaterialApp chung và gỡ các override không còn cần.

Flutter3.47.6 SDK yêu cầu intl ^0.20.3 cho flutter_localizations. Gói này thêm dependency SDK và ghim intl 0.20.3 trong cả pubspec.yaml/pubspec.lock; các hosted packages khác giữ nguyên. Theo [hướng dẫn Flutter chính thức](https://docs.flutter.dev/ui/internationalization).
