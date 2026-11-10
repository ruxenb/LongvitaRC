# Kiến trúc Longvita Final — CM-00 / CM-02

Baseline: `ea7b888` (PR #25 đã tích hợp). Bảng giao việc:
[`final-task-assignment.md`](tasks/final-task-assignment.md).

## Mốc CM-00: khung và bản đồ migration

CM-00 chuẩn bị `mobile/`, `web/`, `packages/core/` và evidence
`auth/`, `rules/`, `web/`, `cross_role/`, `ai/`. Package Core ở mốc này chỉ là
boundary, **chưa phải implementation hoàn tất**. Các entrypoint root vẫn hoạt
động trong mốc chuẩn bị. Không chép logic sang hai client để tạo khung.

## Cấu trúc CM-02 đã triển khai

```text
pubspec.yaml / pubspec.lock   # workspace và một resolution chung
mobile/
  lib/                       # Mobile screens, VM, native services/bootstrap
  android/                   # giữ nguyên applicationId và cấu hình native
  assets/                    # PDF fonts và assets riêng của Mobile
  test/
web/
  lib/                       # Admin screens, VM, auth popup/bootstrap
  web/                       # scaffold nền tảng Flutter Web hiện có
  test/
packages/core/
  lib/models/                # schema/serialization giữ nguyên
  lib/services/              # Firestore data access và interfaces chung
  lib/firebase/              # Analytics/Remote Config dùng ở hai client
  lib/theme/                 # tokens/theme theo Lab 2
  lib/widgets/               # 9 nhóm common widgets và state views
  assets/fonts/              # UI fonts và giấy phép dùng chung
  test/
firebase/                    # canonical rules/emulator tests ở root
e2e_test/ / test_support/     # harness ARTEMIS và offline regression ở root
evidence/                    # một thư mục bằng chứng chung
```

Luồng phụ thuộc: Mobile → Core ← Web. Core không import client; Web không
import Mobile. PDF local, path_provider/printing, storage demo, FCM nền,
Crashlytics và lifecycle riêng của client không kéo vào Core/Web. Domain
models, serialization, Firestore collections/rules, role/status và nghiệp vụ
không đổi chỉ vì đổi package.

Khối Firestore service dùng chung bao gồm Mobile DataService, metadata
repository và AdminService. VM/route/role gate của Admin tiếp tục nằm phía Web.
Chín nhóm widget: Button, IconButton, TextField, Card, Badge, Navigation,
TopBar, Dialog, Supporting; state views đi cùng design system.

## Quy tắc di chuyển

- Dùng Dart Pub workspace với SDK đang có: Flutter 3.47.6 / Dart 3.13.5;
  mỗi member `resolution: workspace`, root giữ một `pubspec.lock`.
- Giữ các hosted version/digest đã khóa. Chỉ bổ sung các package workspace;
  không nâng thư viện hoặc Gradle để thực hiện migration.
- UI fonts và OFL có một nguồn ở Core. Font/asset package paths phải được
  kiểm bằng manifest, licence loading và layout tests của cả hai client.
- Hai entrypoint vẫn tự khởi tạo Firebase; giữ project/App ID/Android SHA,
  không chạy configure tạo app, đổi quyền, billing hay deploy.
- Tất cả test hiện có phải được chuyển đúng owner package; không xóa test
  hoặc giảm expected để che lỗi đường dẫn. File fixture QA không vào app build.
- Cập nhật lệnh chạy/build, Firebase Hosting/config paths, scripts và các
  đường dẫn active. Evidence lịch sử giữ nguyên và ghi đúng commit nguồn.

## Cổng kiểm

CM-00: khung đủ, bản đồ rõ, không runtime source change, diff sạch.
CM-02: core/member analysis, các test đã phân bổ, APK Mobile và Web release
build, dependency boundaries, UI/font/assets, Firebase ID/config/rules và
hosted lock versions đều được kiểm. Kết quả phải ghi đúng fake/offline/native;
không gọi việc build là đã deploy hay đã chạy live cross-role.

## Làm việc sau migration

- Từ root: `flutter pub get --enforce-lockfile`,
  `python scripts/check-monorepo.py`; script `scripts/check-workspace.ps1`
  chạy analysis/test cho từng member (thêm `-Build` để build hai client).
- Chạy Android tại `mobile/`: `flutter run`; Web tại `web/`:
  `flutter run -d chrome`. Không dùng entrypoint `lib/admin_main.dart` cũ.
- Test của Mobile ở `mobile/test/`, Admin ở `web/test/`; Analytics và metadata
  model tests ở `packages/core/test/`. ARTEMIS/rules/evidence vẫn ở root.
- `firebase.json` Hosting trỏ `web/build/web`; chỉ đường dẫn output thay đổi,
  không phải một lần deploy. Không chạy configure để tạo lại Firebase apps.
- Các thành viên đang có branch cũ nên tích hợp migration trước khi sửa tiếp;
  chuyển thay đổi sang đường dẫn tương ứng, không khôi phục root `lib/` hoặc
  chép lại shared models vào client. Không bỏ thay đổi của đồng đội khi có
  conflict. Evidence trước migration giữ nguyên đường dẫn/commit lịch sử.
- Bằng chứng kiểm gói: `evidence/architecture/CM-00-CM-02-20261110/`.

Nguồn kỹ thuật chính thức: [Dart Pub workspaces](https://dart.dev/tools/pub/workspaces),
[Flutter package assets](https://docs.flutter.dev/ui/assets/assets-and-images),
[Flutter package fonts](https://docs.flutter.dev/cookbook/design/package-fonts).
