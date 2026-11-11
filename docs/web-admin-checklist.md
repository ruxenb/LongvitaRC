# TV-04B — Web Admin verification checklist

> **Cập nhật:** 10/11/2026
> **Owner thực thi:** Thắng VLQ
> **Người tổng duyệt test report:** Thái An
> **Trạng thái:** đã có Hosting và bộ ảnh production trên trình duyệt điện thoại
> cho sign-in/OAuth, role-denied, Dashboard, Recipes/search/create/edit UI và
> Review Queue empty. Ảnh phát hiện Recipes chưa đạt mobile-width; thao tác ghi
> dữ liệu thành công, Console evidence và desktop viewport chuẩn vẫn còn thiếu.

## 1. Quy tắc evidence

- Ảnh phải là UI chạy thật, không dùng ảnh AI tạo/chỉnh sửa.
- Không để lộ email, UID, token, URL có download token hoặc dữ liệu cá nhân.
- Tên file bắt đầu bằng số thứ tự, viewport và trạng thái, ví dụ
  `01-1440x900-dashboard-data.png`.
- Mỗi ảnh ghi commit SHA, URL/môi trường, role, viewport và thao tác tái hiện
  trong README của thư mục evidence.
- Local/emulator không được ghi là production; ảnh Hosting phải mở lại ở cửa
  sổ ẩn danh.

## 2. Ma trận kiểm tra

| ID | Màn hình/luồng | Ca cần chứng minh | Trạng thái hiện tại | Evidence cần bổ sung |
|---|---|---|---|---|
| WEB-01 | Sign-in | loading và popup Google | Pass production trên mobile cho việc mở OAuth: có loading, account chooser và cancel recovery; ảnh chooser chứa PII được owner cho phép lưu | Cần chuỗi evidence login mới hoàn chỉnh; che PII trước khi dùng công khai |
| WEB-02 | Role gate | `staff/admin` được vào | Admin pass production; staff chưa có tài khoản demo | Bổ sung staff khi nhóm cấp tài khoản |
| WEB-03 | Role gate | `user` bị từ chối rõ ràng | Pass production trên mobile: có màn hình từ chối, ảnh không lộ email | Kiểm tra lại sau deploy kế tiếp |
| WEB-04 | Recipes | loading | Có widget test | ảnh spinner/skeleton có kiểm soát |
| WEB-05 | Recipes | empty + CTA | Có widget state | ảnh collection/query rỗng an toàn |
| WEB-06 | Recipes | data/search/create/edit | Pass một phần production: có data, search result và form create/edit; chưa chứng minh Save thành công | ảnh kết quả ghi thành công |
| WEB-07 | Recipes | archive/restore + lỗi ghi | Có code/test | ảnh success và error snackbar |
| WEB-08 | Review Queue | loading/empty | Empty pass production trên mobile | Còn thiếu loading live |
| WEB-09 | Review Queue | approve | Có test local | ảnh item + kết quả live |
| WEB-10 | Review Queue | reject bắt buộc lý do | Có test local | ảnh dialog và kết quả live |
| WEB-11 | Review Queue | document lỗi không approve | Có regression test | ảnh cảnh báo thật nếu có fixture an toàn |
| WEB-12 | Dashboard | loading/empty/error/data | Data pass production trên mobile | Còn thiếu loading/empty/error live |
| WEB-13 | Dashboard | ≥3 metrics + chart responsive | Pass một phần: 3 metrics hiển thị; chưa đủ chart/viewport chuẩn | ảnh 1440×900 và 412×915 |
| WEB-14 | Remote Config | guidance true/false không rebuild | Có code/test local | ảnh trước/sau từ Console + Web live |
| WEB-15 | Analytics | approve/reject trong DebugView | Có unit/widget test event | ảnh DebugView thật |
| WEB-16 | Announcement | publish thành công + Analytics | Chờ CM-07 | ảnh form, Inbox Mobile, DebugView |
| WEB-17 | Hosting | SPA reload và mở ẩn danh | Pass một phần: URL/ẩn danh đạt, chưa có SPA route reload production | chụp reload production + metadata route |
| WEB-18 | A11y/layout | keyboard, focus, text scale, overflow | Source đã sửa responsive Recipes ngày 11/11; widget test 412×915 pass, production chưa retest | Deploy rồi chụp lại 412×915; kiểm desktop, keyboard và zoom 200% |

## 3. Viewport bắt buộc

- Desktop chuẩn: `1440 × 900`.
- Desktop nhỏ: `1024 × 768`.
- Mobile-width smoke check: `412 × 915` để chứng minh không overflow, dù Web
  Admin ưu tiên màn rộng.
- Browser zoom 200% cho ít nhất Sign-in, Recipes và Review Queue.

## 4. Quy trình chụp

1. Ghim commit/build và xóa dữ liệu nhạy cảm khỏi fixture.
2. Chạy Web bằng cấu hình đúng project hoặc mở Hosting URL.
3. Chụp console/Network chỉ khi cần và phải crop khỏi email/token; không chỉnh
   nội dung UI evidence.
4. Chạy lần lượt role `user`, `staff/admin`; không đổi role trong lúc ghi một
   test case.
5. Lưu file vào `evidence/web/TV-04B-20261110/`, cập nhật README ngay sau mỗi
   ảnh để tránh mất provenance.
6. Gửi ma trận và evidence cho Thái An đưa vào `docs/test-report.md`.

## 5. Kiểm chứng local đã có

- `evidence/web/TV-00-TV-03-20261109/`: analyzer, admin tests, full Flutter
  suite và Web build tại snapshot đã ghi.
- `evidence/web/TV-03B-20261110/`: Analytics/Remote Config tests và giới hạn
  Console còn lại.
- PR #25 integration evidence: `evidence/review/PR25-integration-20261110/`.
- Lượt sửa review mới nhất: 21/21 admin tests pass; hai file E2E Python compile
  sạch. Chưa suy thành ARTEMIS/device run.

## 6. Điều kiện hoàn thành TV-04B

- Tất cả WEB-01..18 có kết quả Pass/Fail/Blocked và nguồn evidence.
- WEB-03, WEB-14, WEB-15, WEB-16, WEB-17 phải có bằng chứng live phù hợp, không
  được thay bằng widget test.
- Thái An xác nhận ma trận được đưa vào `docs/test-report.md`.
