# Longvita — Mobile App + Web Admin trên Firebase

> **Final Assignment:** hệ thống gồm Flutter Mobile, Flutter Web Admin và
> Firebase dùng chung. Phân công chính thức nằm tại
> [`docs/tasks/final-task-assignment.md`](docs/tasks/final-task-assignment.md).
> Web Admin đã được deploy lên Firebase Hosting tại
> **https://longvita-8da7e.web.app**. Ngày 10/11/2026, nhóm đã kiểm tra URL ở
> cửa sổ ẩn danh, đăng nhập thành công bằng role `admin` và xác nhận role
> `user` bị chặn đúng thiết kế. Bằng chứng TV-00:
> [`evidence/web/TV-00-20261110/`](evidence/web/TV-00-20261110/README.md).

> **Cập nhật 08/11/2026:** **Lab 3 chính là Assignment** đang triển khai, kế thừa thiết kế Lab 2. Giữ 112 task IDs/owners; các phần mobile/web/shared-core là cùng sản phẩm. Sáu dịch vụ Firebase đã có failure-case evidence ở các mức cloud/emulator khác nhau; không suy Storage Emulator thành production. ARTEMIS có một batch 7/7 pass và TC-11 chạy lại thành công, nhưng chưa đủ chiến dịch chính thức tối thiểu ba lượt/test.
>
> **Firebase project:** `longvita-8da7e`, app Android `vn.edu.fpt.longvita` (S0-4). Bốn máy đã có xác nhận đăng nhập Google ở S3-2.
>
> Phiên bản đã ghim (S3-1, 06/11/2026): package hosted trong `pubspec.yaml` là exact version trùng `pubspec.lock`; Flutter/Gradle ở mục 2 là bộ đã build và chạy trên máy Charlie. Storage/Spark, application ID và rubric khác nhau đang được ghi trong DEC-01..04.

> **Môn học:** PRM393 — Mobile Programming (Lab 3: Cloud-Enabled Mobile App)  
> **Chủ đề (kế thừa Lab 2):** Longvita — Ứng dụng hỗ trợ chuyển đổi kiến thức dinh dưỡng trường thọ (*La dieta della longevità* — TS. Valter Longo) thành thực đơn 7 ngày, công thức chi tiết và danh sách mua sắm.  
> **Nền tảng mục tiêu:** Android Device / Emulator  
> **Hình thức làm bài:** Nhóm 4 người (*Handout ghi “Individual”, cần giảng viên xác nhận tại task S0-1*)  
> **Figma Design Lab 2:** [Longvita — UI/UX Design (Page 01–06)](https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=0-1)

### Nguồn đầu vào kế thừa từ Lab 2

- **Repository Lab 2:** [ruxenb/longvita](https://github.com/ruxenb/longvita) — nguồn chuẩn của `ux/persona.md`, `ux/user-flow.md`, `design/DESIGN.md`, `design/design-decisions.md`, `design/screen-spec.md` và `handoff/flutter-handoff.md`.
- **Checkout dùng để đối chiếu:** `T:\PRM393\git\longvita` (nhánh bàn giao Lab 2: `Task_4`).
- **Figma export dùng để kiểm tra offline:** `T:\PRM393\Longvita - UI_UX Design.fig`, SHA-256 `AFAE9522E873EA909F1FBF74AD1AFD329B8CC6A15715B51709D0D3932EEAB140`, cập nhật ngày 01/11/2026.
- **Phạm vi truy vết:** 10 màn `S01–S10`, ba user flow, design foundations, components và prototype Page 03–06. Ma trận chuyển sang Flutter nằm tại [`docs/design-traceability.md`](docs/design-traceability.md).

---

## 1. Phân Công Thành Viên & Vai Trò Trong Dự Án

| Thành viên | Tài khoản / MSSV | Vai trò chính trong Lab 3 | File Task Chi Tiết |
|:---|:---|:---|:---|
| **Thái An** | Thái An | **Team Leader & QA Lead**: Điều phối chung, Analytics, Crashlytics, Remote Config, Google ARTEMIS | [`docs/tasks/task-thai-an.md`](docs/tasks/task-thai-an.md) |
| **Charlie** | CharlieMinh | **Design System in Code + Firebase**: Common Widgets, Theme, Auth, Storage, FCM, Profile | [`docs/tasks/task-charlie.md`](docs/tasks/task-charlie.md) |
| **Hoàng** | Hoàng DV (YAHsaveme) | **Dữ liệu & UI Flows**: DataService, 3 Flows (S01–S10), States, A11y, Đồng bộ Figma | [`docs/tasks/task-hoang.md`](docs/tasks/task-hoang.md) |
| **Thắng** | Thắng VLQ | **Technical Architect & Co-Lead**: MVVM Skeleton, Router, Tài liệu docs, Tổng hợp Report/Slide/Video | [`docs/tasks/task-thang.md`](docs/tasks/task-thang.md) |

- **Trung tâm điều phối toàn bộ 112 tasks:** [`docs/tasks/README.md`](docs/tasks/README.md)
- **Danh sách đầy đủ 112 tasks:** [`docs/tasks/danh-sach-task-full.md`](docs/tasks/danh-sach-task-full.md)
- **Checklist 14 tiêu chí nộp bài:** [`docs/tasks/submission-checklist.md`](docs/tasks/submission-checklist.md)
- **Mốc quan trọng M1–M9 & Phân tích đường găng:** [`docs/tasks/milestones-and-dependencies.md`](docs/tasks/milestones-and-dependencies.md)

---

## 2. Phiên bản công cụ đã kiểm và package đã ghim

Tuân thủ yêu cầu bắt buộc của Handout Mục 3 & 9 về việc ghim phiên bản để tránh xung đột môi trường. Bằng chứng: [`evidence/firebase/S3-1-20261106/`](evidence/firebase/S3-1-20261106/README.md).

| Công cụ / Nền tảng | Phiên bản | Ghi chú cấu hình |
|:---|:---|:---|
| **Flutter SDK** | `3.47.6` (channel stable) | `flutter --version`; bản đã build và chạy S3-1 trên máy Charlie |
| **Dart SDK** | `3.13.5` | Đi kèm Flutter 3.47.6; `pubspec.yaml` yêu cầu `^3.13.2` |
| **Android build** | AGP `9.1.0`, Kotlin `2.4.0`, Gradle wrapper `9.3.1`, Java target 17 | `mobile/android/settings.gradle.kts`, `gradle-wrapper.properties`; JDK 21 chạy Gradle |
| **Firebase Gradle plugins** | google-services `4.5.0`, Crashlytics `3.0.6` | `mobile/android/settings.gradle.kts` |
| **Android SDK** | compileSdk/targetSdk 36, minSdk 24 | Theo Flutter 3.47.6 (`flutter.*SdkVersion`), đọc từ APK bằng `aapt2` |
| **FlutterFire / Firebase CLI** | FlutterFire CLI `1.4.1`, firebase-tools `15.34.2` | Cấu hình theo client: `mobile/lib/firebase_options.dart`, `web/lib/firebase_options.dart`; firebase-tools khóa ở `firebase/package-lock.json` (`npm ci` trong `firebase/`) |
| **Python** | `3.12+` | Dành cho Google ARTEMIS Test Suite |
| **Google ARTEMIS** | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (Apache 2.0) | Pin tại `e2e_test/pyproject.toml` |
| **Firebase Packages** | Core `3.15.2`, Auth `5.7.0`, Storage `12.4.10`, Messaging `15.2.10`, Analytics `11.6.0`, Crashlytics `4.3.10`, RemoteConfig `5.5.0`, Firestore `5.6.12`, google_sign_in `6.3.0` | Exact version trong pubspec của ba member, một `pubspec.lock` ở root |
| **State Management** | `provider: 6.1.5+1` | MVVM Architecture Dependency Injection |

**Quy tắc phiên bản:** mọi package hosted trong pubspec của từng member ghi đúng một version, trùng `pubspec.lock` ở root. Lấy dependencies bằng `flutter pub get --enforce-lockfile` tại root; lệnh này báo lỗi thay vì tự đổi lockfile. Khi cần nâng một package, sửa version trong đúng member pubspec (`mobile/pubspec.yaml`, `web/pubspec.yaml` hoặc `packages/core/pubspec.yaml`), chạy `flutter pub get` tại root và kiểm tra. Commit member pubspec đã sửa cùng root `pubspec.lock` và root `pubspec.yaml` nếu file đó cũng thay đổi; không chạy `flutter pub upgrade` cho toàn workspace.

**Firebase bootstrap:** Mobile dùng `mobile/lib/firebase_options.dart` và `mobile/android/app/google-services.json`; Web dùng `web/lib/firebase_options.dart`. Hai cấu hình giữ nguyên các Firebase App ID đã đăng ký; `firebase.json` trỏ đúng từng client. Mobile giữ `FirebaseBootstrap`/`StartupGate` với nút Thử lại. Migration không chạy FlutterFire configure hoặc tạo Firebase app.


---

## 3. Bản Đồ Nơi Lưu Trữ Sản Phẩm Bàn Giao (Deliverable Map)

Cấu trúc Final sau CM-00/CM-02; [bản đồ migration và ranh giới package](docs/monorepo-migration.md):

```text
LongvitaRC/
├── pubspec.yaml / pubspec.lock          # Pub workspace, một lockfile chung
├── mobile/                            # Flutter Android, package longvita
│   ├── lib/                           # screens, VM, auth/native/PDF/FCM
│   ├── android/                       # vn.edu.fpt.longvita, cấu hình giữ nguyên
│   ├── assets/                        # font PDF và assets riêng Mobile
│   └── test/
├── web/                               # Flutter Web, package longvita_admin
│   ├── lib/                           # Admin screens/VM/auth/bootstrap
│   ├── web/                           # platform index/manifest/icons
│   └── test/
├── packages/core/                     # longvita_core, hai client cùng import
│   ├── lib/                           # models, Firestore, theme, 9 widget groups
│   ├── assets/fonts/                  # UI fonts + OFL, một nguồn
│   └── test/
├── firebase/                          # rules/emulator tests chuẩn ở root
├── e2e_test/ / test_support/           # ARTEMIS và offline regression
├── assets/figma/ / assets/stitch/      # thiết kế tham chiếu, không vào app build
├── evidence/                          # một nguồn bằng chứng chung
├── docs/ / report/ / slides/
└── scripts/                           # kiểm workspace và công cụ nhóm
```

---

## 4. Hướng Dẫn Cài Đặt & Khởi Chạy Ứng Dụng (Barebone)

### Thiết lập nhanh trên máy nhóm đã chuẩn bị ổ T

Mở PowerShell tại thư mục repository và nạp môi trường cho terminal hiện tại:

```powershell
. .\scripts\project-env.ps1
.\scripts\verify-setup.ps1 -RestoreDependencies
```

Script đặt Android SDK, AVD data, Gradle, Pub, npm, uv và pip cache trên ổ
`T:`; đồng thời sửa `JAVA_HOME` của phiên hiện tại sang Temurin 21. Script không
thay đổi biến môi trường toàn hệ thống và không ghi credential vào repository.

Khởi động AVD đã chuẩn bị:

```powershell
.\scripts\start-emulator.ps1
# Dùng -ColdBoot nếu snapshot cũ gây lỗi:
.\scripts\start-emulator.ps1 -ColdBoot
```

Máy khác không có đúng cấu trúc `T:\Android`, `T:\Flutter` và `T:\Tools` vẫn
cần cài toolchain tương ứng hoặc điều chỉnh các path ở đầu
`scripts/project-env.ps1`.

### Bước 1: Khởi tạo môi trường & lấy dependencies

Mở terminal tại **root repository**, nơi có `pubspec.lock` và danh sách
workspace members. Thực hiện bước này trước khi `cd mobile` hoặc `cd web`.

```bash
# Kiểm tra môi trường Flutter
flutter doctor

# Tải toàn bộ packages đã cấu hình
flutter pub get --enforce-lockfile
```

### Kiểm workspace

```powershell
# Tại root, sau khi Flutter/Python đã có trong PATH
python scripts/check-monorepo.py
.\scripts\check-workspace.ps1
# Thêm APK debug và Web release:
.\scripts\check-workspace.ps1 -Build
```

Dart Pub workspace giữ một lockfile chung; mỗi client tự bootstrap Firebase.
Không deploy khi chạy các check này. Các số test/evidence Lab 3 phía dưới là
lịch sử theo commit; bằng chứng migration có nguồn riêng.

### Bước 2: Chạy ứng dụng trên thiết bị Android
```bash
# Xem danh sách thiết bị/máy ảo đang kết nối
flutter devices

# Chạy ứng dụng ở chế độ Debug
cd mobile
flutter run
```

### Chạy Web Admin (mở terminal tại root repo)

Web Admin dùng entrypoint riêng và chỉ cho phép role `staff`/`admin`:

```bash
cd web
flutter run -d chrome
```

Build release dùng cho Firebase Hosting:

```bash
# Tại thư mục web/
flutter build web --release
```

Output tính từ root repo là `web/build/web`. Cấu hình SPA Hosting và Firestore rules mapping nằm ở
`firebase.json`. Không chạy `firebase deploy` nếu tài khoản chưa có quyền trên
project `longvita-8da7e`; deploy production phải được owner cho phép và phải lưu
evidence URL mở ở cửa sổ ẩn danh.

Các màn hình Web hiện có:

- Sign-in Google và role gate `staff/admin`;
- quản lý Recipes: tìm kiếm, tạo, sửa, archive/restore;
- hàng đợi thực đơn `submitted`: approve/reject kèm lý do;
- Dashboard với ba metrics và biểu đồ responsive;
- Remote Config guidance và Analytics cho approve/reject. Announcement Form
  và sự kiện `publish_announcement` chỉ hoàn tất khi CM-07 nối hành động ghi
  Firestore thật.

---

## 5. Hướng Dẫn Chạy Bộ Test E2E ARTEMIS

1. Thiết lập môi trường ảo Python trong thư mục `e2e_test/`:
   ```bash
   cd e2e_test
   uv venv
   source .venv/bin/activate  # Trên Windows: .venv\Scripts\activate
   uv pip install -e .
   ```
   Trên máy Windows đã chuẩn bị, có thể dùng
   `scripts/verify-setup.ps1 -RestoreDependencies` thay cho các lệnh thủ công.
   Sao chép `e2e_test/.env.example` thành `e2e_test/.env` rồi điền cấu hình
   runtime; file `.env` thật đã bị `.gitignore` loại khỏi Git.
2. Thiết lập biến môi trường API Key (không commit file chứa key):
   ```bash
   export ARTEMIS_BASE_URL="http://127.0.0.1:8000"  # Daemon ARTEMIS, chạy từ checkout của google/artemis tại commit đã pin, với GEMINI_API_KEY
   export ANDROID_SERIAL="emulator-5554"  # Hoặc serial của thiết bị adb
   export ARTEMIS_PROFILE="flash"         # "flash" cho regression; "pro" cho exploratory
   export ARTEMIS_FLASH_MODEL="gemini-3.5-flash-lite" # Multimodal model toc do cao cho regression
   export ARTEMIS_PRO_MODEL="gemini-3.8-flash"        # Multimodal model suy luan sau cho exploratory
   export FCM_TEST_TITLE="tiêu đề tin"    # Tin gửi từ Console trước khi chạy TC-10
   ```
3. Chạy toàn bộ test suite bằng pytest:
   ```bash
   pytest -v
   ```

---

## 6. Video Demo & Bằng Chứng Trực Tuyến

- **Demo Video Link:** `[Đường link YouTube / Google Drive mở công khai]` *(Sẽ cập nhật trước hạn nộp tại Task S8-15)*
- **Báo cáo PDF:** [`report/Lab03_<StudentID>.pdf`](report/)
- **Slide Deck PDF:** [`slides/Lab03_<StudentID>_slides.pdf`](slides/)

### Final Assignment deliverables

- **Web Hosting URL:** [https://longvita-8da7e.web.app](https://longvita-8da7e.web.app)
  — đã kiểm tra HTTP 200, cửa sổ ẩn danh, đăng nhập `admin` và chặn `user` ngày
  10/11/2026; xem [bằng chứng TV-00](evidence/web/TV-00-20261110/README.md).
- **Repository:** [github.com/ruxenb/LongvitaRC](https://github.com/ruxenb/LongvitaRC).
- **Cross-role flow:** đặc tả, sequence diagram và bảng đo ba lượt tại
  [`docs/cross-role-flow.md`](docs/cross-role-flow.md); số đo live còn để trống.
- **Web Admin checklist:** [`docs/web-admin-checklist.md`](docs/web-admin-checklist.md),
  evidence index tại
  [`evidence/web/TV-04B-20261110/`](evidence/web/TV-04B-20261110/README.md).
- **Final Report:** `report/Final_<ID>.pdf` — chưa xuất bản.
- **Final Slides:** `slides/Final_<ID>_slides.pdf` — chưa xuất bản.
- **Final Demo Video:** link public/unlisted — chưa có.

---

## 7. Trạng thái bàn giao và AI disclosure

- **Nội dung báo cáo của Thắng:** [`docs/report-drafts/s8-1-thang.md`](docs/report-drafts/s8-1-thang.md).
- **Nội dung slide của Thắng:** [`docs/report-drafts/s8-9-slides-thang.md`](docs/report-drafts/s8-9-slides-thang.md); đã chốt nội dung/evidence ngày 08/11, chưa phải deck PDF cuối.
- **Kịch bản clip của Thắng:** [`docs/report-drafts/s8-14-thang-clip-script.md`](docs/report-drafts/s8-14-thang-clip-script.md); chưa quay clip thật.
- **Audit bảo mật/Git/Project ID gần nhất:** [`evidence/audit/S9-1-S9-4-20261108/`](evidence/audit/S9-1-S9-4-20261108/README.md).
- Report PDF, slide PDF và video public vẫn là placeholder cho đến khi S8-5,
  S8-10 và S8-15 hoàn tất.

AI đã được dùng có kiểm soát; output AI không được tính là bằng chứng runtime
nếu không có log, ảnh hoặc run tương ứng.

| Công cụ AI | Phạm vi sử dụng | Bằng chứng / giới hạn |
|:---|:---|:---|
| **OpenAI Codex** | Phân tích repository, hỗ trợ viết test, review, tài liệu và chuẩn bị deploy | Mọi thay đổi phải qua diff, test và review; runtime claim cần bằng chứng riêng |
| **CodeRabbit** | Review tự động trên pull request | Finding và quyết định Accept/Modify/Reject được tổng hợp tại [`docs/code-review.md`](docs/code-review.md) và `evidence/review/` |
| **Google ARTEMIS + Gemini** | Điều khiển/đánh giá luồng E2E trên thiết bị | Chỉ công nhận kết quả có trace/run trong [`evidence/artemis/`](evidence/artemis/README.md); compile/collect test không đồng nghĩa E2E pass |

### Trạng thái phần việc Thắng VLQ — 10/11/2026

- TV-00 đã deploy production tại https://longvita-8da7e.web.app; HTTP, cửa sổ
  ẩn danh, Google OAuth và role gate `admin`/`user` đã được kiểm tra.
- TV-01, TV-02, TV-03 và TV-03B đã có implementation, test/evidence local trên
  PR #25, đã merge vào `main` tại `ea7b888`.
- TV-04 đã hoàn thành phần đặc tả và quy trình đo; chưa có ba lượt live.
- TV-04B đã có checklist/evidence index; chưa có ảnh production.
- TV-05 đã cập nhật URL, hướng dẫn chạy, roles, tài khoản demo, phiên bản, AI
  disclosure và deliverable map. Task còn chờ nhóm cấp tài khoản `staff` riêng,
  cùng link video, report PDF và slide PDF cuối trước khi đánh dấu hoàn thành.
- Không tuyên bố DebugView Web, Remote Config Console hoặc deliverable cuối đã
  pass nếu chưa có evidence live tương ứng.

---

## 8. Vai trò, Admin đầu tiên và quản lý role (Final, CM-05)

Role của mỗi tài khoản nằm ở trường `role` trong document Firestore `users/{uid}`. Schema và quyền từng collection: [`docs/data-model.md`](docs/data-model.md).

| Role | Client | Cách có role này |
|:---|:---|:---|
| `user` | Mobile | Tự tạo ở lần đăng nhập đầu tiên trên Mobile (`AuthService` ghi `role = 'user'`). |
| `staff` | Web Admin | Admin đổi role của tài khoản đó thành `staff`. |
| `admin` | Web Admin | Admin đầu tiên đặt trong Firebase Console; các admin sau do admin cấp. |

### Admin đầu tiên

- **Admin đầu tiên: Charlie (CharlieMinh).** Đặt trực tiếp trong Firebase Console của project `longvita-8da7e`, vì không client nào được tự nâng role của mình.
- Charlie đã cấp tiếp `role = 'admin'` cho tài khoản Google của Thái An, Hoàng và Thắng. Cả bốn thành viên cũng có quyền quản trị project Firebase (Project settings → Users and permissions).
- README không ghi email hoặc UID. Danh sách tài khoản xem trong Console.

Cách đặt Admin đầu tiên (chỉ người có quyền quản trị project làm được):

1. Đăng nhập Mobile một lần bằng tài khoản cần làm admin, để `users/{uid}` được tạo với `role = 'user'`.
2. Firebase Console → Firestore Database → collection `users` → document của tài khoản đó.
3. Sửa trường `role` từ `user` thành `admin` (kiểu string), lưu lại.
4. Đăng xuất và đăng nhập lại để client đọc role mới.

### Quy tắc đổi role

Rules trong [`firebase/firestore.rules`](firebase/firestore.rules), match `users/{uid}`:

- Chỉ admin đổi role, chỉ trường `role`, chỉ của **người khác**. Không ai tự đổi role của mình, kể cả admin. Giá trị hợp lệ: `user`, `staff`, `admin`.
- Không client nào tạo hồ sơ với role cao hơn `user`, và không client nào xoá hồ sơ.
- Test trên Emulator: R-03 (user tự nâng role → Denied), R-06 (admin đổi role người khác → Allowed), R-07 (admin tự đổi role → Denied) trong `firebase/tests/firestore.rules.matrix.test.js`, cùng các ca chi tiết trong `firebase/tests/firestore.rules.test.js`. Chạy: `cd firebase && npm ci && npm run test:rules`.

Lưu ý: chỉnh sửa trong Firebase Console dùng quyền quản trị project nên **không đi qua Security Rules**. Vì vậy nhóm thống nhất chỉ dùng Console để đặt Admin đầu tiên và cấp role, không ai tự đổi role của chính mình, và mỗi lần đổi role ghi vào worklog của người thực hiện. App chưa có màn hình quản lý role.

### Tài khoản demo theo role

Web dùng Google OAuth nên repository **không lưu mật khẩu**. Chủ tài khoản tự
đăng nhập khi demo; không chia sẻ mật khẩu, token hoặc UID qua Git.

| Role | Tài khoản đã kiểm tra | Client / kết quả ngày 10/11/2026 |
|:---|:---|:---|
| `user` | `phamvanminh150204@gmail.com` | Web xác thực Google thành công nhưng hiển thị “Tài khoản không có quyền”, đúng role gate. |
| `staff` | **Chưa được nhóm cung cấp** | Cần một Google account riêng đăng nhập lần đầu, sau đó admin đổi `users/{uid}.role` thành `staff`. |
| `admin` | `thangvlqse184739@fpt.edu.vn` | Web đăng nhập thành công và mở Dashboard production. |

Các admin bổ sung đã xác minh trong Firestore: `minhpvse183365@fpt.edu.vn` và
`duongvuthaian@gmail.com`. Tài khoản Hoàng chưa xuất hiện trong Firebase Auth ở
lần kiểm tra này, vì vậy README không tuyên bố đã cấp role cho tài khoản đó.
