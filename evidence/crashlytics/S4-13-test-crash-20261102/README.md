# Crash thử lên Crashlytics thật, 02/11/2026

Nút "Gây crash thử" trên Profile, qua hộp xác nhận, trên AVD `LocalMate_API_35`, bản debug, project `longvita-8da7e`. Thái An đồng ý thêm plugin `com.google.firebase.crashlytics` 3.0.6 vào Gradle.

| Bước | Kết quả |
|---|---|
| Xác nhận gây crash | Log thiết bị có `FATAL EXCEPTION`, `FirebaseCrashlyticsTestCrash` |
| Mở lại app | Báo cáo được gửi |
| `console-crashlytics.jpg` | Console có 1 issue, 1 event, `FlutterFirebaseCrashlyticsPlugin.lambda$crash$1` |

Đây là crash thử, nên chỉ số "Crash-free users" trên ảnh không phản ánh chất lượng app.

## Giới hạn

- Chưa nối `FlutterError.onError` và `PlatformDispatcher.onError`, nên lỗi Flutter không bắt được chưa tự lên Crashlytics. Lỗi app đã bắt vẫn gửi qua `recordError`. Phần này thuộc S5-6 của Thái An, đã báo để chốt.
- Chưa kiểm non-fatal và custom key trên Console.
