import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/analytics_service.dart';

/// Records the actual SDK boundary, including names, values and types.
class RecordingAnalyticsSdk implements FirebaseAnalytics {
  final calls = <({String name, Map<String, Object>? parameters})>[];
  bool fail = false;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    Object? callOptions,
  }) async {
    calls.add((name: name, parameters: parameters));
    if (fail) throw StateError('Analytics unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('export sends exactly one SDK event with typed report parameters', () async {
    final sdk = RecordingAnalyticsSdk();
    await AnalyticsService(analytics: sdk).logExportReport(
      fileSizeKb: 19,
      hasShoppingList: 0,
    );
    expect(sdk.calls, hasLength(1));
    expect(sdk.calls.single.name, 'export_report');
    expect(sdk.calls.single.parameters, {
      'topic': 'longevity_meal_plan',
      'report_topic': 'longevity_meal_plan',
      'file_size_kb': 19,
      'has_shopping_list': 0,
    });
  });

  test('the SDK receives the supplied topic and actual report values', () async {
    final sdk = RecordingAnalyticsSdk();
    await AnalyticsService(analytics: sdk).logExportReport(
      topic: 'another_report',
      fileSizeKb: 7,
      hasShoppingList: 1,
    );
    expect(sdk.calls.single.parameters, {
      'topic': 'another_report',
      'report_topic': 'another_report',
      'file_size_kb': 7,
      'has_shopping_list': 1,
    });
  });

  test('SDK failure neither breaks the export nor retries the event', () async {
    final sdk = RecordingAnalyticsSdk()..fail = true;
    await expectLater(
      AnalyticsService(analytics: sdk).logExportReport(
        fileSizeKb: 19,
        hasShoppingList: 0,
      ),
      completes,
    );
    expect(sdk.calls, hasLength(1));
  });
}
