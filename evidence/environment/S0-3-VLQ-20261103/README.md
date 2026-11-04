# S0-3-VLQ — Môi trường máy Thắng, 03/11/2026

## Kết quả nghiệm thu

| Thành phần | Kết quả |
|---|---|
| Flutter / Dart | Flutter 3.47.9 stable, Dart 3.13.7 |
| Java | Eclipse Temurin 21.0.7 |
| Android SDK | `T:\Android\Sdk`, Android 34/35/36, Build Tools 34/36 |
| Android tools | ADB 37.0.1, Emulator 37.2.13, NDK 28.2.13676358, CMake 3.22.1 |
| AVD | `Longvita_API_36`, Google APIs x86_64, Android 16/API 36 |
| Firebase tooling | Firebase CLI 15.34.2, FlutterFire CLI 1.4.1 |
| Python / ARTEMIS | Python 3.12.16, uv 0.13.7, pinned ARTEMIS client cài được |

Các lệnh kiểm chứng đã chạy trong phiên thiết lập:

- `flutter doctor -v`: **No issues found**, Android licenses accepted.
- `flutter devices`: nhận `emulator-5554` là Android API 36.
- `flutter build apk --debug`: tạo thành công
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `adb install -r .../app-debug.apk`: `Success`; tiến trình
  `vn.edu.fpt.longvita` chạy trên emulator.
- `flutter analyze`: no issues.
- `flutter test`: 270/270 pass.
- `pytest --collect-only -q`: 7 E2E tests collected.

## Debug certificate cần đăng ký Firebase

- Package: `vn.edu.fpt.longvita`
- SHA-1: `9D:9C:D3:03:14:86:02:C5:5A:3A:5E:68:97:22:35:4C:19:F6:D5:71`
- SHA-256: `DF:E1:24:36:77:DE:ED:4C:85:17:B4:7A:DC:16:4B:14:5B:7E:6A:EE:5B:3B:75:C2:2B:55:29:3F:0D:A9:9A:0A`
- Keystore local nằm ngoài repo tại `T:\Android\user-home\debug.keystore` và
  bị loại khỏi Git theo `*.keystore`.

## Giới hạn

- Emulator đã được tắt sau kiểm chứng; AVD/data vẫn lưu trên ổ T.
- Google Sign-In bằng certificate này chưa được nghiệm thu vì đang chờ Firebase
  owner thêm SHA-1/SHA-256 và cấp lại client config nếu cần.
- Không commit APK, Android SDK, AVD, keystore, cache hoặc credentials vào repo.
