// S4-13: Profile and Firebase Demo Area against fake services. Upload success
// and push here use fakes; a live upload and a real push are not covered.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/screens/auth_gate.dart';
import 'package:longvita/screens/profile_screen.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show FakeDataService;
import '../fcm/notification_service_test.dart' show FakeGateway;

class ScriptedStorage extends FakeStorageService {
  /// Next upload result; null fails the upload, as a missing bucket does.
  String? nextUrl = 'https://storage.test/report.pdf';
  Completer<String?>? held;
  void Function(double)? lastOnProgress;
  int uploads = 0;

  @override
  Future<String?> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) {
    uploads++;
    lastOnProgress = onProgress;
    return held?.future ?? Future.value(nextUrl);
  }
}

class ScriptedRemoteConfig extends FakeRemoteConfig {
  bool nextRefresh = false;

  @override
  Future<bool> forceFetchAndActivate() async => nextRefresh;
}

class CountingCrashlytics extends FakeCrashlytics {
  int crashes = 0;

  @override
  void triggerTestCrash() => crashes++;
}

class Harness {
  final auth = FakeAuthService();
  final analytics = FakeAnalytics();
  final crashlytics = CountingCrashlytics();
  final storage = ScriptedStorage();
  final viewer = FakeReportViewer();
  final remoteConfig = ScriptedRemoteConfig();
  final gateway = FakeGateway();
  late final notifications = NotificationService(gateway: gateway);
  late final mealPlan = MealPlanViewModel(
    dataService: FakeDataService(),
    analytics: analytics,
    crashlytics: crashlytics,
    remoteConfig: FakeRemoteConfig(),
  );
  late final profile = ProfileViewModel(
    authService: auth,
    storageService: storage,
    notificationService: notifications,
    reportService: FakeReportService(),
    reportStore: FakeLocalReportStore(),
    reportViewer: viewer,
    remoteConfigService: remoteConfig,
    crashlyticsService: crashlytics,
    analyticsService: analytics,
  );
  late final session = AuthViewModel(
    authService: auth,
    analytics: analytics,
    crashlytics: crashlytics,
    sessionScoped: [mealPlan, profile],
  );

  Widget app({Widget home = const ProfileScreen(), double textScale = 1}) =>
      MultiProvider(
        providers: [
          Provider<IDataService>.value(value: FakeDataService()),
          ChangeNotifierProvider<AuthViewModel>.value(value: session),
          ChangeNotifierProvider<MealPlanViewModel>.value(value: mealPlan),
          ChangeNotifierProvider<ProfileViewModel>.value(value: profile),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: home,
          ),
        ),
      );
}

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<Harness> pumpProfile(
    WidgetTester tester, {
    bool withPlan = true,
    Size size = const Size(360, 800),
    double textScale = 1,
    void Function(Harness)? arrange,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final h = Harness();
    arrange?.call(h);
    h.session; // subscribes to the auth stream
    await tester.pumpWidget(h.app(textScale: textScale));
    await settle(tester);
    // Not awaited: the fakes' timers only fire while the test clock is pumped.
    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    unawaited(h.session.signInWithGoogle());
    await settle(tester);
    if (withPlan) {
      unawaited(h.mealPlan.generatePlan(uid: 'uid-a', weightKg: 60, age: 30));
    }
    await settle(tester);
    return h;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  RemoteMessage push(String id, {String? title, String? body, String? type}) =>
      RemoteMessage(
        messageId: id,
        notification: RemoteNotification(title: title, body: body),
        data: {'target_type': ?type, 'schema_version': '1'},
      );

  testWidgets('shows who is signed in', (tester) async {
    await pumpProfile(tester);

    expect(find.text('User uid-a'), findsOneWidget);
    expect(find.text('uid-a@example.test'), findsOneWidget);
    expect(find.text('Vai trò: user'), findsOneWidget);
  });

  testWidgets('sign-out from Profile leaves it and shows Sign-in',
      (tester) async {
    final h = await pumpProfile(tester);
    await tester.pumpWidget(h.app(home: const AuthGate()));
    await settle(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tapKey(tester, 'profile-sign-out');
    await tester.pumpAndSettle();

    expect(h.auth.signOutCalls, 1);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
  });

  group('export', () {
    testWidgets('without a plan the action is disabled and says why',
        (tester) async {
      final h = await pumpProfile(tester, withPlan: false);

      expect(find.textContaining('Chưa có thực đơn để xuất'), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile-export')));
      await settle(tester);
      expect(h.storage.uploads, 0);
    });

    testWidgets('shows progress while the upload runs and ignores repeat taps',
        (tester) async {
      final h = await pumpProfile(tester);
      h.storage.held = Completer();

      await tapKey(tester, 'profile-export');
      expect(find.text('Đang xuất PDF…'), findsOneWidget);
      h.storage.lastOnProgress!(0.4);
      await tester.pump();
      expect(find.textContaining('40%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-export')));
      await settle(tester);
      expect(h.storage.uploads, 1);

      h.storage.held!.complete('https://storage.test/report.pdf');
      await settle(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('success shows the download URL and no retry', (tester) async {
      await pumpProfile(tester);

      await tapKey(tester, 'profile-export');

      expect(find.text('Đã tải PDF lên Cloud Storage.'), findsOneWidget);
      expect(find.text('https://storage.test/report.pdf'), findsOneWidget);
      expect(find.byKey(const Key('profile-retry')), findsNothing);
    });

    testWidgets('failed upload keeps the file: message, retry, open and share',
        (tester) async {
      final h = await pumpProfile(tester);
      h.storage.nextUrl = null;

      await tapKey(tester, 'profile-export');

      expect(find.textContaining('chưa tải lên được'), findsOneWidget);
      await tapKey(tester, 'profile-open');
      await tapKey(tester, 'profile-share');
      expect(h.viewer.previewed, hasLength(1));
      expect(h.viewer.shared, hasLength(1));

      h.storage.nextUrl = 'https://storage.test/report.pdf';
      await tapKey(tester, 'profile-retry');
      expect(h.storage.uploads, 2);
      expect(find.text('https://storage.test/report.pdf'), findsOneWidget);
      expect(find.byKey(const Key('profile-retry')), findsNothing);
    });

    testWidgets('a PDF that cannot be opened is reported', (tester) async {
      final h = await pumpProfile(tester);
      h.viewer.error = Exception('no viewer');

      await tapKey(tester, 'profile-export');
      await tapKey(tester, 'profile-open');

      expect(find.text('Không mở được file PDF đã lưu.'), findsOneWidget);
    });
  });

  group('notifications', () {
    testWidgets('empty inbox says so', (tester) async {
      await pumpProfile(tester);
      expect(find.text('Chưa có thông báo nào.'), findsOneWidget);
    });

    testWidgets('a message arriving while Profile is open appears',
        (tester) async {
      final h = await pumpProfile(tester);

      h.gateway.foreground.add(push('m1', title: 'Tin mới', body: 'Nội dung'));
      await settle(tester);

      expect(find.text('Tin mới'), findsOneWidget);
      expect(find.text('Nội dung'), findsOneWidget);
      expect(find.text('Chưa có thông báo nào.'), findsNothing);
    });

    testWidgets('a message with a bad target stays and says it cannot open',
        (tester) async {
      final h = await pumpProfile(tester);

      h.gateway.foreground.add(push('m1', title: 'Tin lạ', type: 'unknown'));
      await settle(tester);

      expect(find.text('Tin lạ'), findsOneWidget);
      expect(find.textContaining('Không mở được nội dung'), findsOneWidget);
    });

    testWidgets('denied permission is explained', (tester) async {
      await pumpProfile(tester, arrange: (h) => h.gateway.grant = false);
      expect(find.textContaining('Thông báo đang tắt'), findsOneWidget);
    });

    testWidgets('sign-out empties the inbox', (tester) async {
      final h = await pumpProfile(tester);
      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);

      h.session.signOut();
      await settle(tester);

      expect(h.profile.inbox, isEmpty);
    });
  });

  group('Remote Config', () {
    testWidgets('shows current values', (tester) async {
      await pumpProfile(tester);

      expect(find.text('5'), findsOneWidget);
      expect(find.text('Bật'), findsOneWidget);
      expect(find.text('Trống'), findsOneWidget);
    });

    testWidgets('refresh reports new values', (tester) async {
      final h = await pumpProfile(tester);
      h.remoteConfig.nextRefresh = true;

      await tapKey(tester, 'profile-refresh-config');

      expect(find.text('Đã áp dụng giá trị mới.'), findsOneWidget);
    });

    testWidgets('refresh does not claim success when nothing was applied',
        (tester) async {
      await pumpProfile(tester);

      await tapKey(tester, 'profile-refresh-config');

      expect(find.textContaining('Không có giá trị mới'), findsOneWidget);
      expect(find.text('Đã áp dụng giá trị mới.'), findsNothing);
    });
  });

  group('Crashlytics', () {
    testWidgets('cancelling the confirmation does not crash', (tester) async {
      final h = await pumpProfile(tester);

      await tapKey(tester, 'profile-test-crash');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(h.crashlytics.crashes, 0);
    });

    testWidgets('confirming triggers the test crash once', (tester) async {
      final h = await pumpProfile(tester);

      await tapKey(tester, 'profile-test-crash');
      await tester.tap(find.text('Gây crash'));
      await tester.pumpAndSettle();

      expect(h.crashlytics.crashes, 1);
    });
  });

  group('layout and semantics', () {
    for (final (name, size, scale) in [
      ('360 wide', const Size(360, 800), 1.0),
      ('412 wide', const Size(412, 915), 1.0),
      ('360 wide at text scale 2', const Size(360, 800), 2.0),
    ]) {
      testWidgets('no overflow: $name', (tester) async {
        final h = await pumpProfile(tester, size: size, textScale: scale);
        h.storage.nextUrl = null;
        await tapKey(tester, 'profile-export');
        h.gateway.foreground.add(push('m1', title: 'Tin mới', body: 'Nội dung'));
        await settle(tester);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('actions are named for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProfile(tester);

      for (final label in [
        'Quay lại',
        'Đăng xuất',
        'Xuất báo cáo PDF',
        'Cập nhật Remote Config',
        'Gây crash thử',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });
  });
}
