# Hoàng — Bổ sung HD-05 và đối chiếu Figma S04 (10/11/2026)

## Phạm vi và nguồn

- Nhánh: `feature/hoang-vietnamese-figma-20261110`; PR #29.
- Đối chiếu Figma gốc: file `73GTcipwH825N7l501or8D`, S04 `103:160`; Figma là bản tham chiếu đóng băng, không sửa thiết kế.
- Tiếp tục dùng `IDataService` / `DataService` và Firestore thật; dữ liệu mẫu chỉ tồn tại trong lớp fake của unit/widget tests.
- Không thay đổi schema Firestore, vai trò hoặc workflow xét duyệt của `firebase/firestore.rules`. Trạng thái lưu trên DB là `draft → submitted → approved/rejected`; nhãn giao diện là tiếng Việt.

## Những thay đổi đã lập trình

1. **HD-05 — Gửi xét duyệt:** Thêm nút **Gửi chuyên gia xét duyệt** trong S04 khi thực đơn đã lưu, thuộc phiên hiện tại, đủ 7 ngày và còn là bản nháp. Chặn thao tác gửi trùng trong lúc đang gửi; chỉ đổi trạng thái trên giao diện khi Firestore xác nhận ghi thành công.
2. **HD-05 — Cập nhật realtime:** Khi mở/lưu kế hoạch, `MealPlanViewModel` theo dõi `streamUserMealPlans(uid)`, cập nhật `status` và `reviewerReason` mà không ghi đè món ăn vừa sửa. Hủy subscription khi đổi tài khoản, đăng xuất hoặc dispose. Bỏ qua snapshot cache `draft` cũ sau khi gửi xét duyệt.
3. **Khôi phục khi lỗi:** Gửi thất bại giữ nguyên bản nháp và hiển thị nút Thử lại. Khi lỗi stream, vẫn hiển thị kế hoạch và cho phép **Kết nối lại**.
4. **Kiểm tra an toàn:** Không gửi ID kế hoạch khác hoặc kế hoạch đã duyệt; không gọi ghi cập nhật đối với kế hoạch đã qua trạng thái bản nháp.
5. **S04 Figma:** Bộ chọn ngày ngang, tối thiểu 48 dp, mỗi lần hiển thị món của ngày được chọn (không thay thế 7 ngày bằng một ngày), dùng ngày trong tuần của thời điểm tạo kế hoạch; vẫn có lưu, gửi xét duyệt, nguyên liệu và kế hoạch đã lưu.
6. **FlowFrame:** Dùng `AppTopBar`, nền canvas, bề ngang tối đa 480 dp theo design system, áp dụng cho các màn S02/S03/S04/S10.

## Kiểm thử thực hiện

- `test/flows/hoang_viewmodels_test.dart`: 4 ca mới cho gửi đúng/sai ID, cập nhật duyệt realtime, retry lỗi ghi và đổi phiên.
- `test/flows/weekly_plan_review_ui_test.dart`: 2 ca widget tại 360 và 412 dp, chọn ngày, gửi và cập nhật trạng thái.
- Các kết quả Flutter analyze và tổng test cần đối chiếu log của lần chạy mới nhất; **không xem widget test là kiểm thử thiết bị Android thật**.

## Bản ghi rà soát (AI-assisted review)

| Mã | Phát hiện | Mức độ | Quyết định | Cách xử lý |
|---|---|---|---|---|
| HD-F01 | S04 chưa có nút gửi duyệt dù ViewModel có phương thức | Cao | Accept | Bổ sung CTA và trạng thái loading/error |
| HD-F02 | Không có listener cập nhật duyệt từ Web lên kế hoạch đang mở | Cao | Accept | Stream lọc UID/ID, hủy theo session, giữ nội dung draft |
| HD-F03 | `submitForReview(planId)` chưa xác thực activePlan/owner trước khi gọi service | Cao | Accept | Chặn ID, owner, trạng thái, độ dài tuần không hợp lệ |
| HD-F04 | S04 ban đầu xếp cả 7 ngày thành ExpansionTile, khác bộ chọn ngày Figma | Trung bình | Modify | Hiển thị ngày chọn theo các chip cuộn ngang |

## Chưa có đủ bằng chứng nghiệm thu

- **Android SDK:** `flutter doctor -v` báo không có SDK platform trong `D:\Tools\AndroidSDK\platforms`; lệnh `sdkmanager` hiện lỗi khởi tạo Java security. Do đó chưa xác nhận APK, screenshot Android 360/412, ARTEMIS và test thiết bị thật.
- **Firebase production:** Chưa thực hiện lượt test cross-role **live** với tài khoản user/staff; chưa xác minh DebugView Analytics, Crashlytics Console hoặc Firebase seed recipes thật.
- **Figma:** S04 đã tăng mức tương đồng về bố cục nhưng chưa có ảnh overlay/pixel-diff trên Android; toàn bộ S01–S10 chưa có nghiệm thu đồng bộ 100%.
- **Bài nộp:** Chưa có video demo 3 flows, bằng chứng tối thiểu 3 lượt ARTEMIS và chứng minh thông số dinh dưỡng từ recipe được kiểm duyệt thực tế. Không đánh dấu những mục này là hoàn thành.

Các khác biệt vẫn phải được xem xét và chấp thuận bằng bằng chứng thực tế trước khi merge PR #29 vào main. Không ghi dữ liệu giả vào Firebase dùng chung.

## Xác minh cuối ngày 10/11/2026

- Flutter Analyze `--no-pub`: **No issues found**; log `D:\PRM393\hoang_final_analyze_20261110.log`.
- Flutter Test `--no-pub --concurrency=1`: **484/484 bài đạt**; log `D:\PRM393\hoang_final_tests_20261110.log`.
- Bộ test có thêm 4 ca ViewModel và 2 ca widget HD-05/S04. Đã xử lý lỗi cũ trong kiểm thử về race và tràn chữ 200% mà không bỏ điều kiện bảo mật của production.
- Đây là nghiệm thu chạy Flutter tự động, **không phải** kiểm thử ARTEMIS/Android thật, cross-role Firebase live hay xác nhận dữ liệu dinh dưỡng.
