# Tooling setup — Thắng VLQ — 04/11/2026

## Storage policy

Mọi công cụ, cache, môi trường ảo, evidence và artifact mới của Longvita ưu tiên ổ `T:`. Không di chuyển thủ công ứng dụng đã cài từ trước; nếu công cụ không hỗ trợ vị trí tùy chọn thì phải báo trước khi cài.

## Android / Flutter

- Flutter 3.47.9, Dart 3.13.7: `T:\Flutter\flutter`.
- Android SDK/API 36 và ADB: `T:\Android\Sdk`.
- Emulator: `Longvita_API_36`, Android 16/API 36.
- `flutter doctor -v`: không có lỗi.
- `flutter analyze`: không có lỗi; `flutter test`: 305/305 pass tại mốc kiểm tra routing.

## Firebase

- FlutterFire CLI 1.4.1: `T:\Tools\PubCache\bin`.
- Firebase CLI 15.34.2: `T:\Tools\npm-global`.
- Firebase CLI đã đăng nhập bằng tài khoản Thắng và xác nhận có quyền project `longvita-8da7e`.
- `android/app/google-services.json` trỏ đúng project `longvita-8da7e`.
- Dependencies rules test: `firebase/node_modules` trên ổ `T:`; `test/firestore/node_modules` dùng junction tới cùng bộ dependencies để tránh tải trùng.
- Firebase emulator cache được chuyển bằng `FIREBASE_EMULATORS_PATH` tới `T:\Tools\firebase-emulators`.
- Remote Config template đọc từ cloud ngày 04/11 đang rỗng `{}`; file defaults trong repo chưa được publish. Không deploy/publish nếu chưa có team approval.

- Firestore emulator JAR 1.22.0 đã tải đủ tại `T:\Tools\firebase-emulators\cloud-firestore-emulator-v1.22.0.jar`; Storage rules runtime cũng được cache trên ổ `T:`.
- `test/firestore`: **22/22 pass** với project demo và Firestore Emulator.
- `firebase`: **55/55 pass** với Firestore + Storage Emulator.
- Lần chạy trong sandbox bị chặn mở cổng localhost 4400/8185; chạy emulator ngoài sandbox đã xác nhận đây là giới hạn môi trường, không phải lỗi rules.

## Google ARTEMIS

- Source được clone đúng commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` tại `T:\Tools\artemis`.
- Python 3.12.16 và 196 packages ARTEMIS nằm trong `T:\PRM393\lab_3\LongvitaRC\e2e_test\.venv`.
- ARTEMIS client, daemon CLI và 18 E2E tests import/collect thành công.
- `ARTEMIS_APP_DIR=T:\Tools\artemis-data`.
- `ARTEMIS_TRACES_DIR=T:\PRM393\lab_3\LongvitaRC\evidence\artemis\raw`.
- ARTEMIS doctor đạt các mục bắt buộc: Python, system config, model credential, ADB device, FFmpeg, scrcpy, Node/npm và Showcase UI.
- Accessibility Helper v1.2.0/code 6 đã cài và enable trên `emulator-5554`.
- OCR key là tùy chọn; ARTEMIS dùng UI XML khi không có OCR key.

Không ghi API key vào repo hoặc tài liệu này. Credential chỉ được đọc từ environment/secure configuration hiện có.

## Review / security / video

- GitHub CLI 2.103.3 portable: `T:\Tools\github-cli`; đã đăng nhập tài khoản `Vu-Luong-Quang-Thang`, quyền `WRITE` trên `ruxenb/LongvitaRC`.
- Gitleaks 8.30.1 portable: `T:\Tools\gitleaks`.
- Gitleaks đã quét đủ 111 commits; báo cáo redacted lưu ngoài repo tại `T:\Tools\longvita-gitleaks-redacted.json`. Có 4 findings lịch sử cần audit ở S9-1; chưa tự động sửa hoặc rewrite history.
- FFmpeg 7.1 portable: `T:\Tools\ffmpeg\bin`.
- scrcpy 5.0.1 portable: `T:\Tools\scrcpy`.
- Các đường dẫn trên đã được thêm vào User PATH.
- Word, PowerPoint và Node.js là ứng dụng có sẵn từ trước trên `C:`; không di chuyển thủ công. Các project output/cache mới vẫn phải lưu ở `T:`.
- Không cần OBS để chạy task hiện tại: scrcpy + FFmpeg + Android `screenrecord` đủ cho capture/replay; PowerPoint có thể dùng để ghép phần trình bày. Chỉ cài OBS vào `T:` nếu workflow video cuối thực sự cần.

## Việc còn cần quyết định hoặc dữ liệu bên ngoài

1. Team approval trước khi deploy Firestore/Storage rules hoặc publish Remote Config.
2. Publish ít nhất hai Remote Config parameters và lưu ảnh before/after nếu thực hiện task tương ứng.
3. Chạy ARTEMIS formal cases trên emulator/device; mỗi test cần raw trace và số lần chạy theo test plan.
4. Audit 4 findings Gitleaks bằng output redacted trước khi xử lý; không đưa secret thật vào issue/report và không rewrite history nếu chưa có quyết định của team.
