import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_admin/admin/admin_app.dart';
import 'package:longvita_admin/admin/sign_in_web_screen.dart';
import 'package:longvita_core/longvita_core.dart';

import 'auth_fakes.dart';

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  testWidgets('sign-in uses Core button with disabled loading semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        host(SignInWebScreen(busy: true, onSignIn: () {})),
      );
      expect(find.text('Đang mở tài khoản Google…'), findsOneWidget);
      final data = tester.getSemantics(find.byType(AppButton));
      expect(
        data,
        matchesSemantics(
          label: 'Đang mở tài khoản Google…',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester
            .getSemantics(find.text('Trang quản trị Longvita'))
            .getSemanticsData()
            .headingLevel,
        1,
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final size in [
    const Size(360, 480),
    const Size(412, 620),
    const Size(1280, 800),
  ]) {
    testWidgets('sign-in/error at $size and text 2.0 scrolls without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          SignInWebScreen(
            onSignIn: () {},
            message:
                'Không thể kết nối đến Google. Hãy kiểm tra mạng rồi thử lại.',
          ),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(AppButton));
      expect(find.text('Đăng nhập bằng Google').hitTestable(), findsOneWidget);
      await tester.pumpWidget(
        host(
          AdminAuthMessage(
            title: 'Không thể kiểm tra quyền truy cập',
            message: 'Chưa thể xác minh quyền từ máy chủ. Hãy kiểm tra mạng rồi thử lại.',
            actionText: 'Thử lại',
            action: () {},
            changeAccount: () {},
          ),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Đổi tài khoản'));
      expect(find.text('Đổi tài khoản').hitTestable(), findsOneWidget);
    });
  }

  testWidgets(
    'real access gate retries a failed role query without Google login',
    (tester) async {
      final auth = FakeAdminAuth()..user = AuthTestUser('a');
      auth.roleLoader = (_) async => throw StateError('private-id');
      await tester.pumpWidget(
        host(
          AdminAccessGate(
            auth: auth,
            authorizedBuilder: (user, role) => Text('authorized:$role'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('private-id'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
      auth.roleLoader = (_) async => 'admin';
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('authorized:admin'), findsOneWidget);
      expect(auth.signIns, 0);
      expect(auth.roleCalls, ['a', 'a']);
      await tester.pumpWidget(const SizedBox());
      await auth.close();
    },
  );

  testWidgets(
    'same UID re-login replaces the authorized subtree without an intermediate frame',
    (tester) async {
      final auth = FakeAdminAuth()..user = AuthTestUser('a');
      var starts = 0;
      await tester.pumpWidget(
        host(
          AdminAccessGate(
            auth: auth,
            authorizedBuilder: (_, _) =>
                _SessionMarker(onStart: () => ++starts),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(starts, 1);
      auth.emit(null);
      auth.emit(AuthTestUser('a'));
      await tester.pumpAndSettle();
      expect(starts, 2);
      await tester.pumpWidget(const SizedBox());
      await auth.close();
    },
  );

  testWidgets('role error does not endlessly animate after the timeout', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final pending = Completer<String?>();
    auth.roleLoader = (_) => pending.future;
    await tester.pumpWidget(host(AdminAccessGate(auth: auth)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    pending.complete(null);
    await tester.pump();
    await auth.close();
  });
}

class _SessionMarker extends StatefulWidget {
  final VoidCallback onStart;
  const _SessionMarker({required this.onStart});
  @override
  State<_SessionMarker> createState() => _SessionMarkerState();
}

class _SessionMarkerState extends State<_SessionMarker> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => const Text('privileged session');
}
