# Worklog — Thắng VLQ

> **Vai trò:** Technical Architect & Co-Lead  
> **Ngày cập nhật:** 04/11/2026
> **Nhánh kiểm tra:** `main`  
> **Mục đích:** Ghi bằng chứng hoàn thành, phần còn thiếu, lỗi đã phát hiện và điều kiện tiếp tục cho các task do Thắng phụ trách.

## 1. Tóm tắt trạng thái

- Tổng số task của Thắng: **28**.
- Đã hoàn thành và có bằng chứng: **7/28 (25%)**.
- Hoàn thành mới ngày 04/11: **S0-3-VLQ** và **S3-6**.
- Không còn blocker Android SDK/ADB/emulator trên máy Thắng.
- Tooling hỗ trợ Firebase, ARTEMIS, review, security scan và video được ghi tại [`docs/thang-tooling-setup-20261104.md`](thang-tooling-setup-20261104.md).
- Các task test/review/report/nộp bài chưa hoàn thành vì còn phụ thuộc tính năng, Firebase runtime, bằng chứng ARTEMIS hoặc sản phẩm của thành viên khác.

## 2. Task đã hoàn thành

### S0-6 — Kết nối đầu vào Lab 2

Đã xác minh repository `https://github.com/ruxenb/longvita`, checkout `T:\PRM393\git\longvita` (nhánh bàn giao `Task_4`), toàn bộ tài liệu persona/user flow/design/screen spec/handoff và Figma Page 01–06.

File Figma offline: `T:\PRM393\Longvita - UI_UX Design.fig`, SHA-256 `AFAE9522E873EA909F1FBF74AD1AFD329B8CC6A15715B51709D0D3932EEAB140`.

Bằng chứng: phần “Nguồn đầu vào kế thừa từ Lab 2” trong `README.md`.

### S1-1 — Design traceability

`docs/design-traceability.md` đã có 10 màn Lab 2 và hai màn bổ sung Lab 3; ba flow nghiệp vụ; Auth Flow; alternative/recovery paths; Component-to-Widget mapping; routes, data source và Design Deviation Log. S07 Empty State đã sửa để quay về S04, khớp nguồn Lab 2.

### S2-1 — Service contracts và ViewModel baseline

Đã chốt contract Auth/Data/Report, Firebase wrappers, bốn ViewModel chính và quy tắc UI không gọi SDK trực tiếp. Dependency được đăng ký tập trung bằng Provider.

Bằng chứng: `docs/service-contracts.md`, `docs/architecture.md` và implementation merge tại commit `ae35f07`.

### S2-2 — MVVM skeleton và Provider DI

Đã có models, services, Firebase wrappers, ViewModels, screens, theme, widgets, `MultiProvider`, constructor injection, explicit `ViewState` và AuthGate.

Kiểm chứng ngày 02/11/2026:

- `flutter pub get`: thành công.
- `flutter analyze`: `No issues found`.
- `flutter test`: `1/1` test pass.

### S2-5 — Architecture document

`docs/architecture.md` đã có cấu trúc thư mục, Mermaid layer diagram, sequence diagram, bảng ViewModel–Service, dependency một chiều và định hướng tách shared core. Nội dung đã được đối chiếu với code tại commit `ae35f07` và service baseline hiện tại.

## 3. Task hoàn thành bổ sung ngày 04/11/2026

### S0-3-VLQ — Android toolchain và emulator

Kết quả kiểm tra lại ngày 04/11/2026:

- Flutter stable `3.47.9`, Dart `3.13.7`: đạt.
- `flutter doctor -v`: **No issues found**.
- Android SDK tại `T:\Android\Sdk`, API 36, Build Tools 36.0.0: đạt.
- Android licenses: đã chấp nhận đầy đủ; ADB hoạt động.
- Emulator `Longvita_API_36` khởi động thành công và xuất hiện trong `flutter devices` dưới tên `emulator-5554`, Android 16/API 36.
- Debug APK build, cài đặt và chạy thành công trên emulator.

Task không còn bị chặn và được chuyển sang **Đã hoàn thành**.

### S3-6 — Auth routing và Back navigation

Kiểm chứng source và tự động:

- `AuthGate` xử lý loading, signed-in và signed-out; khi đổi phiên sẽ `popUntil(route.isFirst)` để không quay lại route protected.
- Test xác nhận đăng xuất xóa route protected và Back không quay lại; Home → Profile → Back trở về Home.
- `flutter analyze`: **No issues found**.
- `flutter test`: **305/305 tests passed**.

Smoke test native trên `emulator-5554` ngày 04/11:

- Signed-out mở đúng Sign-in; Back ở route gốc đưa về Android launcher.
- Mở lại app khôi phục phiên Firebase và vào `Longvita Dashboard`.
- Từ Dashboard mở S02 Tạo thực đơn, S10 Kế hoạch đã lưu, Tra cứu công thức và Hồ sơ; phím Back của cả bốn route đều trở về Dashboard.
- Ảnh và mô tả bằng chứng: [`evidence/routing/S0-3-S3-6-20261104/`](../evidence/routing/S0-3-S3-6-20261104/).

Task được chuyển sang **Đã hoàn thành**. Smoke test này xác nhận routing/back; không thay thế ARTEMIS 3-run hoặc kiểm thử failure cases Firebase của các task khác.

## 4. Firebase: trạng thái và phần còn thiếu

Người dùng đã được mời vào Firebase project, nhưng quyền Console không tự động hoàn tất cấu hình ứng dụng trong repo.

Hiện có Firebase packages, Firestore/Storage rules, Remote Config defaults, service wrappers và ViewModel consumers. Bản debug Android đã khởi tạo Firebase, khôi phục phiên Google của Thắng và vào Dashboard trên emulator.

Chưa có hoặc chưa được xác minh:

- `android/app/google-services.json` đã có trong checkout, được Git theo dõi và trỏ tới project `longvita-8da7e`.
- Chưa đối chiếu project ID này với toàn bộ ảnh Firebase Console và README cuối.
- Chưa xác minh lại SHA-1 debug của máy Thắng trên Firebase Console trong lượt kiểm tra này.
- App Android đã kết nối đủ để khôi phục phiên Firebase Auth thật; chưa dùng kết quả này để khẳng định toàn bộ sáu dịch vụ Firebase đã chạy end-to-end.
- Chưa có evidence Auth/Storage/FCM/Analytics/Crashlytics/Remote Config.

Cần phối hợp Charlie/Thái An để đối chiếu project ID/SHA-1 và thu thập evidence riêng cho Storage, FCM, Analytics, Crashlytics và Remote Config.

## 5. Lỗi đã phát hiện và cách xử lý

### E-01 — Flutter command không chạy trong sandbox ban đầu

Flutter cần ghi cache ngoài workspace nên ban đầu không trả output. Sau khi cho phép cập nhật cache, dependencies được restore thành công.

### E-02 — Analyzer báo hàng loạt package URI không tồn tại

Nguyên nhân là chạy Dart analyzer trước khi có `.dart_tool/package_config.json`, không phải hàng trăm lỗi source độc lập. Đã chạy `flutter pub get` rồi kiểm tra bằng `flutter analyze`.

### E-03 — 10 lỗi contract AnalyticsService

- `MealPlanViewModel` gọi các tham số cũ `targetAge`, `weightKg`, `fishCount`.
- `ProfileViewModel` gọi `logExportReport(format: 'pdf')`.
- AnalyticsService mới yêu cầu `targetAgeGroup`, `mealsPerDay`, `eatingWindowHours`, `fishMealsCount`, `fileSizeKb`, `hasShoppingList`.

Đã sửa mapping nhóm tuổi, số bữa, cửa sổ ăn 12 giờ, số bữa cá, kích thước PDF và cờ shopping list. Sau sửa, analyzer sạch và test pass.

### E-04 — Android toolchain chưa sẵn sàng

`flutter doctor` báo `Unable to locate Android SDK`. Đây là blocker môi trường, không phải lỗi Dart source; chưa thể chạy Android/Firebase runtime.

## 6. Các task chưa thể làm sớm

- **S5-10:** cần sáu Firebase service hoạt động trên Android và evidence failure cases.
- **S6-1:** cần flow, accessibility, instrumentation và failure testing hoàn tất.
- **S6-12:** cần ARTEMIS chỉ ra lỗi thuộc phạm vi Thắng.
- **S7-1-VLQ đến S7-4:** cần feature-freeze, PR/review output và findings của cả nhóm.
- **S8-1/S8-5/S8-9/S8-10:** cần chức năng, evidence và review hoàn chỉnh.
- **S8-14/S8-15:** cần finding đã sửa và clip demo của các thành viên.
- **S8-16:** README còn thiếu project ID/data source đã xác minh, AI disclosure cuối và video public.
- **S8-17-VLQ:** worklog đã khởi tạo nhưng chỉ hoàn thành khi cập nhật đến cuối dự án.
- **S9-1 đến S9-6:** là kiểm tra/nộp cuối kỳ, chưa đủ điều kiện.

## 7. Trạng thái Git trước commit

- Base trước thay đổi: `main` tại commit `614e731`.
- Thay đổi gồm tài liệu nguồn Lab 2, service contracts, task tracker, worklog và hai sửa lỗi Analytics contract.
- Không thêm API key, service account, keystore hoặc secret.
- Tại mốc lịch sử 02/11, `google-services.json` chưa có trong commit của Thắng; checkout hiện tại sau khi merge các PR đã có file được Git theo dõi.
