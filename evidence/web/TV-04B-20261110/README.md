# TV-04B Web Admin evidence index — 10/11/2026

Thư mục này là nơi nhận ảnh Web thật theo `docs/web-admin-checklist.md`.

## Bằng chứng production trên trình duyệt điện thoại

Phiên kiểm tra ngày 10/11/2026 mở
`https://longvita-8da7e.web.app` bằng trình duyệt Android ở chế độ portrait.
Kích thước ảnh chụp là `922 × 2048` px. CSS viewport của phiên này **không được
ghi nhận**, nên ảnh chỉ là mobile-browser observation và không được dùng để xác
nhận ca bắt buộc `412 × 915`; cần chụp lại với viewport đã đo. Build Hosting
gần nhất đã được xác minh từ `main` commit `0cfe905`.

| File | Role/trạng thái | Kết quả |
|:---|:---|:---|
| `01-mobile-portrait-signin.png` | Chưa đăng nhập | Trang đăng nhập production tải thành công trên điện thoại. |
| `02-mobile-portrait-oauth-loading-popup-blocked.png` | OAuth loading + popup blocked | Có trạng thái chờ và thông báo popup bị chặn; ảnh này không chứng minh recovery hay login pass. Recovery sau hủy nằm ở ảnh 06. |
| `03-mobile-portrait-review-empty.png` | `admin`, Review Queue | Empty state và hướng dẫn xét duyệt hiển thị; bố cục dùng được nhưng hẹp. |
| `04-mobile-portrait-recipes-responsive-finding.png` | `admin`, Recipes data | Dữ liệu Firestore tải được nhưng tiêu đề xuống dòng và bảng bị cắt; đây là finding WEB-18. |
| `05-mobile-portrait-dashboard-data.png` | `admin`, Dashboard data | Ba metrics và phần biểu đồ tải từ Firestore; bố cục xếp dọc. |
| `06-mobile-portrait-signin-cancelled.png` | OAuth cancelled | Thông báo hủy đăng nhập và CTA thử lại hiển thị đúng. |
| `07-mobile-portrait-dashboard-data-1127.png` | `admin`, Dashboard data | Xác nhận lại ba metrics production; không thay thế desktop viewport chuẩn. |
| `08-mobile-portrait-recipes-overflow-1128.png` | `admin`, Recipes data | Xác nhận finding trước sửa: heading xuống dòng và nội dung bảng bị cắt ngang. |
| `09-mobile-portrait-review-empty-1128.png` | `admin`, Review Queue | Xác nhận empty state production; không chứng minh approve/reject. |
| `10-mobile-portrait-signin-1128.png` | Chưa đăng nhập | Trang đăng nhập production tải thành công. |
| `11-mobile-portrait-recipe-create-form.png` | `admin`, Create Recipe | Form tạo công thức mở trên production; không chứng minh Save thành công. |
| `12-mobile-portrait-recipe-edit-form.png` | `admin`, Edit Recipe | Form sửa hiển thị dữ liệu hiện có; không chứng minh Save thành công. |
| `13-mobile-portrait-recipe-search.png` | `admin`, Recipes search | Từ khóa `gr` lọc danh sách còn một kết quả hiển thị. |
| `14-mobile-portrait-oauth-opening.png` | OAuth opening | Trạng thái đang mở tài khoản Google hiển thị; không chứa email. |
| `15-mobile-portrait-role-denied.png` | `user` không có quyền | Role gate production từ chối rõ ràng và cho phép đổi tài khoản. |
| `16-mobile-portrait-google-account-chooser-PII.png` | Google Account chooser | Chứng minh OAuth production mở được account chooser cho `longvita-8da7e.firebaseapp.com`. Ảnh chứa tên/email và chỉ được giữ theo xác nhận của owner; không tái sử dụng trong báo cáo/slide public nếu chưa che PII. |

Riêng file `16-mobile-portrait-google-account-chooser-PII.png` chứa tên/email
tài khoản và được đưa vào evidence theo xác nhận trực tiếp của owner. Các file
còn lại không chứa UID, token hoặc email. Không đưa file 16 vào báo cáo, slide,
video hoặc kho public nếu chưa che PII. Đây là Web Admin chạy trong trình duyệt
điện thoại, không phải ứng dụng Flutter Mobile native.

## Đã xác minh trước đó

- Checklist WEB-01..18 đã được định nghĩa, gồm role gate, bốn states, hành động
  chính, responsive, Remote Config, Analytics, Announcement và Hosting.
- Sau sửa review PR #25: 21/21 test trong `test/admin/admin_web_test.dart` và
  `test/admin/pr25_integration_test.dart` pass.
- `e2e_test/conftest.py` và `e2e_test/test_auth.py` compile sạch sau khi loại
  marker `Longvita` dùng chung giữa Sign-in và Home.

## Trạng thái checklist được ảnh hỗ trợ

- WEB-01: **Pass production trên mobile cho việc mở OAuth** — có Sign-in, trạng
  thái loading, account chooser và cancellation. Ảnh account chooser chứa PII;
  bộ evidence chưa chứng minh toàn bộ lần đăng nhập mới từ đầu đến Dashboard.
- WEB-02: **Pass một phần** — admin vào được Dashboard/Recipes/Review Queue;
  staff chưa được kiểm tra production. Role gate chi tiết nằm ở evidence TV-00.
- WEB-03: **Pass production trên mobile** — tài khoản không có role phù hợp bị
  từ chối rõ ràng; ảnh evidence không chứa email.
- WEB-06: **Pass một phần** — production hiển thị recipe data, search và form
  create/edit; chưa có bằng chứng Save thành công, archive/restore hoặc lỗi ghi.
- WEB-08: **Pass empty state** — Review Queue không có thực đơn chờ duyệt.
- WEB-12: **Pass data đại diện** — Dashboard có dữ liệu; loading/empty/error
  riêng vẫn chưa đủ ảnh.
- WEB-13: **Pass một phần** — ba Dashboard metrics hiển thị; chưa kiểm đủ chart
  tại `1440 × 900` và `412 × 915`.
- WEB-18: **Fail mobile-width** — Recipes overflow/cắt nội dung và heading xuống
  dòng bất thường. Cần sửa rồi chụp lại với CSS viewport đã ghi nhận.
- WEB-17: **Pass một phần** — URL mở trên mobile browser và có bằng chứng ẩn
  danh desktop tại [`../TV-00-20261110/`](../TV-00-20261110/README.md), nhưng
  chưa có evidence reload một SPA route trên production.

## Còn thiếu

- Chưa có ảnh tạo/sửa/archive/restore công thức thành công.
- Chưa có item Review Queue thật để approve/reject và đo cross-role.
- Chưa có đủ bốn trạng thái Dashboard.
- Chưa có DebugView thật hoặc Remote Config toggle thật.
- Announcement Form có trong source và test local nhưng chưa có ảnh production
  hoặc kết quả Mobile inbox trong bộ evidence này; không ghi là đã deploy.
- Chưa ghi production Firestore.

## Sửa WEB-18 trong source ngày 11/11/2026

- `RecipeManagementScreen` chuyển sang danh sách card khi content width dưới
  720 px; desktop tiếp tục dùng DataTable đầy đủ.
- Header chuyển action xuống dòng khi content width dưới 560 px; padding trang
  Recipes giảm từ 32 px xuống 16 px ở chế độ compact.
- Bổ sung widget test tại viewport `412 × 915`, xác nhận compact list xuất hiện,
  desktop table không render và không phát sinh Flutter exception/overflow.
- Kiểm chứng local: `flutter analyze` sạch; 27/27 test trong
  `admin_web_test.dart` và `pr25_integration_test.dart` pass; Web release build
  thành công, Wasm dry run thành công. Lượt kiểm tra toàn package Web sau đó đạt
  69/69 test, gồm cả Auth và Announcement.

Kết quả trên là kiểm chứng source/local. WEB-18 vẫn cần người kiểm thử mở bản
deploy production sau lần release kế tiếp và chụp lại viewport CSS `412 × 915`;
ảnh finding số 04 được giữ làm bằng chứng trước sửa.

Mỗi ảnh bổ sung phải ghi commit SHA, môi trường, role, viewport và bước tái
hiện; không lưu email, UID hoặc token.
