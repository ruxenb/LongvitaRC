import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  Future<void> setUserId(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (_) {}
  }

  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  Future<void> logGenerateMealPlan({
    required int targetAge,
    required double weightKg,
    required int fishCount,
  }) async {
    await logEvent('generate_meal_plan', {
      'target_age': targetAge,
      'weight_kg': weightKg,
      'fish_count': fishCount,
    });
  }

  Future<void> logSaveMealPlan({required String planId, required String status}) async {
    await logEvent('save_meal_plan', {
      'plan_id': planId,
      'status': status,
    });
  }

  Future<void> logExportReport({required String format}) async {
    await logEvent('export_report', {
      'format': format,
    });
  }
}
