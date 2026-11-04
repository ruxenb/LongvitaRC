# S0-3-VLQ / S3-6 — Android và routing smoke test (04/11/2026)

## Môi trường

- Flutter 3.47.9, Dart 3.13.7.
- Android SDK/API 36, emulator `Longvita_API_36` (`emulator-5554`), Android 16.
- Debug APK build, cài đặt và chạy thành công.
- `flutter doctor -v`: không có lỗi.
- `flutter analyze`: không có lỗi.
- `flutter test`: 305/305 test pass.

## Kết quả routing/back

- AuthGate mở Sign-in khi signed-out; Back ở route gốc về Android launcher.
- Mở lại app khôi phục phiên Firebase và vào Dashboard.
- S02 Tạo thực đơn, S10 Kế hoạch đã lưu, Tra cứu công thức và Hồ sơ đều mở được từ Dashboard.
- Phím Back từ bốn route trên đều quay về Dashboard.

## Ảnh bằng chứng

- `01-s10-saved-plans.png`: màn S10 và nút Back.
- `02-recipe-catalog.png`: màn Tra cứu công thức và nút Back.
- `03-profile-firebase-services.png`: phần Remote Config/Crashlytics trong Hồ sơ, không chứa email.
- `04-s02-preferences.png`: màn S02 Sở thích ăn uống, form thiết lập thực đơn và nút Back.

Ảnh Hồ sơ có tên/email chỉ được dùng để đối chiếu tại chỗ và không đưa vào repository công khai. Các ảnh tĩnh chứng minh màn hình/Back affordance; kết quả Back về Dashboard được xác nhận bằng native UI dump sau thao tác ADB.

## Giới hạn

Smoke test này xác nhận môi trường Android và routing/back. Nó không thay thế ARTEMIS 3-run, kiểm thử failure cases của sáu Firebase services hoặc bằng chứng Firebase Console.
