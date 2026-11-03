// S4-13: Profile and Firebase Demo Area against fake services. Upload success
// and push here use fakes; a live upload and a real push are not covered.
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_history_store.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/app_notification.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/upload_failure.dart';
import 'package:longvita/screens/auth_gate.dart';
import 'package:longvita/screens/home_screen.dart';
import 'package:longvita/screens/profile_screen.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:longvita/widgets/app_dialog.dart';
import 'package:longvita/widgets/app_supporting.dart';
import 'package:provider/provider.dart';

import '../auth/auth_fakes.dart';
import '../auth/session_isolation_test.dart' show FakeDataService;
import '../fcm/notification_service_test.dart' show FakeGateway;

class ScriptedStorage extends FakeStorageService {
  /// Next upload result; null fails the upload, as a missing bucket does.
  String? nextUrl = 'https://storage.test/report.pdf';
  Completer<String>? held;
  void Function(double)? lastOnProgress;
  int uploads = 0;

  @override
  Future<String> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) {
    uploads++;
    lastOnProgress = onProgress;
    final url = nextUrl;
    return held?.future ??
        (url != null
            ? Future.value(url)
            : Future.error(
                const UploadFailure(UploadFailureKind.unknown)));
  }
}

class ScriptedRemoteConfig extends FakeRemoteConfig {
  /// What the SDK reports: true for any newly fetched config, changed or not.
  bool nextRefresh = false;

  /// Applied by the next refresh, like a value edited on the Console.
  int? nextMaxRecommendations;
  int _maxRecommendations = 5;

  /// When set, the fetch waits for it, like a slow network.
  Completer<void>? held;
  int fetches = 0;

  @override
  int get maxRecommendations => _maxRecommendations;

  @override
  Future<bool> forceFetchAndActivate() async {
    fetches++;
    await held?.future;
    _maxRecommendations = nextMaxRecommendations ?? _maxRecommendations;
    return nextRefresh;
  }
}

/// No file system in widget tests, where real file futures never complete.
class MemoryHistory implements NotificationHistoryStore {
  final Map<String, List<AppNotification>> saved = {};
  final List<AppNotification> pending = [];

  @override
  Future<List<AppNotification>> load(String uid) async => saved[uid] ?? const [];

  @override
  Future<void> save(String uid, List<AppNotification> items) async =>
      saved[uid] = items;

  @override
  Future<void> addPending(AppNotification item) async => pending.insert(0, item);

  @override
  Future<List<AppNotification>> takePending() async {
    final items = List.of(pending);
    pending.clear();
    return items;
  }
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
  final history = MemoryHistory();
  late final notifications =
      NotificationService(gateway: gateway, history: history);
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
          routes: {ProfileScreen.routeName: (_) => const ProfileScreen()},
          // Above the navigator, so dialogs are scaled too.
          builder: (_, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child!,
          ),
          home: home,
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
    expect(find.textContaining('example.test'), findsOneWidget);
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
    expect(h.auth.signOutCalls, 0, reason: 'asks first');
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(h.auth.signOutCalls, 1);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
  });

  testWidgets('cancelling the sign-out keeps the session', (tester) async {
    final h = await pumpProfile(tester);

    await tapKey(tester, 'profile-sign-out');
    await tester.pumpAndSettle();
    expect(find.textContaining('PDF đã lưu trên máy này sẽ bị xóa'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(h.auth.signOutCalls, 0);
    expect(find.text('User uid-a'), findsOneWidget);
  });

  testWidgets('Home opens Profile, and Back returns to Home', (tester) async {
    final h = await pumpProfile(tester);
    await tester.pumpWidget(h.app(home: const HomeScreen()));
    await settle(tester);

    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home has one way to export: it leads to Profile', (tester) async {
    final h = await pumpProfile(tester);
    await tester.pumpWidget(h.app(home: const HomeScreen()));
    await settle(tester);

    expect(find.text('Mở PDF đã lưu'), findsNothing);
    expect(find.text('Chia sẻ PDF đã lưu'), findsNothing);
    expect(find.text('Thử tải lên lại'), findsNothing);

    final link = find.text('Xuất báo cáo PDF ở Hồ sơ');
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(h.storage.uploads, 0);
  });

  group('tapping a notification', () {
    Future<Harness> pumpGate(WidgetTester tester) async {
      final h = await pumpProfile(tester);
      await tester.pumpWidget(h.app(home: const AuthGate()));
      await settle(tester);
      return h;
    }

    testWidgets('opens Profile from Home', (tester) async {
      final h = await pumpGate(tester);
      expect(find.byType(ProfileScreen), findsNothing);

      h.gateway.opened.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Tin mới'), findsOneWidget);
    });

    testWidgets('a message only received does not navigate', (tester) async {
      final h = await pumpGate(tester);

      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('a message received on Home shows there and View opens it',
        (tester) async {
      final h = await pumpGate(tester);

      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pump();

      expect(find.text('Thông báo mới: Tin mới'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);

      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Tin mới'), findsOneWidget);
    });

    testWidgets('a message received on another screen shows there',
        (tester) async {
      final h = await pumpGate(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Màn khác')),
      )));
      await tester.pumpAndSettle();

      h.gateway.foreground.add(push('m1', body: 'Nội dung'));
      await settle(tester);
      await tester.pump();

      expect(find.text('Màn khác'), findsOneWidget);
      expect(find.text('Thông báo mới: Nội dung'), findsOneWidget);
    });

    testWidgets('a repeated message shows nothing new', (tester) async {
      final h = await pumpGate(tester);
      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pump();
      ScaffoldMessenger.of(tester.element(find.byType(HomeScreen)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();

      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pump();

      expect(find.text('Thông báo mới: Tin mới'), findsNothing);
    });

    group('PM-FCM-02: a message belongs to the session that received it', () {
      RemoteMessage forA() => const RemoteMessage(
            messageId: 'private-a',
            data: {'recipient_uid': 'uid-a'},
            notification: RemoteNotification(title: 'Private message for A'),
          );
      const shownA = 'Thông báo mới: Private message for A';

      Future<VoidCallback> showForA(WidgetTester tester, Harness h) async {
        h.gateway.foreground.add(forA());
        await settle(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(shownA), findsOneWidget);
        return tester
            .widget<AppSnackBarContent>(find.byType(AppSnackBarContent))
            .onAction!;
      }

      Future<void> signOut(WidgetTester tester, Harness h) async {
        unawaited(h.session.signOut());
        await settle(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      }

      Future<void> signIn(WidgetTester tester, Harness h, String uid) async {
        h.auth.nextSignIn = AuthSignInSucceeded(uid);
        unawaited(h.session.signInWithGoogle());
        await settle(tester);
        await tester.pumpAndSettle();
      }

      testWidgets('sign-out removes the message and its View action',
          (tester) async {
        final h = await pumpGate(tester);
        await showForA(tester, h);

        await signOut(tester, h);

        expect(find.text(shownA), findsNothing);
        expect(find.text('Xem'), findsNothing);
      });

      testWidgets('View kept from before sign-out does not open Profile',
          (tester) async {
        final h = await pumpGate(tester);
        final view = await showForA(tester, h);
        await signOut(tester, h);

        view();
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      });

      testWidgets('A -> B: B sees nothing of A and A\'s View does nothing',
          (tester) async {
        final h = await pumpGate(tester);
        final view = await showForA(tester, h);

        h.auth.emitUid('uid-b');
        await settle(tester);
        await tester.pumpAndSettle();
        expect(h.session.currentUser?.uid, 'uid-b');
        expect(find.text(shownA), findsNothing);

        view();
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsNothing);
      });

      testWidgets('A -> sign-out -> A: the old View does nothing',
          (tester) async {
        final h = await pumpGate(tester);
        final view = await showForA(tester, h);
        await signOut(tester, h);
        await signIn(tester, h, 'uid-a');
        expect(h.session.currentUser?.uid, 'uid-a');
        expect(find.text(shownA), findsNothing);

        view();
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsNothing);
      });

      testWidgets('A -> sign-out -> A: a new message still shows and opens',
          (tester) async {
        final h = await pumpGate(tester);
        await showForA(tester, h);
        await signOut(tester, h);
        await signIn(tester, h, 'uid-a');

        h.gateway.foreground.add(push('m2', title: 'Tin sau'));
        await settle(tester);
        await tester.pumpAndSettle();
        expect(find.text('Thông báo mới: Tin sau'), findsOneWidget);

        await tester.tap(find.text('Xem'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('session ending before the frame shows nothing',
          (tester) async {
        final h = await pumpGate(tester);

        // The message reaches the gate first; the session ends right after,
        // before the frame that would show the snackbar.
        h.gateway.foreground.add(forA());
        scheduleMicrotask(() => h.auth.emitUid(null));
        await settle(tester);
        await tester.pumpAndSettle();

        expect(find.text(shownA), findsNothing);
        expect(find.byType(ProfileScreen), findsNothing);
      });

      testWidgets('a tap from the shade after sign-out waits for sign-in',
          (tester) async {
        final h = await pumpGate(tester);
        await signOut(tester, h);

        h.gateway.opened.add(push('m3', title: 'Tin bấm'));
        await settle(tester);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsNothing);

        await signIn(tester, h, 'uid-a');
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      group('queued behind another snackbar', () {
        Future<void> receive(WidgetTester tester, Harness h, String id) async {
          h.gateway.foreground.add(RemoteMessage(
            messageId: id,
            data: const {'recipient_uid': 'uid-a'},
            notification: RemoteNotification(title: id),
          ));
          await settle(tester);
          await tester.pump(const Duration(milliseconds: 300));
        }

        void feedback(WidgetTester tester, String text) => showAppSnackBar(
              tester.element(find.byType(Scaffold).last),
              message: text,
              duration: const Duration(seconds: 20),
            );

        /// Lets every snackbar in the queue take its turn and expire.
        Future<void> drainQueue(WidgetTester tester) async {
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(seconds: 2));
          }
          await tester.pumpAndSettle();
        }

        testWidgets('two messages, then sign-out: neither ever shows again',
            (tester) async {
          final h = await pumpGate(tester);
          await receive(tester, h, 'private-a-1');
          await receive(tester, h, 'private-a-2');
          expect(find.text('Thông báo mới: private-a-1'), findsOneWidget);

          await signOut(tester, h);
          expect(tester.takeException(), isNull);
          expect(find.textContaining('private-a-'), findsNothing);

          // Check every frame while the queue drains, not only at the end.
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 200));
            expect(find.textContaining('private-a-'), findsNothing);
          }
          expect(tester.takeException(), isNull);
          expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
        });

        testWidgets('waiting behind other feedback: the feedback stays, the '
            'message never shows', (tester) async {
          final h = await pumpGate(tester);
          feedback(tester, 'Unrelated feedback');
          await tester.pump(const Duration(milliseconds: 300));
          await receive(tester, h, 'private-a-queued');
          expect(find.text('Unrelated feedback'), findsOneWidget);

          await signOut(tester, h);
          expect(tester.takeException(), isNull);
          expect(find.text('Unrelated feedback'), findsOneWidget);

          await drainQueue(tester);
          expect(tester.takeException(), isNull);
          expect(find.textContaining('private-a-queued'), findsNothing);
        });

        testWidgets('feedback waiting behind a message still shows after '
            'sign-out', (tester) async {
          final h = await pumpGate(tester);
          await receive(tester, h, 'private-a-1');
          feedback(tester, 'Later feedback');
          await tester.pump();

          await signOut(tester, h);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.textContaining('private-a-'), findsNothing);
          expect(find.text('Later feedback'), findsOneWidget);
        });

        testWidgets('queued messages of A never reach B', (tester) async {
          final h = await pumpGate(tester);
          await receive(tester, h, 'private-a-1');
          await receive(tester, h, 'private-a-2');

          h.auth.emitUid('uid-b');
          await settle(tester);
          expect(h.session.currentUser?.uid, 'uid-b');
          await drainQueue(tester);

          expect(tester.takeException(), isNull);
          expect(find.textContaining('private-a-'), findsNothing);
        });

        testWidgets('A signs back in: old queue stays gone, a new message '
            'shows', (tester) async {
          final h = await pumpGate(tester);
          await receive(tester, h, 'private-a-1');
          await receive(tester, h, 'private-a-2');
          await signOut(tester, h);
          await signIn(tester, h, 'uid-a');

          await receive(tester, h, 'private-a-3');
          expect(find.text('Thông báo mới: private-a-3'), findsOneWidget);
          await drainQueue(tester);

          expect(tester.takeException(), isNull);
          expect(find.textContaining('private-a-1'), findsNothing);
          expect(find.textContaining('private-a-2'), findsNothing);
        });
      });

      testWidgets('a message for B shows nothing to A', (tester) async {
        final h = await pumpGate(tester);

        h.gateway.foreground.add(const RemoteMessage(
          messageId: 'for-b',
          data: {'recipient_uid': 'uid-b'},
          notification: RemoteNotification(title: 'Private message for B'),
        ));
        await settle(tester);
        await tester.pumpAndSettle();

        expect(find.textContaining('Private message for B'), findsNothing);
      });
    });

    testWidgets('a message already in the inbox still opens, once',
        (tester) async {
      final h = await pumpGate(tester);
      h.gateway.foreground.add(push('m1', title: 'Tin mới'));
      await settle(tester);

      h.gateway.opened.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Quay lại'));
      await tester.pumpAndSettle();
      h.gateway.opened.add(push('m1', title: 'Tin mới'));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing, reason: 'routed once');
    });

    testWidgets('does not stack a second Profile', (tester) async {
      final h = await pumpGate(tester);
      h.gateway.opened.add(push('m1', title: 'Tin 1'));
      await settle(tester);
      await tester.pumpAndSettle();

      h.gateway.opened.add(push('m2', title: 'Tin 2'));
      await settle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
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

    testWidgets('cancel stops the upload and allows a retry', (tester) async {
      final h = await pumpProfile(tester);
      h.storage.held = Completer();

      await tapKey(tester, 'profile-export');
      expect(find.byKey(const Key('profile-retry')), findsNothing);

      await tapKey(tester, 'profile-cancel-upload');
      expect(h.storage.cancelCalls, 1);
      expect(find.text('Đã hủy tải lên. PDF vẫn còn trên máy.'), findsOneWidget,
          reason: 'shown at once, before the SDK task ends');
      h.storage.held!
          .completeError(const UploadFailure(UploadFailureKind.cancelled));
      await settle(tester);

      expect(find.text('Đã hủy tải lên. PDF vẫn còn trên máy.'), findsOneWidget);
      expect(find.byKey(const Key('profile-cancel-upload')), findsNothing);
      expect(find.byKey(const Key('profile-retry')), findsOneWidget);
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

    testWidgets('saved history shows when Profile opens', (tester) async {
      await pumpProfile(tester, arrange: (h) {
        h.history.saved['uid-a'] = const [
          AppNotification(messageId: 'old', title: 'Tin đã lưu'),
        ];
      });

      expect(find.text('Tin đã lưu'), findsOneWidget);
    });

    testWidgets('a background message shows when the app resumes',
        (tester) async {
      final h = await pumpProfile(tester);
      h.history.pending
          .add(const AppNotification(messageId: 'bg', title: 'Tin nền'));
      expect(find.text('Tin nền'), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);

      expect(find.text('Tin nền'), findsOneWidget);
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
      h.remoteConfig
        ..nextRefresh = true
        ..nextMaxRecommendations = 7;

      await tapKey(tester, 'profile-refresh-config');

      expect(find.text('Đã áp dụng giá trị mới.'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    // Found with ARTEMIS TC-09: the SDK reports every fresh fetch as activated,
    // so each tap claimed new values while nothing had changed.
    testWidgets('a fetch with the same values does not claim new values',
        (tester) async {
      final h = await pumpProfile(tester);
      h.remoteConfig.nextRefresh = true;

      await tapKey(tester, 'profile-refresh-config');

      expect(find.text('Đã áp dụng giá trị mới.'), findsNothing);
      expect(find.textContaining('Không có giá trị mới'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('refresh does not claim success when nothing was applied',
        (tester) async {
      await pumpProfile(tester);

      await tapKey(tester, 'profile-refresh-config');

      expect(find.textContaining('Không có giá trị mới'), findsOneWidget);
      expect(find.text('Đã áp dụng giá trị mới.'), findsNothing);
    });

    // S4-14 (PM-S4-14-01): what TalkBack sees while the fetch is pending.
    testWidgets('while refreshing, the action says so and cannot be repeated',
        (tester) async {
      final handle = tester.ensureSemantics();
      final h = await pumpProfile(tester);
      h.remoteConfig
        ..held = Completer()
        ..nextRefresh = true
        ..nextMaxRecommendations = 7;
      final button = find.byKey(const Key('profile-refresh-config'));

      await tapKey(tester, 'profile-refresh-config');

      expect(
          tester.getSemantics(button),
          isSemantics(
            label: 'Đang cập nhật…',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ));
      await tester.tap(button);
      await settle(tester);
      expect(h.remoteConfig.fetches, 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('5'), findsOneWidget);

      h.remoteConfig.held!.complete();
      await settle(tester);

      expect(
          tester.getSemantics(button),
          isSemantics(
            label: 'Cập nhật Remote Config',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ));
      expect(find.text('Đã áp dụng giá trị mới.'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(h.remoteConfig.fetches, 1);
      handle.dispose();
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
      ('412 wide at text scale 2', const Size(412, 915), 2.0),
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

    // S4-14: text that is not its own node merges into the card's node, which
    // TalkBack reads before everything in the card.
    testWidgets('each card title is a heading of its own, after an upload',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProfile(tester);
      await tapKey(tester, 'profile-export');

      for (final title in [
        'Báo cáo PDF',
        'Thông báo',
        'Remote Config',
        'Crashlytics',
      ]) {
        expect(tester.getSemantics(find.text(title)),
            isSemantics(label: title, isHeader: true, isTextField: false),
            reason: title);
      }
      expect(
          tester.getSemantics(find.text('Chưa có thông báo nào.')),
          isSemantics(
              label: 'Chưa có thông báo nào.', isHeader: false));
      expect(
          tester.getSemantics(find.text('https://storage.test/report.pdf')),
          isSemantics(
            label: '',
            value: 'https://storage.test/report.pdf',
            isTextField: true,
            isReadOnly: true,
            isHeader: false,
          ));
      handle.dispose();
    });

    // Found with TalkBack's Headings control: Android reports a heading only
    // when headingLevel is set, so `header: true` alone was never a heading.
    testWidgets('every heading has a level, so Android reports it',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProfile(tester);
      await tapKey(tester, 'profile-export');
      final unleveled = find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.flagsCollection.isHeader && data.headingLevel == 0;
      });

      for (final (text, level) in [
        ('Hồ sơ', 1),
        ('Firebase Demo Area', 2),
        ('Báo cáo PDF', 3),
        ('Thông báo', 3),
        ('Remote Config', 3),
        ('Crashlytics', 3),
      ]) {
        expect(tester.getSemantics(find.text(text)).headingLevel, level,
            reason: text);
      }
      expect(unleveled, findsNothing);

      await tapKey(tester, 'profile-sign-out');
      expect(tester.getSemantics(find.text('Đăng xuất?')).headingLevel, 1);
      expect(unleveled, findsNothing);
      handle.dispose();
    });

    testWidgets('upload progress speaks its phase once, percentage as value',
        (tester) async {
      final handle = tester.ensureSemantics();
      final h = await pumpProfile(tester);
      h.storage.held = Completer();
      await tapKey(tester, 'profile-export');

      h.storage.lastOnProgress!(0.4);
      await tester.pump();
      final progress = find.byType(LinearProgressIndicator);
      final label = tester.getSemantics(progress).label;
      expect(label, isNot(contains('%')));
      // TalkBack reads three ASCII dots as "3 period"; the UI uses '…'.
      expect(label, isNot(contains('...')));
      expect(tester.getSemantics(progress),
          isSemantics(isLiveRegion: true, value: '40%'));

      h.storage.lastOnProgress!(0.7);
      await tester.pump();
      expect(tester.getSemantics(progress),
          isSemantics(isLiveRegion: true, label: label, value: '70%'));

      h.storage.held!.complete('https://storage.test/report.pdf');
      await settle(tester);
      handle.dispose();
    });

    for (final (name, key, title) in [
      ('sign-out', 'profile-sign-out', 'Đăng xuất?'),
      ('test crash', 'profile-test-crash', 'Gây crash thử?'),
    ]) {
      testWidgets('$name dialog is announced, closes in Vietnamese, and fits '
          'at text scale 2', (tester) async {
        final handle = tester.ensureSemantics();
        final h = await pumpProfile(tester, textScale: 2);
        await tapKey(tester, key);

        expect(tester.takeException(), isNull);
        expect(
            tester.getSemantics(find.byType(AppDialog)),
            isSemantics(
                label: title, scopesRoute: true, namesRoute: true));
        expect(find.bySemanticsLabel('Dismiss'), findsNothing);
        expect(find.bySemanticsLabel(AppDialog.barrierLabel), findsOneWidget);

        await tester.ensureVisible(find.bySemanticsLabel('Hủy'));
        await tester.tap(find.bySemanticsLabel('Hủy'));
        await tester.pump(const Duration(milliseconds: 300)); // exit animation
        await settle(tester);
        expect(find.byType(AppDialog), findsNothing);
        expect(h.session.currentUser, isNotNull);
        expect(h.crashlytics.crashes, 0);
        handle.dispose();
      });
    }
  });
}
