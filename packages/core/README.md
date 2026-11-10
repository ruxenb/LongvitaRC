# Longvita Shared Core — CM-02

Package `longvita_core` thuộc Dart Pub workspace tại root. Mobile và Web phụ
thuộc cùng package `longvita_core: 1.0.0` với `resolution: workspace`; không có
bản sao models/services/theme trong hai client.

```dart
import 'package:longvita_core/longvita_core.dart';
// Hoặc import hẹp theo module:
import 'package:longvita_core/models/meal_plan_model.dart';
```

Barrel và các module dưới `lib/models`, `lib/services`, `lib/theme`,
`lib/widgets`, `lib/firebase`, `lib/l10n` là public API được hỗ trợ. Chưa có
implementation trong `lib/src`; nếu bổ sung thì client không import `src/`.
Đổi đường dẫn public là thay đổi API cần cập nhật consumers, không chỉ là
di chuyển nội bộ. Quy ước này theo [Dart package layout](https://dart.dev/tools/pub/create-packages).

- `models/`: domain, serialization và shared state types.
- `services/`: DataService, AdminService, metadata repository và contracts.
- `firebase/`: Analytics và Remote Config dùng được trên cả hai client.
- `theme/`, `widgets/`, `l10n/`: tokens Lab 2, theme, 9 nhóm common widgets,
  supporting/state views và nhãn Material tiếng Việt.
- `assets/fonts/`: Fraunces, Newsreader, Quicksand và giấy phép OFL. Font family
  trong AppTypography đã có namespace package; không khai báo lại ở client.

Core không bootstrap Firebase. Client khởi tạo Firebase trước khi tạo services
và tự quản lý session/role gate. PDF file I/O, FCM, Crashlytics, Google Sign-in
native và Storage demo vẫn ở Mobile; Core không import ngược client.

Tại root: `flutter pub get --enforce-lockfile`. Sau đó tại `packages/core/`:

```shell
flutter analyze --no-pub lib test
flutter test --no-pub
```

Xem [bản đồ migration](../../docs/monorepo-migration.md) và chạy
`python scripts/check-monorepo.py` từ root để kiểm ranh giới/cấu hình.
