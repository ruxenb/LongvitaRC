# Longvita Android

Flutter client độc lập, dùng `longvita_core` từ `../packages/core`.
Từ root repo, chạy `flutter pub get --enforce-lockfile`, sau đó:

```powershell
cd mobile
flutter run
# Kiểm và build trong client:
flutter analyze --no-pub lib test
flutter test --no-pub
flutter build apk --debug
```

Xem [bản đồ kiến trúc](../docs/monorepo-migration.md) và README root cho
Firebase/evidence. Firebase app ID và môi trường đã đăng ký được giữ nguyên.
