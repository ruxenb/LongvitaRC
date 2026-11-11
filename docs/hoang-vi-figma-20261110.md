# Hoàng: đối chiếu tiếng Việt và Figma ngày 10/11/2026

## Nguồn thiết kế và phạm vi
- Thiết kế gốc: Figma 73GTcipwH825N7l501or8D, Final UI, S01 node 103:5. Figma đóng băng, chỉ chỉnh Flutter.
- S01 sử dụng lại AppTopBar, AppSummaryCard, AppMealCard, AppButton, AppBadge và AppNavigationBar, giữ tokens từ Figma.
- S01 lấy món theo ngày hiện tại từ MealPlanViewModel.activePlan; không giả dữ liệu. Khi không có món, hiển thị empty state.
- Giữ realtime Firestore Inbox, các đường vào kế hoạch, mua sắm, hồ sơ và đăng xuất.
- Việt hóa S05/S06/S09, điều hướng, badge, error state và locale MaterialApp. Không sửa schema/status, không tự dịch tên món từ nguồn.

## Sai lệch và các việc còn cần nghiệm thu
- Không tự điền ảnh mẫu; ảnh món chỉ dùng nếu có nguồn hình hợp lệ.
- Trang chủ có thêm Inbox và lối vào hồ sơ so với S01 để đáp ứng Final Assignment.
- Các màn S02/S03/S04/S10 vẫn cần đối chiếu ảnh thực tế 360/412 dp và font scale 1/2.
- Chưa có bằng chứng để khẳng định pixel-perfect toàn bộ 10 màn hoặc hoàn thành 26/26 task.

## Kiểm tra
- Chạy Node kiểm tra cấu trúc S01, locale, không emoji trong các chuỗi Dart.
- Chạy git diff --check, Flutter analyze, Flutter test trước khi nghiệm thu.
- ARTEMIS 3 lượt/test, cross-role live, ảnh Android, Analytics/Crashlytics và video phải dùng evidence thật.

## Kết quả đã kiểm chứng ngày 10/11/2026
- Flutter 3.47.2, flutter pub get --enforce-lockfile: thành công.
- Flutter analyze --no-pub: không có vấn đề.
- Flutter test --no-pub, các bộ profile và design-system: 84/84 bài đạt.
- Flutter test --no-pub --concurrency=1: 478/478 bài đạt trên Flutter 3.47.2; lần chạy song song trước đó bị kẹt tiến trình.
- Quét chuỗi Dart: 0 emoji; chưa đối chiếu ảnh native của toàn bộ 10 màn Figma.
