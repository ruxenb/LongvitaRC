# Worklog — Thắng VLQ

## 10/11/2026 — TV-00 production và TV-05 README

- TV-00: deploy Flutter Web từ `web/` lên Firebase Hosting project
  `longvita-8da7e`; production URL `https://longvita-8da7e.web.app` trả HTTP
  200 và mở được trong Cốc Cốc ẩn danh.
- Kiểm tra role gate production: `admin` vào Dashboard; `user` xác thực Google
  nhưng bị chặn đúng màn hình “Tài khoản không có quyền”. Deploy chỉ gồm
  Hosting, không deploy Rules và không ghi dữ liệu production.
- TV-05: cập nhật README với URL, hướng dẫn Mobile/Web/emulator, roles, tài khoản
  demo đã xác minh, pinned versions, AI disclosure và deliverable map.
- Chưa đóng TV-05: còn thiếu tài khoản `staff` riêng, video public/unlisted,
  report PDF và slide PDF cuối. Ảnh TV-00 cần làm sạch PII trước khi commit.

> **Vai trò:** Technical Architect & Co-Lead  
> **Ngày cập nhật:** 10/11/2026
> **Nhánh kiểm tra:** `codex/tv00-hosting-evidence` (đồng bộ `main` tại `0cfe905`)  
> **Mục đích:** Ghi bằng chứng hoàn thành, phần còn thiếu, lỗi đã phát hiện và điều kiện tiếp tục cho các task do Thắng phụ trách.

## 1. Tóm tắt trạng thái

- Tổng số task của Thắng: **28**.
- Đã hoàn thành và có bằng chứng: **13/28 (46%)**.
- Hoàn thành mới ngày 08/11: **S8-9** (nội dung slide cá nhân, nguồn evidence,
  gợi ý hình và AI disclosure; chưa phải deck PDF cuối).
- Hoàn thành mới ngày 07/11: **S7-2-VLQ**, **S7-3-VLQ**, **S8-1** và
  **S9-5-VLQ**.
- Hoàn thành mới ngày 04/11: **S0-3-VLQ** và **S3-6**.
- Không còn blocker Android SDK/ADB/emulator trên máy Thắng.
- Tooling hỗ trợ Firebase, ARTEMIS, review, security scan và video được ghi tại [`docs/thang-tooling-setup-20261104.md`](thang-tooling-setup-20261104.md).
- Nhánh `Thang` đã merge vào `main` tại `90d9fd0`; `origin/Thang` không còn commit riêng chưa có trên `main` tại thời điểm kiểm tra.
- Snapshot 08/11: working tree sạch, `main` đồng bộ `origin/main` tại `4f3fd07` (merge PR #19). PR #19 thuộc phạm vi FCM của Charlie nên không làm tăng số task hoàn thành của Thắng.
- Baseline sau PR #19 có evidence **388/388 Flutter tests pass** trong `evidence/fcm/S4-12-v1-20261108/README.md`; đây là kết quả đã lưu của PR, không phải lượt chạy lại độc lập trong lần cập nhật worklog này.
- Sau merge: `flutter analyze lib --no-pub` sạch và **334/334 Flutter tests pass**. Analyzer toàn cây bị ảnh hưởng bởi Dart template bên trong `test/firestore/node_modules/firebase-tools`, không phải source `lib/`.
- Các task test/review/report/nộp bài còn lại chưa hoàn thành vì vẫn phụ thuộc
  Firebase runtime, bằng chứng ARTEMIS hoặc sản phẩm của thành viên khác.

### S5-10 — Hoàn thành có giới hạn ngày 06/11/2026

Trên AVD `Longvita_API_36`, project `longvita-8da7e`:

- Remote Config lần đầu được cấu hình trên Console với bốn parameter khớp
  in-app defaults; hai giá trị nhìn thấy được đã đổi live (5→6, Bật→Tắt), app
  fetch/activate không rebuild và sau đó hoàn nguyên thành công.
- Analytics DebugView nhận debug device; `logout` được tạo khi emulator offline,
  sau khi bật mạng và đăng nhập lại Console nhận cả `logout` và `login`.
- Crashlytics nhận fatal test issue; app mở lại đúng `ROLE: ADMIN`. Auth offline
  được app xử lý không crash và Console nhận non-fatal `AuthFailureKind.network`,
  `network_error`, `ApiException: 7`, reason `Google sign-in failed (network)`.
- Kết hợp evidence 04–05/11, sáu dịch vụ đều có ít nhất một manual failure case.
  Storage chỉ đạt trên Firebase Storage Emulator; project Spark chưa được tuyên
  bố Storage cloud pass. Firestore dùng chung vẫn thiếu `recipes`, nên plan mới
  và export/upload của tài khoản Thắng còn bị chặn bởi dữ liệu nghiệp vụ.

Evidence: [`evidence/failure-cases/S5-10-THANG-20261106/`](../evidence/failure-cases/S5-10-THANG-20261106/).
S5-10 được chuyển sang **Đã hoàn thành có giới hạn**.

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
- Debug certificate của máy Thắng đã lấy SHA-1/SHA-256. Owner đã thêm fingerprint;
  ngày 05/11/2026 fresh Google Sign-In trên AVD API 36 thành công bằng certificate
  này, không có lỗi `ApiException: 10` hoặc lỗi cấu hình OAuth.

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

Các chuẩn bị và audit từ nhánh Thắng vẫn được lưu trong `docs/failure-case-matrix.md`, `evidence/audit/S9-1-S9-4-20261103/`, `scripts/` và `docs/report-drafts/`; chúng chưa được tính là hoàn tất các task phụ thuộc cloud hoặc nghiệm thu cuối kỳ.

### S5-10 — Failure cases tiếp tục ngày 04/11/2026

Trên `Longvita_API_36`, commit `90d9fd0`:

- **PASS — Remote Config offline:** tắt Wi-Fi và mobile data, xác minh mạng
  unreachable; refresh không báo thành công giả, giữ giá trị hiện tại.
- **PASS — Crashlytics cancel:** mở dialog test crash rồi hủy; ứng dụng trở về
  Profile và tiến trình vẫn chạy.
- **Chưa tính pass — FCM permission denied:** đã tới permission gate nhưng phiên
  tự động không chọn thay người dùng trên hộp thoại quyền riêng tư. Quyền và mạng
  đã được khôi phục sau kiểm tra.

Evidence: [`evidence/failure-cases/S5-10-THANG-20261104/`](../evidence/failure-cases/S5-10-THANG-20261104/).
S5-10 vẫn **Đang làm** vì còn Storage/Analytics, FCM cloud, cloud dashboard và
manual cases khác.

### S3-2 / S3-3 và S5-10 — Auth/FCM bổ sung ngày 05/11/2026

Trên commit `dcbdedf`, AVD `Longvita_API_36`:

- **PASS — Fresh Google Sign-In:** đăng xuất phiên cũ, người dùng tự chọn tài
  khoản trong account picker, app vào Dashboard đúng phiên; không có lỗi cấu
  hình SHA/OAuth.
- **PASS — Auth cancel:** nhấn Back từ account picker, app về Sign-in và hiện
  thông báo hủy rõ ràng, không crash.
- **PASS — Auth offline:** tắt Wi-Fi/mobile data, chọn tài khoản; app về Sign-in,
  hiện lỗi mạng và cho thử lại; log ánh xạ `ApiException: 7` thành network failure.
- **PASS — FCM permission denied:** người dùng chọn Don't allow; Android xác nhận
  `granted=false`, app vẫn chạy và Profile giải thích cách bật notification.
- Sau kiểm thử, Wi-Fi/mobile data và quyền notification đã được khôi phục.

Evidence khử PII:
[`evidence/auth/S3-2-S5-10-THANG-20261105/`](../evidence/auth/S3-2-S5-10-THANG-20261105/).

### S7-2-VLQ, S7-3-VLQ và S8-1 — Hoàn thành ngày 07/11/2026

- Hồ sơ PR #6 đã có 5 findings thật, quyết định, lý do và link commit `55bdf3e`.
- S7-2-VLQ hoàn thành: đủ 5 findings thật với vị trí, loại, quyết định, lý do và
  disclosure công cụ trong `docs/code-review.md`.
- S7-3-VLQ hoàn thành: commit `55bdf3e` sửa PR6-01..05, có link từng finding và
  đã merge vào `main` qua `90d9fd0`.
- S8-1 hoàn thành nội dung cá nhân tại
  [`docs/report-drafts/s8-1-thang.md`](report-drafts/s8-1-thang.md), cập nhật theo
  `main` `c4e8024` và ghi rõ giới hạn Flutter/native/Firebase/ARTEMIS.
- Đã soạn kịch bản clip S8-14 tại
  [`docs/report-drafts/s8-14-thang-clip-script.md`](report-drafts/s8-14-thang-clip-script.md);
  chưa quay hoặc ghép video cuối.
- S9-5-VLQ đã có bài nói hoàn chỉnh để Thắng học, kèm Remote Config live và
  TC-11 ARTEMIS chạy thật; task được tính hoàn thành.

## 4. Firebase: trạng thái và phần còn thiếu

Người dùng đã được mời vào Firebase project, nhưng quyền Console không tự động hoàn tất cấu hình ứng dụng trong repo.

Hiện có Firebase packages, Firestore/Storage rules, Remote Config defaults, service wrappers và ViewModel consumers. Bản debug Android đã khởi tạo Firebase, khôi phục phiên Google của Thắng và vào Dashboard trên emulator.

Chưa có hoặc chưa được xác minh:

- `android/app/google-services.json` đã có trong checkout, được Git theo dõi và trỏ tới project `longvita-8da7e`.
- Chưa đối chiếu project ID này với toàn bộ ảnh Firebase Console và README cuối.
- SHA-1/SHA-256 của máy Thắng đã có trong hồ sơ Console/OAuth và fresh Google
  Sign-In đã pass ngày 05/11.
- Auth cancel/offline và FCM permission-denied đã có evidence manual; chưa dùng
  các kết quả này để khẳng định toàn bộ sáu dịch vụ Firebase đã chạy end-to-end.
- Còn thiếu evidence project thật cho Storage, Analytics offline delivery,
  Crashlytics non-fatal và Remote Config live.

Cần phối hợp Charlie/Thái An để thu thập evidence còn lại cho Storage, FCM cloud,
Analytics, Crashlytics và Remote Config live.

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

- **S5-10:** đã hoàn thành có giới hạn; Storage là Emulator theo Spark/DEC-01,
  không phải bằng chứng Storage cloud production.
- **S6-1:** cần flow, accessibility, instrumentation và failure testing hoàn tất.
- **S6-12:** cần ARTEMIS chỉ ra lỗi thuộc phạm vi Thắng.
- **S7-4:** S7-1/S7-2/S7-3 của Thắng đã hoàn thành; S7-4 vẫn cần nghiệm thu
  hồ sơ review đủ thành viên và xác nhận leader.
- **S8-5/S8-10:** S8-1 và nội dung cá nhân S8-9 của Thắng đã hoàn thành; còn
  đầu vào nhóm và bước ghép report/slide cuối.
- **S8-14/S8-15:** cần finding đã sửa và clip demo của các thành viên.
- **S8-16:** README còn thiếu project ID/data source đã xác minh, AI disclosure cuối và video public.
- **S8-17-VLQ:** worklog đã khởi tạo nhưng chỉ hoàn thành khi cập nhật đến cuối dự án.
- **S9-1/S9-4:** đã audit giữa kỳ nhưng phải chạy lại trước nộp; S9-2/S9-3/S9-5/S9-6
  chưa đủ điều kiện.

## 7. Review PR #6 trên nhánh Thang

- S7-1-VLQ được đối chiếu lại ngày 10/11 và chuyển sang **Đã hoàn thành** vì PR
  #6 đã được hai công cụ AI review, output đã lưu và hồ sơ đã merge. Việc này
  xác nhận đầu ra review đã tồn tại, không thay thế mốc feature freeze S6-1.
- `55bdf3e`: xử lý privacy/evidence findings từ Bugbot và Security Review.
- `c42519f`: ghi 5 findings, quyết định, lý do và giới hạn vào
  `docs/code-review.md` và `evidence/review/PR-6-THANG-20261103/`.
- Analyzer sạch, 270/270 Flutter tests pass và 7 ARTEMIS cases collect được.
- Hai commit đã được đưa vào `main` qua merge nhánh `Thang` ngày 04/11/2026.
- Không thêm API key, service account, keystore hoặc secret.

## 8. TC-11 ARTEMIS chạy lại ngày 07/11/2026

- Emulator: `Longvita_API_36`, serial `emulator-5554`.
- Profile/model: Flash / `gemini-3.5-flash-lite`.
- Pytest: **1 passed in 77.88s**.
- ARTEMIS task: `9a885faf-776a-457a-8cc4-2cdfb007b93d`.
- Sáu replay steps xác nhận đăng xuất về Sign-in và Android Back ra launcher,
  không quay lại Dashboard.
- Lượt model `gemini-3.8-flash` trước đó timeout 180 giây trước thao tác UI; raw
  failed record được giữ để phân biệt lỗi hạ tầng/model với lỗi ứng dụng.
- S9-5-VLQ hoàn thành: bài nói 5 phút đã soạn theo source/evidence thật, phần
  Remote Config và ARTEMIS đều có kết quả kiểm chứng để Thắng tự học và luyện.

## 9. Cập nhật tài liệu và audit ngày 08/11/2026

- S8-9 hoàn thành ở mức nội dung cá nhân: sáu thông điệp đã được cập nhật theo
  evidence mới, có nguồn, gợi ý hình và AI disclosure. Dàn trang/PDF thuộc S8-10.
- S8-16 được bổ sung trạng thái bàn giao, liên kết draft/audit và disclosure;
  chưa hoàn thành vì còn thiếu report PDF, slide PDF và video public.
- S7-4 đã tổng hợp hồ sơ thật của Thắng, Charlie và Hoàng; đã đủ ngưỡng số lượng
  và loại finding nhưng còn thiếu gói review/disclosure được nghiệm thu của Thái
  An và xác nhận leader nên chỉ chuyển sang Đang làm.
- Gitleaks quét history và cây hiện tại, mỗi lượt có 5 findings: hai Firebase
  client keys và ba Firebase Storage download token trong URL PDF ở raw ARTEMIS.
  Không in token vào worklog; cần xác minh/revoke/rotate và sanitize trước khi
  đóng S9-1.
- S9-2 xác nhận Project Settings khớp `longvita-8da7e`, project number
  `1041459198085` và package `vn.edu.fpt.longvita`; cần rà lại tập ảnh cuối.
- S9-4 snapshot `main` có 185 commit, phân bố 2/55/54/36/3/23/2/10 từ 01–08/11;
  chronology hợp lý nhưng chưa có ngưỡng giảng viên và vẫn cần audit cuối.
- Chi tiết audit: `evidence/audit/S9-1-S9-4-20261108/README.md`.

## 10. Hiệu chỉnh tracker và cập nhật ngày 10/11/2026

- Đối chiếu lại PR #6, `evidence/review/PR-6-THANG-20261103/README.md`, commit
  sửa `55bdf3e` và merge commit `90d9fd0`: S7-1-VLQ đáp ứng đủ đầu ra gồm PR,
  AI review và hồ sơ review trong repo.
- Chuyển S7-1-VLQ từ **Chưa bắt đầu** sang **Đã hoàn thành**; tổng tiến độ cá
  nhân tăng từ 13/28 lên 14/28. S7-2-VLQ và S7-3-VLQ giữ nguyên trạng thái đã
  hoàn thành.
- Giữ S6-1 ở **Chưa bắt đầu** vì chưa có tag `v1.0-rc` và chưa có xác nhận
  feature freeze của nhóm. Việc hoàn thành đầu ra S7-1 trước dependency được ghi
  như ngoại lệ trình tự, không được dùng để suy ra S6-1 đã đạt.
- S7-4 vẫn **Đang làm** vì còn thiếu gói review/disclosure được nghiệm thu của
  Thái An và xác nhận leader; không suy từ hồ sơ cá nhân của Thắng thành hoàn
  thành review toàn nhóm.
- Các deliverable cuối S8-5, S8-10, S8-15, S8-16 và audit/nộp bài S9 vẫn giữ
  nguyên trạng thái cho đến khi có PDF, video public và lượt kiểm cuối.

## 11. Yêu cầu leader xác nhận S6-1 và S7-4 ngày 10/11/2026

- Soạn yêu cầu gửi Thái An tại
  `docs/coordination/request-thai-an-s6-1-s7-4-20261110.md`, tách rõ hai quyết
  định: chọn SHA/tag/tiêu chí kiểm thử cho S6-1 và bổ sung hồ sơ AI review cá
  nhân cùng nghiệm thu tổng hợp cho S7-4.
- S6-1 chuyển từ **Chưa bắt đầu** sang **Chờ leader xác nhận**; chưa tạo hoặc
  push tag `v1.0-rc`, chưa suy một snapshot test cũ thành release candidate.
- S7-4 giữ **Đang làm**. Hồ sơ ba thành viên không thay thế PR/output,
  findings, quyết định, fix link và disclosure của Thái An.
- Yêu cầu kèm điều kiện đóng task và mẫu phản hồi để quyết định của leader có
  thể truy vết trong repo/GitHub, tránh nghiệm thu bằng suy đoán.
