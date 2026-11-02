import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý giám sát lỗi và crash ứng dụng (Firebase Crashlytics).
/// Tuân thủ quy định Handout Mục 6 & 7:
/// - Ghi nhận handled non-fatal error từ luồng thật kèm stack trace.
/// - Đính kèm User Identifier và Custom Key (module, flow_step).
/// - Cung cấp hàm kích hoạt test crash phục vụ quay video demo & nghiệm thu.
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  /// Gán User ID khi đăng nhập để theo dõi phiên gặp sự cố trên Dashboard
  Future<void> setUserId(String uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid);
    } catch (_) {}
  }

  /// Gán Custom Key phục vụ lọc lỗi theo module/tính năng trên Crashlytics Dashboard
  Future<void> setCustomKey(String key, Object value) async {
    try {
      if (value is String) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics.setCustomKey(key, value);
      } else {
        await _crashlytics.setCustomKey(key, value.toString());
      }
    } catch (_) {}
  }

  /// Helper gán ngữ cảnh luồng đang chạy (giúp phân loại lỗi theo flow trên console)
  Future<void> setFlowContext({
    required String flowName,
    required String currentScreen,
  }) async {
    await setCustomKey('current_flow', flowName);
    await setCustomKey('current_screen', currentScreen);
  }

  /// Ghi nhận lỗi có xử lý (Handled Non-Fatal Error) từ luồng nghiệp vụ thực tế
  /// Ví dụ: Thất bại khi parse JSON, lỗi kết nối Firestore, lỗi xuất PDF...
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[Crashlytics Non-Fatal] Reason: $reason | Error: $exception');
      }
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  /// Nút kích hoạt Test Crash phục vụ quay video demo và chụp màn hình Dashboard
  /// Lưu ý: Chỉ gọi từ nút thử nghiệm trong Firebase Demo Area tại màn hình Profile.
  void triggerTestCrash() {
    _crashlytics.log('Người dùng chủ động kích hoạt Test Crash từ Demo Area.');
    _crashlytics.crash();
  }
}
