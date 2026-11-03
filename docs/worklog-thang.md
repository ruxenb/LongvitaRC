# Worklog — Thắng VLQ

> **Vai trò:** Technical Architect & Co-Lead  
> **Ngày cập nhật:** 03/11/2026
> **Nhánh kiểm tra:** `Thang` (base gồm nội dung PR #6)
> **Mục đích:** Ghi bằng chứng hoàn thành, phần còn thiếu, lỗi đã phát hiện và điều kiện tiếp tục cho các task do Thắng phụ trách.

## 1. Tóm tắt trạng thái

- Tổng số task của Thắng: **28**.
- Đã hoàn thành và có bằng chứng: **6/28 (21%)**.
- Đang làm: **S3-6, S5-10, S8-17-VLQ, S9-1, S9-4**.
- **S0-3-VLQ đã hoàn thành**: Android toolchain/emulator không còn là blocker.
- Các task test/review/report/nộp bài chưa hoàn thành vì còn phụ thuộc tính năng, Firebase runtime, bằng chứng ARTEMIS hoặc sản phẩm của thành viên khác.

## 2. Task đã hoàn thành

### S0-3-VLQ — Toolchain Android trên máy Thắng

Kiểm chứng ngày 03/11/2026:

- Flutter `3.47.9`, Dart `3.13.7`, Java 21.
- Android SDK API 34/35/36, Build Tools, Platform Tools/ADB, NDK, CMake và
  emulator cài trên ổ `T:`.
- AVD `Longvita_API_36` boot thành công; `flutter devices` nhận Android API 36.
- `flutter doctor -v`: **No issues found**, licenses đã chấp nhận.
- `flutter build apk --debug`: thành công; APK được cài và app chạy trên AVD.
- Firebase CLI `15.34.2`, FlutterFire CLI `1.4.1`, Python `3.12.16`, uv và
  ARTEMIS client đều hoạt động; `pytest --collect-only` nhận 7 test.
- Debug certificate của máy Thắng đã lấy SHA-1/SHA-256; đang chờ owner thêm
  fingerprint vào Firebase để kiểm Google Sign-In runtime bằng certificate này.

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

### S3-6 — Đang làm

AuthGate đã xử lý loading, signed-in và signed-out. Bộ 270 test ngày 03/11 pass,
gồm protected route bị loại sau logout, Home → Profile → Back, notification không
stack Profile và session A→B không rò state/tác vụ cũ.

Chưa thể hoàn thành vì routes/screens S02–S10 chưa tồn tại và Google Sign-In bằng
debug certificate của máy Thắng còn chờ Firebase thêm SHA. Sau khi có SHA cần
smoke test auth + Back path trên Android runtime.

### S5-10 — Đang làm

Đã lập [`docs/failure-case-matrix.md`](failure-case-matrix.md), đối chiếu failure
handling hiện có cho sáu Firebase services và tách rõ bằng chứng fake, widget,
Firebase Emulator và project thật. Storage cancel/denied đã có emulator evidence;
Auth cancel và FCM foreground có Android evidence; các ca cloud/manual còn thiếu
được ghi thành blocker thay vì suy diễn là pass.

### S9-1 và S9-4 — Audit giữa kỳ

Hồ sơ tại
[`evidence/audit/S9-1-S9-4-20261103/README.md`](../evidence/audit/S9-1-S9-4-20261103/README.md):

- Không thấy secret credential pattern hoặc tracked keystore/service-account key
  trong cây hiện tại và toàn bộ reachable Git history.
- Đã khử username khỏi 18 đường dẫn máy trong evidence text, giữ nguyên kết quả.
- Lịch sử snapshot có 71 commit trước audit: 2 ngày 01/11, 55 ngày 02/11 và 14
  ngày 03/11; planning/MVVM skeleton có trước feature integration.
- Hai task vẫn **Đang làm** vì phải rerun trước submission và chưa có ngưỡng
  commit/ngày được giảng viên xác nhận.

## 4. Firebase: trạng thái và phần còn thiếu

Người dùng đã được mời vào Firebase project, nhưng quyền Console không tự động hoàn tất cấu hình ứng dụng trong repo.

Hiện có Firebase packages, `google-services.json`, Firestore/Storage rules, Remote
Config defaults, service wrappers, ViewModel consumers và evidence thật cho một
số dịch vụ trên project `longvita-8da7e`.

Chưa có hoặc chưa được xác minh:

- SHA-1/SHA-256 debug của máy Thắng chưa được xác nhận đã thêm trên Firebase Console.
- Chưa xác minh Google Sign-In bằng debug certificate của máy Thắng.
- Storage project thật và Remote Config before/after Console còn thiếu.
- ARTEMIS daemon/model key và raw runs còn thiếu.

Cần phối hợp Charlie/Thái An thêm cả SHA-1/SHA-256 của máy Thắng, tải lại
`google-services.json` nếu Firebase thay đổi OAuth client, rồi rebuild/smoke test.

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

### E-04 — Android toolchain chưa sẵn sàng — Đã xử lý

Đã cài Android SDK/ADB/AVD trên ổ T, chấp nhận licenses, build/cài/chạy APK và
đạt `flutter doctor` sạch ngày 03/11/2026.

### E-05 — Evidence chứa định danh máy/người dùng — Đã xử lý phần phát hiện

Review PR #6 loại ảnh chứa tên/email thật và thay traceback ARTEMIS chứa username
bằng bản tóm tắt khử PII (`55bdf3e`). Audit S9-1 tiếp tục phát hiện 18 evidence
text files có prefix đường dẫn máy cũ; đã thay prefix bằng `<user-home>/` mà không
đổi assertions/kết quả.

## 6. Các task chưa thể làm sớm

- **S5-10:** đã bắt đầu matrix; cần chạy thủ công phần cloud/runtime còn thiếu.
- **S6-1:** cần flow, accessibility, instrumentation và failure testing hoàn tất.
- **S6-12:** cần ARTEMIS chỉ ra lỗi thuộc phạm vi Thắng.
- **S7-1-VLQ đến S7-4:** PR #6 đã có 5 findings và 1 fix commit trong hồ sơ review,
  nhưng review riêng của Thắng/feature-freeze và tối thiểu 3 fix commits toàn nhóm
  vẫn chưa đạt.
- **S8-1/S8-5/S8-9/S8-10:** cần chức năng, evidence và review hoàn chỉnh.
- **S8-14/S8-15:** cần finding đã sửa và clip demo của các thành viên.
- **S8-16:** README còn thiếu project ID/data source đã xác minh, AI disclosure cuối và video public.
- **S8-17-VLQ:** worklog đã khởi tạo nhưng chỉ hoàn thành khi cập nhật đến cuối dự án.
- **S9-1/S9-4:** đã audit giữa kỳ nhưng phải chạy lại trước nộp; S9-2/S9-3/S9-5/S9-6
  chưa đủ điều kiện.

## 7. Review PR #6 trên nhánh Thang

- `55bdf3e`: xử lý privacy/evidence findings từ Bugbot và Security Review.
- `c42519f`: ghi 5 findings, quyết định, lý do và giới hạn vào
  `docs/code-review.md` và `evidence/review/PR-6-THANG-20261103/`.
- Analyzer sạch, 270/270 Flutter tests pass và 7 ARTEMIS cases collect được.
- Hai commit đã push lên `origin/Thang`; PR #6 gốc không tự nhận nếu Charlie chưa
  cherry-pick/merge từ nhánh này.
