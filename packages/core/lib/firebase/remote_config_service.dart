import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý cấu hình từ xa (Firebase Remote Config).
/// Tuân thủ quy định Handout Mục 6 & 7:
/// - Thiết lập In-App Defaults đồng bộ với `firebase/remote-config-defaults.json`.
/// - Hỗ trợ ít nhất 2 tham số làm thay đổi giao diện/hành vi nhìn thấy được mà không cần rebuild app.
/// - Xử lý failure case: khi mất mạng hoặc fetch lỗi, app tự động fallback về in-app defaults an toàn.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Giá trị mặc định trong ứng dụng (In-App Defaults)
  static const Map<String, dynamic> defaultParameters = {
    'max_meal_recommendations': 5,
    'enable_longevity_score': true,
    'web_show_review_guidance': true,
    'daily_protein_target_ratio': 0.8,
    'banner_announcement': 'Chào mừng đến với Longvita - Dinh dưỡng trường thọ theo TS. Valter Longo',
    'ai_feature_enabled': true,
    'gemini_model_name': 'gemini-2.0-flash',
    'ai_prompt_template': 'Bạn là chuyên gia dinh dưỡng trường thọ theo phương pháp TS. Valter Longo. Hãy gợi ý một món ăn trường thọ dạng JSON với các thông số dinh dưỡng, tỷ lệ calo, protein và chất chống oxy hóa.',
  };

  /// Khởi tạo và đồng bộ cấu hình từ xa
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Trong môi trường dev/test, đặt minimumFetchInterval thấp để thấy thay đổi tức thì
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 5)
              : const Duration(hours: 1),
        ),
      );

      // 1. Nạp In-App Defaults trước để đảm bảo app luôn có dữ liệu hợp lệ
      await _remoteConfig.setDefaults(defaultParameters);

      // 2. Fetch và activate từ Firebase Console (nếu có mạng)
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Khi mất mạng hoặc fetch thất bại, âm thầm dùng In-App Defaults không để app crash
      debugPrint('[RemoteConfig] Fetch error, using in-app defaults: $e');
    }
  }

  /// Nạp lại cấu hình thủ công (Dùng cho nút "Cập nhật Remote Config" tại Profile Demo Area)
  Future<bool> forceFetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // GETTERS TRUY XUẤT CÁC THAM SỐ (ĐƯỢC GỌI TỪ VIEWMODEL / UI)
  // ===========================================================================

  /// Read a boolean parameter without exposing the SDK to client services.
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// Read a string parameter without exposing the SDK to client services.
  String getString(String key) => _remoteConfig.getString(key);

  /// Tham số 1: Số lượng món gợi ý hiển thị tối đa (int)
  int get maxRecommendations =>
      _remoteConfig.getInt('max_meal_recommendations');

  /// Tham số 2: Feature flag bật/tắt hiển thị Điểm trường thọ (bool)
  bool get enableLongevityScore =>
      _remoteConfig.getBool('enable_longevity_score');

  /// Cờ Web Admin: hiện/ẩn hướng dẫn nghiệp vụ trên hàng đợi xét duyệt.
  bool get webShowReviewGuidance =>
      _remoteConfig.getBool('web_show_review_guidance');

  /// Tham số 3: Tỷ lệ mục tiêu đạm mỗi ngày (double)
  double get proteinTargetRatio =>
      _remoteConfig.getDouble('daily_protein_target_ratio');

  /// Tham số 4: Chuỗi thông báo banner trên Trang chủ (String)
  String get bannerAnnouncement =>
      _remoteConfig.getString('banner_announcement');
}
