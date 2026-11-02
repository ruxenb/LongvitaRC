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
    'daily_protein_target_ratio': 0.8,
    'banner_announcement':
        'Chào mừng đến với Longvita - Dinh dưỡng trường thọ theo TS. Valter Longo',
  };

  /// Khởi tạo và đồng bộ cấu hình từ xa
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Trong môi trường dev/test, đặt minimumFetchInterval thấp để thấy thay đổi tức thì
          minimumFetchInterval:
              kDebugMode ? const Duration(seconds: 5) : const Duration(hours: 1),
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

  /// Tham số 1: Số lượng món gợi ý hiển thị tối đa (int)
  int get maxRecommendations =>
      _remoteConfig.getInt('max_meal_recommendations');

  /// Tham số 2: Feature flag bật/tắt hiển thị Điểm trường thọ (bool)
  bool get enableLongevityScore =>
      _remoteConfig.getBool('enable_longevity_score');

  /// Tham số 3: Tỷ lệ mục tiêu đạm mỗi ngày (double)
  double get proteinTargetRatio =>
      _remoteConfig.getDouble('daily_protein_target_ratio');

  /// Tham số 4: Chuỗi thông báo banner trên Trang chủ (String)
  String get bannerAnnouncement =>
      _remoteConfig.getString('banner_announcement');
}
