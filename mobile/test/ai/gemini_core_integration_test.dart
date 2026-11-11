import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:longvita/services/gemini_ai_service.dart';
import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita_core/firebase/remote_config_service.dart';

class _Config extends Fake implements RemoteConfigService {
  final bool enabled;
  final String model;
  _Config({this.enabled = true, this.model = 'configured-model'});

  @override
  bool getBool(String key) {
    expect(key, 'ai_feature_enabled');
    return enabled;
  }

  @override
  String getString(String key) {
    expect(key, 'gemini_model_name');
    return model;
  }
}

class _Analytics extends Fake implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    events.add((name, parameters));
  }
}

void main() {
  test('Core Remote Config flag stops AI before HTTP and analytics', () async {
    var calls = 0;
    final analytics = _Analytics();
    final service = GeminiAiService(
      remoteConfig: _Config(enabled: false),
      analytics: analytics,
      apiKey: 'unit-test-key',
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final result = await service.recommendLongevityMeal(mealType: 'lunch');
    expect(result.isAiGenerated, isFalse);
    expect(calls, 0);
    expect(analytics.events, isEmpty);
  });

  test(
    'Core configured model and positional Analytics contract work together',
    () async {
      final analytics = _Analytics();
      final service = GeminiAiService(
        remoteConfig: _Config(model: 'configured-model'),
        analytics: analytics,
        apiKey: 'unit-test-key',
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '/v1beta/models/configured-model:generateContent',
          );
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'mealName': 'Món kiểm thử',
                          'calories': 400,
                          'proteinGrams': 12,
                          'ingredients': ['Đậu'],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await service.recommendLongevityMeal(mealType: 'lunch');
      expect(result.isAiGenerated, isTrue);
      await service.logRecommendationAccepted(
        recommendationId: result.id,
        wasEdited: true,
      );
      expect(analytics.events.map((event) => event.$1), [
        'ai_request',
        'ai_result_accepted',
      ]);
      expect(analytics.events.first.$2?['model_name'], 'configured-model');
      expect(analytics.events.last.$2?['was_edited'], 1);
    },
  );

  test(
    'HTTP failure logs through Core Analytics and returns fallback',
    () async {
      final analytics = _Analytics();
      final service = GeminiAiService(
        remoteConfig: _Config(),
        analytics: analytics,
        apiKey: 'unit-test-key',
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      final result = await service.recommendLongevityMeal(mealType: 'dinner');
      expect(result.isAiGenerated, isFalse);
      expect(analytics.events.map((event) => event.$1), [
        'ai_request',
        'ai_error',
      ]);
      expect(analytics.events.last.$2?['error_type'], 'http_500');
    },
  );
}
