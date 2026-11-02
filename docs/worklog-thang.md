# Worklog — Thắng VLQ

> **Vai trò:** Technical Architect & Co-Lead  
> **Ngày cập nhật:** 02/11/2026  
> **Nhánh kiểm tra:** `main`  
> **Mục đích:** Ghi bằng chứng hoàn thành, phần còn thiếu, lỗi đã phát hiện và điều kiện tiếp tục cho các task do Thắng phụ trách.

## 1. Tóm tắt trạng thái

- Tổng số task của Thắng: **28**.
- Đã hoàn thành và có bằng chứng: **5/28 (18%)**.
- Đang làm: **S3-6**.
- Bị chặn bởi môi trường máy: **S0-3-VLQ**.
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

## 3. Task đang làm hoặc bị chặn

### S0-3-VLQ — Bị chặn bởi Android toolchain

Kết quả `flutter doctor -v` ngày 02/11/2026:

- Flutter stable `3.47.9`, Dart `3.13.7`, Windows, Chrome và Visual Studio: đạt.
- Android SDK: **không được tìm thấy**.
- ADB/Android emulator hoặc Android device: **chưa có**.

Cần cài Android SDK Platform 34, Platform Tools, Build Tools và emulator/device; cấu hình bằng `flutter config --android-sdk <đường-dẫn-sdk>` nếu SDK ở vị trí riêng; sau đó chạy lại `flutter doctor -v` và `flutter devices`.

### S3-6 — Đang làm

AuthGate đã xử lý loading, signed-in và signed-out. Chưa thể hoàn thành vì chưa đủ routes/screens `S01–S10`, chưa kiểm tra Back từ S04/S08/S09, chưa có Android runtime và Firebase Android chưa được cấu hình hoàn chỉnh.

Cần hoàn thành các screen/routes, route contract, Android SDK/emulator/device và chạy smoke test auth + toàn bộ Back path.

## 4. Firebase: trạng thái và phần còn thiếu

Người dùng đã được mời vào Firebase project, nhưng quyền Console không tự động hoàn tất cấu hình ứng dụng trong repo.

Hiện có Firebase packages, Firestore/Storage rules, Remote Config defaults, service wrappers và ViewModel consumers.

Chưa có hoặc chưa được xác minh:

- `android/app/google-services.json` chưa xuất hiện trong checkout.
- Chưa ghi Firebase project ID trong README.
- Chưa xác minh SHA-1 debug của máy Thắng trên Firebase Console.
- Chưa chạy app Android kết nối project thật.
- Chưa có evidence Auth/Storage/FCM/Analytics/Crashlytics/Remote Config.

Cần phối hợp Charlie/Thái An để chạy `flutterfire configure`, lấy đúng `google-services.json`, đăng ký SHA-1 và đối chiếu project ID.

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
- `google-services.json` chưa có trong commit này.
