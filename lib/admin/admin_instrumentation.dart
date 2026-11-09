import 'package:flutter/foundation.dart';

import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';

class AdminWebInstrumentation extends ChangeNotifier {
  final AnalyticsService analytics;
  final RemoteConfigService remoteConfig;

  bool showReviewGuidance = true;
  bool refreshing = false;

  AdminWebInstrumentation({
    required this.analytics,
    required this.remoteConfig,
  });

  Future<void> initialize() async {
    await remoteConfig.initialize();
    showReviewGuidance = remoteConfig.webShowReviewGuidance;
  }

  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    notifyListeners();
    await remoteConfig.forceFetchAndActivate();
    showReviewGuidance = remoteConfig.webShowReviewGuidance;
    refreshing = false;
    notifyListeners();
  }

  Future<void> logPlanReview(String status) => status == 'approved'
      ? analytics.logApprovePlan()
      : analytics.logRejectPlan();

  Future<void> logPublishAnnouncement() => analytics.logPublishAnnouncement();
}
