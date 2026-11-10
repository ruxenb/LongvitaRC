# TV-04B Web Admin evidence index — 10/11/2026

Thư mục này là nơi nhận ảnh Web thật theo `docs/web-admin-checklist.md`.

## Bằng chứng production trên trình duyệt điện thoại

Phiên kiểm tra ngày 10/11/2026 mở
`https://longvita-8da7e.web.app` bằng trình duyệt Android ở chế độ portrait.
Kích thước ảnh chụp là `922 × 2048` px; không suy kích thước pixel ảnh thành CSS
viewport vì thiết bị có device-pixel ratio riêng. Build Hosting gần nhất đã
được xác minh từ `main` commit `0cfe905`.

| File | Role/trạng thái | Kết quả |
|:---|:---|:---|
| `01-mobile-portrait-signin.png` | Chưa đăng nhập | Trang đăng nhập production tải thành công trên điện thoại. |
| `02-mobile-portrait-oauth-loading-popup-blocked.png` | OAuth loading/error | Có trạng thái chờ rõ ràng; trình duyệt báo chặn popup nên đây là bằng chứng recovery, không phải login pass. |
| `03-mobile-portrait-review-empty.png` | `admin`, Review Queue | Empty state và hướng dẫn xét duyệt hiển thị; bố cục dùng được nhưng hẹp. |
| `04-mobile-portrait-recipes-responsive-finding.png` | `admin`, Recipes data | Dữ liệu Firestore tải được nhưng tiêu đề xuống dòng và bảng bị cắt; WEB-13/18 fail ở mobile width. |
| `05-mobile-portrait-dashboard-data.png` | `admin`, Dashboard data | Ba metrics và phần biểu đồ tải từ Firestore; bố cục xếp dọc. |
| `06-mobile-portrait-signin-cancelled.png` | OAuth cancelled | Thông báo hủy đăng nhập và CTA thử lại hiển thị đúng. |

Ảnh account chooser có email đã **không được commit**. Các ảnh trong thư mục
không chứa UID, token hoặc email. Đây là Web Admin chạy trong trình duyệt điện
thoại, không phải ứng dụng Flutter Mobile native.

## Đã xác minh trước đó

- Checklist WEB-01..18 đã được định nghĩa, gồm role gate, bốn states, hành động
  chính, responsive, Remote Config, Analytics, Announcement và Hosting.
- Sau sửa review PR #25: 21/21 test trong `test/admin/admin_web_test.dart` và
  `test/admin/pr25_integration_test.dart` pass.
- `e2e_test/conftest.py` và `e2e_test/test_auth.py` compile sạch sau khi loại
  marker `Longvita` dùng chung giữa Sign-in và Home.

## Trạng thái checklist được ảnh hỗ trợ

- WEB-01: **Pass một phần** — có Sign-in, OAuth loading và cancellation; popup
  bị trình duyệt chặn trong một lượt.
- WEB-02: **Pass production** — admin vào được Dashboard/Recipes/Review Queue;
  role gate chi tiết nằm ở evidence TV-00.
- WEB-08: **Pass empty state** — Review Queue không có thực đơn chờ duyệt.
- WEB-12: **Pass data đại diện** — Dashboard có dữ liệu; loading/empty/error
  riêng vẫn chưa đủ ảnh.
- WEB-13 và WEB-18: **Fail mobile-width** — Recipes overflow/cắt nội dung và
  heading xuống dòng bất thường. Cần sửa responsive rồi chụp lại.
- WEB-17: **Pass URL trên mobile browser**; bằng chứng ẩn danh desktop nằm ở
  [`../TV-00-20261110/`](../TV-00-20261110/README.md).

## Còn thiếu

- Chưa có ảnh tạo/sửa/archive/restore công thức thành công.
- Chưa có item Review Queue thật để approve/reject và đo cross-role.
- Chưa có đủ bốn trạng thái Dashboard.
- Chưa có DebugView thật hoặc Remote Config toggle thật.
- Announcement Form đã merge qua PR #34 nhưng chưa có ảnh production trong bộ
  evidence này.
- Chưa ghi production Firestore.

Mỗi ảnh bổ sung phải ghi commit SHA, môi trường, role, viewport và bước tái
hiện; không lưu email, UID hoặc token.
