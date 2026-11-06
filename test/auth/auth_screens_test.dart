import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/analytics_service.dart';
import 'package:longvita/firebase/crashlytics_service.dart';
import 'package:longvita/firebase/firebase_bootstrap.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/firebase/remote_config_service.dart';
import 'package:longvita/firebase/storage_service.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/screens/auth_gate.dart';
import 'package:longvita/screens/startup_gate.dart';
import 'package:longvita/services/i_auth_service.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:longvita/widgets/longvita_widgets.dart';
import 'package:provider/provider.dart';

import '../qa/qa_support.dart';
import 'auth_fakes.dart';
import 'session_isolation_test.dart' show FakeDataService;

/// Full provider tree as in main.dart, with fakes.
class Harness {
  final auth = FakeAuthService();
  final analytics = FakeAnalytics();
  final crashlytics = FakeCrashlytics();
  late final dataService = FakeDataService();
  late final mealPlan = MealPlanViewModel(
    dataService: dataService,
    analytics: analytics,
    crashlytics: crashlytics,
    remoteConfig: FakeRemoteConfig(),
  );
  late final ingredients =
      IngredientViewModel(analytics: analytics, crashlytics: crashlytics);
  late final profile = ProfileViewModel(
    authService: auth,
    storageService: FakeStorageService(),
    notificationService: FakeNotificationService(),
    reportService: FakeReportService(),
    reportStore: FakeLocalReportStore(),
    reportViewer: FakeReportViewer(),
    remoteConfigService: FakeRemoteConfig(),
    crashlyticsService: crashlytics,
    analyticsService: analytics,
  );
  late final vm = AuthViewModel(
    authService: auth,
    analytics: analytics,
    crashlytics: crashlytics,
    sessionScoped: [mealPlan, ingredients, profile],
  );

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          Provider<IAuthService>.value(value: auth),
          Provider<IDataService>.value(value: dataService),
          Provider<AnalyticsService>.value(value: analytics),
          Provider<CrashlyticsService>.value(value: crashlytics),
          Provider<RemoteConfigService>.value(value: FakeRemoteConfig()),
          Provider<StorageService>.value(value: FakeStorageService()),
          Provider<NotificationService>.value(value: FakeNotificationService()),
          ChangeNotifierProvider<AuthViewModel>.value(value: vm),
          ChangeNotifierProvider<MealPlanViewModel>.value(value: mealPlan),
          ChangeNotifierProvider<IngredientViewModel>.value(value: ingredients),
          ChangeNotifierProvider<ProfileViewModel>.value(value: profile),
        ],
        child: child,
      );
}

/// Lets the fake services' futures complete inside the widget test's fake
/// clock without waiting on the infinite spinner animation.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  final theme = AppTheme.lightTheme;

  setUpAll(loadQaFonts);

  Future<Harness> pumpGate(WidgetTester tester,
      {Size size = const Size(360, 800), GlobalKey? key, double textScale = 1}) async {
    final h = Harness();
    await pumpQa(tester, h.wrap(const AuthGate()),
        size: size,
        theme: theme,
        boundaryKey: key,
        textScale: textScale,
        realShadows: key != null);
    await settle(tester);
    return h;
  }

  testWidgets('signed out shows Sign-in with the Google action', (tester) async {
    await pumpGate(tester);
    expect(find.text('Thực đơn trường thọ cho cả tuần'), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
  });

  testWidgets('picker open: loading button, repeated taps ignored',
      (tester) async {
    final h = await pumpGate(tester);
    h.auth.pendingSignIn = Completer<AuthSignInResult>();

    await tester.tap(find.byKey(const Key('sign-in-google')));
    await tester.pump();
    expect(find.text('Đang mở tài khoản Google…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sign-in-google')));
    await tester.pump();
    expect(h.auth.signInCalls, 1);

    h.auth.pendingSignIn!.complete(const AuthSignInCancelled());
    await settle(tester);
  });

  testWidgets('cancel shows an informational notice that can be dismissed',
      (tester) async {
    final h = await pumpGate(tester);
    h.auth.nextSignIn = const AuthSignInCancelled();

    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);

    expect(find.textContaining('Bạn đã đóng cửa sổ chọn tài khoản'),
        findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pump();
    expect(find.textContaining('Bạn đã đóng cửa sổ'), findsNothing);
  });

  testWidgets('credential failure shows an error and a retry label',
      (tester) async {
    final h = await pumpGate(tester);
    h.auth.nextSignIn = const AuthSignInFailed(
        AuthFailure(AuthFailureKind.network, code: 'network_error'));

    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);

    expect(find.textContaining('Không có kết nối mạng'), findsOneWidget);
    expect(find.text('Thử lại với Google'), findsOneWidget);

    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);
    expect(find.text('Thử lại với Google'), findsNothing);
    expect(h.vm.state, isA<AuthSignedIn>());
  });

  testWidgets('profile failure opens recovery, not Sign-in; retry recovers',
      (tester) async {
    final h = await pumpGate(tester);
    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    h.auth.profileResults.add(const AuthFailure(AuthFailureKind.profileRead));

    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);

    expect(find.text('Chưa tải được hồ sơ'), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsNothing);

    // Each action is its own accessibility node (TalkBack/ARTEMIS can target
    // it); found on Android when the whole panel merged into one node.
    final handle = tester.ensureSemantics();
    for (final label in ['Thử lại', 'Đăng xuất']) {
      expect(
        tester.getSemantics(find.text(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();

    await tester.tap(find.text('Thử lại'));
    await settle(tester);
    expect(h.vm.state, isA<AuthSignedIn>());
    expect(find.text('Chưa tải được hồ sơ'), findsNothing);
  });

  testWidgets('recovery sign-out returns to Sign-in', (tester) async {
    final h = await pumpGate(tester);
    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    h.auth.profileResults.add(const AuthFailure(AuthFailureKind.profileWrite));
    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);
    expect(find.text('Chưa tạo được hồ sơ'), findsOneWidget);

    await tester.tap(find.text('Đăng xuất'));
    await settle(tester);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
  });

  testWidgets('logout removes pushed protected routes (Back cannot return)',
      (tester) async {
    final h = await pumpGate(tester);
    h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);
    expect(h.vm.state, isA<AuthSignedIn>());

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Protected detail')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Protected detail'), findsOneWidget);

    await h.vm.signOut();
    await settle(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Protected detail'), findsNothing);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('start-up failure shows error + retry, then the app',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(StartupGate(
      initialize: () async {
        attempts++;
        return attempts == 1
            ? BootstrapFailed('not-configured', Exception('no google-services'))
            : const BootstrapReady();
      },
      buildReadyApp: () async =>
          const MaterialApp(home: Scaffold(body: Text('App ready'))),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Không thể khởi động ứng dụng'), findsOneWidget);
    expect(find.textContaining('chưa có cấu hình Firebase'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('an initializer that throws shows error + retry, then the app',
      (tester) async {
    var attempts = 0;
    var builds = 0;
    await tester.pumpWidget(StartupGate(
      initialize: () async {
        if (++attempts == 1) throw StateError('injected initializer failure');
        return const BootstrapReady();
      },
      buildReadyApp: () async {
        builds++;
        return const MaterialApp(home: Scaffold(body: Text('App ready')));
      },
    ));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Không thể khởi động ứng dụng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);
    expect(builds, 0);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(attempts, 2);
    expect(builds, 1);
  });

  testWidgets('a service failing after Firebase starts shows error + retry',
      (tester) async {
    var builds = 0;
    await tester.pumpWidget(StartupGate(
      initialize: () async => const BootstrapReady(),
      buildReadyApp: () async {
        builds++;
        if (builds == 1) throw StateError('service start failed');
        return const MaterialApp(home: Scaffold(body: Text('App ready')));
      },
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Không thể khởi động ứng dụng'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(builds, 2);
  });

  group('screenshots (actual)', () {
    for (final size in const [Size(360, 800), Size(412, 915)]) {
      final w = size.width.toInt();

      testWidgets('sign-in idle $w', (tester) async {
        final key = GlobalKey();
        await pumpGate(tester, size: size, key: key);
        expect(tester.takeException(), isNull);
        await captureQa(tester, key, 'auth-sign-in-$w',
            metadata: {'state': 'AuthSignedOut', 'task': 'CHARLIE-AUTH-01'});
      });

      testWidgets('sign-in cancelled $w', (tester) async {
        final key = GlobalKey();
        final h = await pumpGate(tester, size: size, key: key);
        h.auth.nextSignIn = const AuthSignInCancelled();
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await captureQa(tester, key, 'auth-sign-in-cancelled-$w',
            metadata: {'state': 'AuthSignedOut(cancelled)'});
      });

      testWidgets('sign-in failure $w', (tester) async {
        final key = GlobalKey();
        final h = await pumpGate(tester, size: size, key: key);
        h.auth.nextSignIn = const AuthSignInFailed(
            AuthFailure(AuthFailureKind.configuration));
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await captureQa(tester, key, 'auth-sign-in-error-$w',
            metadata: {'state': 'AuthSignedOut(configuration)'});
      });

      testWidgets('sign-in loading $w', (tester) async {
        final key = GlobalKey();
        final h = await pumpGate(tester, size: size, key: key);
        h.auth.pendingSignIn = Completer<AuthSignInResult>();
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pump();
        await captureQa(tester, key, 'auth-sign-in-loading-$w',
            metadata: {'state': 'AuthSigningIn'});
        h.auth.pendingSignIn!.complete(const AuthSignInCancelled());
        await settle(tester);
      });

      testWidgets('profile recovery $w', (tester) async {
        final key = GlobalKey();
        final h = await pumpGate(tester, size: size, key: key);
        h.auth.nextSignIn = const AuthSignInSucceeded('uid-a');
        h.auth.profileResults
            .add(const AuthFailure(AuthFailureKind.network, code: 'unavailable'));
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await captureQa(tester, key, 'auth-profile-recovery-$w',
            metadata: {'state': 'AuthProfileError(network)'});
      });
    }

    testWidgets('sign-in headline is a heading for screen readers',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGate(tester);
      expect(
          tester.getSemantics(find.text('Thực đơn trường thọ cho cả tuần')),
          isSemantics(
              label: 'Thực đơn trường thọ cho cả tuần', isHeader: true));
      // Android reports a heading only when headingLevel is set.
      expect(tester.getSemantics(find.text('Longvita')).headingLevel, 1);
      expect(
          tester
              .getSemantics(find.text('Thực đơn trường thọ cho cả tuần'))
              .headingLevel,
          2);
      handle.dispose();
    });

    testWidgets('sign-in textScale 2.0 at 360 has no overflow', (tester) async {
      final key = GlobalKey();
      final h = await pumpGate(tester, key: key, textScale: 2.0);
      h.auth.nextSignIn = const AuthSignInFailed(
          AuthFailure(AuthFailureKind.credential));
      await tester.tap(find.byKey(const Key('sign-in-google')));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await captureQa(tester, key, 'auth-sign-in-error-360-text2_0',
          pixelRatio: 1.0, metadata: {'textScale': 2.0});
    });
  });
}
