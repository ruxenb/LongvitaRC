import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {
        'max_meal_recommendations': 5,
        'enable_longevity_score': true,
        'daily_protein_target_ratio': 0.8,
        'banner_announcement':
            'Chào mừng đến với Longvita - Dinh dưỡng trường thọ theo TS. Valter Longo',
      });
      await _remoteConfig.fetchAndActivate();
    } catch (_) {}
  }

  int get maxRecommendations =>
      _remoteConfig.getInt('max_meal_recommendations');

  bool get enableLongevityScore =>
      _remoteConfig.getBool('enable_longevity_score');

  double get proteinTargetRatio =>
      _remoteConfig.getDouble('daily_protein_target_ratio');

  String get bannerAnnouncement =>
      _remoteConfig.getString('banner_announcement');
}
