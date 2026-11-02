# Longvita — Cloud-Enabled Mobile App

> **Cập nhật 02/11/2026:** **Lab 3 chính là Assignment** đang triển khai, kế thừa thiết kế Lab 2. Xem [bàn giao kỹ thuật và tiến độ Charlie](docs/tasks/charlie-progress.md) cho phạm vi nhánh, kiểm chứng và các quyết định cần team review. Giữ 112 task IDs/owners; các phần mobile/web/shared-core là cùng sản phẩm. Nhánh hiện chưa chứng minh đủ sáu Firebase services hoặc toàn bộ E2E.
>
> **Firebase project:** `longvita-8da7e`, app Android `vn.edu.fpt.longvita` (S0-4). Chưa mời đủ thành viên và SHA.
>
> SDK máy kiểm tra: Flutter 3.47.6/Dart 3.13.5; bảng tool bên dưới ghi baseline team, cần chốt khi ghim. `pubspec.lock` là resolved package versions; `^` trong pubspec không phải exact pin. Storage/Spark, application ID và rubric khác nhau đang được ghi trong DEC-01..04.

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

## 2. Pinned Tool Versions (Phiên Bản Công Cụ Đã Ghim)

Tuân thủ yêu cầu bắt buộc của Handout Mục 3 & 9 về việc ghim phiên bản để tránh xung đột môi trường:

| Công cụ / Nền tảng | Phiên bản ghim (Pinned Version) | Ghi chú cấu hình |
|:---|:---|:---|
| **Flutter SDK** | `3.47.2` (channel stable) | `flutter --version` |
| **Dart SDK** | `3.13.2` | Đi kèm với Flutter 3.47.2 |
| **Android SDK Platform** | API 34 (Android 14) / Min SDK 21 | Cấu hình trong `android/app/build.gradle.kts` |
| **Python** | `3.12+` | Dành cho Google ARTEMIS Test Suite |
| **Google ARTEMIS** | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (Apache 2.0) | Pin tại `e2e_test/pyproject.toml`; chưa có raw run |
| **Firebase Packages** | Core `3.15.2`, Auth `5.7.0`, Storage `12.4.10`, Messaging `15.2.10`, Analytics `11.6.0`, Crashlytics `4.3.10`, RemoteConfig `5.5.0`, Firestore `5.6.12` | Quản lý trong `pubspec.yaml` |
| **State Management** | `provider: ^6.1.2` | MVVM Architecture Dependency Injection |

---

## 3. Bản Đồ Nơi Lưu Trữ Sản Phẩm Bàn Giao (Deliverable Map)

Cấu trúc thư mục chuẩn theo Mục 9 của Handout PRM393 Lab 3:

```text
PRM393_Lab03_<StudentID>/
├── README.md                          # Tài liệu giới thiệu, hướng dẫn chạy, ghim version, link video
├── pubspec.yaml                       # Quản lý dependencies và asset declarations
├── analysis_options.yaml              # Cấu hình bộ linter tiêu chuẩn cho Flutter/Dart
├── .gitignore                         # Loại bỏ secret, keystore, env; cho phép google-services.json
├── lib/                               # Tầng kiến trúc MVVM (Core-Package-Ready đón đầu Assignment)
│   ├── # --- Cụm Shared Core (sẵn sàng chuyển thành packages/core khi lên Assignment) ---
│   ├── models/                        # Plain Dart data classes (User có role, MealPlan có status, Recipe, Ingredient...)
│   ├── services/                      # Service interfaces & Cloud Firestore services (DataService, AuthService, ReportService)
│   ├── firebase/                      # Wrappers dịch vụ Firebase (Crashlytics, Analytics, Remote Config)
│   ├── theme/                         # Tokens: ColorScheme, TextTheme, AppSpacing, AppRadius
│   ├── widgets/                       # 9 component dùng chung theo tokens Lab 2
│   ├── # --- Cụm Mobile App (sẽ chuyển thành mobile/ khi lên Assignment) ---
│   ├── viewmodels/                    # ViewModels quản lý explicit state model (ViewState)
│   ├── screens/                       # 10 màn hình Lab 2 + SignInScreen + ProfileScreen
│   ├── utils/                         # Hàm bổ trợ & tiện ích
│   └── main.dart                      # Điểm vào chính của ứng dụng Flutter & MultiProvider setup
├── e2e_test/                          # Bộ kiểm thử E2E Google ARTEMIS (Section 7)
│   ├── conftest.py                    # Khởi tạo client, device serial, profile Flash/Pro
│   ├── pyproject.toml                 # Cấu hình môi trường Python 3.12+ & pytest
│   └── test_*.py                      # Kịch bản kiểm thử tự động theo từng module nghiệp vụ
├── android/                           # Cấu hình nền tảng Android (chứa google-services.json)
├── firebase/                          # Cấu hình dịch vụ Firebase
│   ├── storage.rules                  # Security rules giới hạn reports/{uid}/...
│   └── remote-config-defaults.json    # Giá trị mặc định in-app cho Remote Config
├── docs/                              # Hồ sơ kỹ thuật của Lab 3
│   ├── tasks/                         # Bảng phân chia 112 tasks và tiến độ nhóm 4 người
│   ├── design-traceability.md         # Ma trận truy vết thiết kế Lab 2 -> Flutter & Deviation log
│   ├── architecture.md                # Tài liệu kiến trúc MVVM, Mermaid layer diagram, sequence
│   ├── analytics-plan.md              # Kế hoạch đo lường sự kiện Firebase Analytics (Appendix A)
│   ├── test-plan.md                   # Kế hoạch kiểm thử tự động ARTEMIS (Appendix B)
│   ├── code-review.md                 # Sổ ghi nhận kết quả AI Code Review (Appendix C)
│   ├── service-contracts.md            # Baseline service interfaces/wrappers và ViewModel
│   └── worklog-thang.md                # Tiến độ, bằng chứng, lỗi và blocker của Thắng
├── evidence/                          # Toàn bộ bằng chứng nghiệm thu (Mục 11)
│   ├── auth/                          # Ảnh chụp màn hình đăng nhập, tab Users trên Firebase console
│   ├── storage/                       # Ảnh chụp console file list under reports/{uid}/...
│   ├── fcm/                           # Bằng chứng nhận notification ở 3 trạng thái
│   ├── analytics/                     # Ảnh chụp Firebase DebugView cho 8 sự kiện
│   ├── crashlytics/                   # Ảnh chụp dashboard Crashlytics (non-fatal error + test crash)
│   ├── remote-config/                 # Ảnh chụp màn hình trước/sau khi đổi giá trị trên console
│   ├── artemis/                       # Traces, logs, pass-rate tables và video replay ARTEMIS
│   └── review/                        # Output thô xuất từ các công cụ AI review (PR review log)
├── report/
│   └── Lab03_<StudentID>.pdf          # Báo cáo tổng kết hoàn chỉnh (8–12 trang)
└── slides/
    └── Lab03_<StudentID>_slides.pdf   # Slide thuyết trình bảo vệ dự án (12–15 trang)
```

---

## 4. Hướng Dẫn Cài Đặt & Khởi Chạy Ứng Dụng (Barebone)

### Bước 1: Khởi tạo môi trường & lấy dependencies
```bash
# Kiểm tra môi trường Flutter
flutter doctor

# Tải toàn bộ packages đã cấu hình
flutter pub get
```

### Bước 2: Chạy ứng dụng trên thiết bị Android
```bash
# Xem danh sách thiết bị/máy ảo đang kết nối
flutter devices

# Chạy ứng dụng ở chế độ Debug
flutter run
```

---

## 5. Hướng Dẫn Chạy Bộ Test E2E ARTEMIS

1. Thiết lập môi trường ảo Python trong thư mục `e2e_test/`:
   ```bash
   cd e2e_test
   uv venv
   source .venv/bin/activate  # Trên Windows: .venv\Scripts\activate
   uv pip install -e .
   ```
2. Thiết lập biến môi trường API Key (không commit file chứa key):
   ```bash
   export ARTEMIS_BASE_URL="http://127.0.0.1:8000"  # Daemon ARTEMIS, chạy từ checkout của google/artemis tại commit đã pin, với GEMINI_API_KEY
   export ANDROID_SERIAL="emulator-5554"  # Hoặc serial của thiết bị adb
   export ARTEMIS_PROFILE="flash"         # "flash" cho regression; "pro" cho exploratory
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
