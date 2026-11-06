# S3-1 — FlutterFire configure, Firebase bootstrap và ghim phiên bản, 06/11/2026

- **Baseline:** `origin/main` `008a1a9` (sau PR #12 `3b34816`; các commit mới của Thắng/An chỉ đổi docs, evidence, scripts và README). Nhánh `feature/charlie-bootstrap-02`.
- **Firebase:** project `longvita-8da7e`, app Android duy nhất `1:1041459198085:android:33939d119fc3892d8e11ec`, package `vn.edu.fpt.longvita`. Không tạo app/project, không thêm iOS/Web, không đổi billing, rules hay chính sách Auth.
- **Lệnh và output đã lọc:** [`commands.txt`](commands.txt). Đã bỏ email tài khoản CLI và FCM token.

## Công cụ thực dùng trên máy Charlie

| Công cụ | Phiên bản | Nguồn |
|---|---|---|
| Flutter / Dart | 3.47.6 (stable, `5fc346839b`) / 3.13.5 | `flutter --version` |
| FlutterFire CLI | 1.4.1 | `flutterfire --version` (đã cài sẵn trong Pub cache, không nâng) |
| Firebase CLI | firebase-tools 15.34.2 | `firebase/node_modules`, `firebase --version` |
| Java | 21.0.12 | `java -version` |
| AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / wrapper 9.3.1 | `android/settings.gradle.kts`, `gradle-wrapper.properties` |
| google-services / Crashlytics Gradle | 4.5.0 / 3.0.6 | `android/settings.gradle.kts` |
| APK | compileSdk 36, targetSdk 36, minSdk 24 | `aapt2 dump badging` |

Đây là kết quả trên máy Charlie. Ba máy còn lại chưa gửi `flutter --version`; không suy ra họ dùng cùng SDK từ việc họ đăng nhập được ở S3-2.

## Ghim phiên bản

18 package hosted trong `pubspec.yaml` đổi từ `^x.y.z` sang đúng bản đang khóa trong `pubspec.lock`. `flutter` và `flutter_test` vẫn `sdk: flutter`; `environment.sdk` giữ `^3.13.2`.

| Package | Trước | Sau = bản resolved |
|---|---|---|
| firebase_core | ^3.6.0 | 3.15.2 |
| firebase_auth | ^5.3.1 | 5.7.0 |
| google_sign_in | ^6.2.2 | 6.3.0 |
| firebase_storage | ^12.3.4 | 12.4.10 |
| firebase_messaging | ^15.1.3 | 15.2.10 |
| firebase_analytics | ^11.3.3 | 11.6.0 |
| firebase_crashlytics | ^4.1.3 | 4.3.10 |
| firebase_remote_config | ^5.1.3 | 5.5.0 |
| cloud_firestore | ^5.4.4 | 5.6.12 |
| provider | ^6.1.2 | 6.1.5+1 |
| cupertino_icons | ^1.0.8 | 1.0.9 |
| pdf / printing / path_provider | ^3.11.1 / ^5.13.2 / ^2.1.4 | 3.13.1 / 5.15.1 / 2.1.6 |
| http / intl / google_fonts | ^1.2.2 / ^0.19.0 / ^6.2.1 | 1.6.0 / 0.19.0 / 6.3.3 |
| flutter_lints (dev) | ^6.0.0 | 6.0.0 |

- `flutter pub get --enforce-lockfile` thoát 0 trước và sau khi ghim.
- SHA-256 của `pubspec.lock` vẫn là `f70ebc51…cfed6a`; lockfile không đổi một byte.
- Không chạy `pub upgrade` hay `pub add`. Package transitive vẫn do lockfile khóa.

## FlutterFire configure

Charlie tự đăng nhập Firebase CLI (`firebase login`) trên trình duyệt; Claude không nhập credential. Lệnh:

```bash
flutterfire configure --project=longvita-8da7e --platforms=android --android-package-name=vn.edu.fpt.longvita --yes
```

CLI tìm thấy app sẵn có và dùng đúng App ID `…33939d119fc3892d8e11ec`. Liệt kê theo từng nền tảng trước và sau: Android 1 app, iOS và Web không có. Lệnh liệt kê không lọc in cùng một resource Android bốn lần; `--json` cho thấy bốn bản ghi giống hệt nhau, Danh sách theo từng nền tảng và App ID trước/sau là căn cứ xác nhận app được dùng lại.

**Soát diff sau configure:**

| File | Thay đổi | Đánh giá |
|---|---|---|
| `android/app/google-services.json` | Chỉ **thêm** 3 OAuth client Android (`client_type: 1`) cho SHA-1 của Thắng `9d9cd303…`, Hoàng `d3be85d5…`, An `ef32d1b3…` | Đúng các client đã đăng ký ở S3-2. API key, App ID, project, bucket, client của Charlie và web client `09p0…` không đổi |
| `lib/firebase_options.dart` (mới) | `DefaultFirebaseOptions.android`; nền tảng khác ném `UnsupportedError` | apiKey, appId, messagingSenderId, projectId, storageBucket khớp từng giá trị với `google-services.json` |
| `firebase.json` (mới, gốc repo) | Metadata FlutterFire: project, App ID, đường dẫn output | Để chạy lại configure. Không thay `firebase/firebase.json` của emulator/rules |
| Gradle (`settings`, `app`) | Không đổi | Plugin google-services và Crashlytics đã có sẵn, không bị đổi version |

## Bootstrap

- `FirebaseBootstrap` giờ mặc định gọi `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` theo [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup). Vẫn chỉ có một lần khởi tạo, bọc bởi `Firebase.apps.isEmpty`.
- Plugin google-services vẫn giữ, vì Crashlytics và Google Sign-in đọc resource native, ví dụ `default_web_client_id`. Hai nguồn cấu hình cùng sinh từ một app nên giá trị trùng nhau; logcat không có `duplicate-app`.
- Trên nền tảng chưa configure, `UnsupportedError` của `currentPlatform` được xếp vào `not-configured`. Có test mới cho trường hợp này.
- **Sửa trong `StartupGate`:** nếu Firebase khởi động xong nhưng một service ném lỗi khi tạo, trước đây `_running` kẹt ở `true` và app quay vòng mãi, không có Thử lại. Giờ lỗi này thành `BootstrapFailed('app-start')` và hiện màn lỗi kèm Thử lại. Test mới thất bại với mã cũ (không tìm thấy "Không thể khởi động ứng dụng") và đạt với mã mới.
- Không đổi `IAuthService`, `AuthGate`, luồng đăng nhập hay chính sách S3-5.

## Kiểm tra

- `flutter analyze --no-pub`: không có lỗi.
- `flutter test --no-pub`: 336/336, gồm 334 cũ và 2 test mới.
- `flutter build apk --debug --no-pub`: thành công. APK ký bằng `CN=Android Debug`, SHA-1 `2baa67bc…35ec`, trùng SHA của Charlie đã đăng ký.
- Cảnh báo build còn lại: `firebase_analytics` và `firebase_remote_config` vẫn áp Kotlin Gradle Plugin; Flutter tương lai sẽ yêu cầu Built-in Kotlin. Đây là việc cần tính khi nâng package sau này. S3-1 không nâng package hay toolchain.

## Native trên emulator

AVD `LocalMate_API_35` (Android 15, Google Play). Cài bằng `adb install -r`, giữ dữ liệu và phiên đăng nhập; không đăng xuất hay xóa dữ liệu.

| Ảnh | Bước | Kết quả |
|---|---|---|
| `01-cold-start-home.png` | Force-stop rồi mở APK build từ nhánh này | Khôi phục phiên tài khoản A (tài khoản trường của Charlie) vào Home. Profile Firestore có `ROLE: USER`, banner lấy từ Remote Config. Logcat: `FirebaseInitProvider: FirebaseApp initialization successful`; không có `duplicate-app`, `FATAL`, `ApiException` hay `Firebase start-up failed`. Chạy cold start lần 2 sau khi cài lại bản thường: cùng kết quả |
| `02-qa-injected-failure.png` | QA host `test/qa/startup_recovery_host.dart`, lần khởi động đầu **giả lập lỗi** | Màn "Không thể khởi động ứng dụng" kèm nút "Thử lại"; app không đi tiếp vào service nào. Logcat: `Firebase start-up failed: qa-injected …` |
| `03-qa-retry-loading.png` | Bấm "Thử lại" | "Đang khởi động Longvita" |
| `04-qa-retry-real-app.png` | Lần thử lại chạy `FirebaseBootstrap` và `buildAppScope` thật | Vào Home của A với dữ liệu thật |

Sau đó đã cài lại APK bình thường và kiểm app mở vào Home.

## Giới hạn

- Lỗi ở `02` là lỗi giả lập trong QA host. Nó chứng minh UI và logic phục hồi, không phải sự cố SDK hay mạng thật. Không xóa config thật hoặc phá Firebase để thử.
- Trường hợp thiếu `google-services.json` và lỗi tạo service được chứng minh bằng widget/unit test, không chạy native.
- Configure chỉ chạy cho Android, đúng như app hiện có; không có cấu hình iOS hay Web.
- Không chạy lại rules, ARTEMIS, TalkBack hay push thật: thay đổi chỉ chạm bootstrap và phiên bản package.

## PM review ngày 06/11/2026

PM kiểm độc lập mã và cấu hình tại `0dcdc1a`. `flutter pub get --enforce-lockfile` thoát 0. Cả 18 version ghim khớp lockfile, blob lockfile giữ nguyên so với `008a1a9`. Năm trường Firebase options khớp `google-services.json`. Ba Android OAuth client thêm vào khớp SHA-1 của S3-2. Các giá trị config còn lại giữ nguyên.

Lệnh liệt kê app chỉ đọc trên Firebase CLI trả đúng một app Android với App ID dự kiến, iOS 0 và Web 0. Lịch sử configure trước/sau do Dev cung cấp. PM đọc APK đã build bằng `aapt2` và xác nhận package, compile SDK 36, target SDK 36 và min SDK 24.

Analyzer sạch. Suite Flutter **336/336 đạt**, gồm ca lỗi tạo service và thử lại. PM xem ảnh màn lỗi và ảnh Home sau khi thử lại. Lượt chạy thiết bị và lỗi giả lập trong QA host là bằng chứng Dev. Hai thư mục QA phát sinh từ lần PM chạy suite được giữ local.
