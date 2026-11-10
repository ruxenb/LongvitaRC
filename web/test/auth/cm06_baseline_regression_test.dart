import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_admin/admin/admin_app.dart';

import 'auth_fakes.dart';

void main() {
  testWidgets('CM06: role-only gate denies an unexpected non-null role', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminRoleGate(
          role: Future.value('user'),
          onDenied: () {},
          authorizedBuilder: (_) => const Text('privileged shell'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('privileged shell'), findsNothing);
    expect(find.text('Tài khoản không có quyền'), findsOneWidget);
  });

  testWidgets('CM06: role failures never expose raw SDK details', (
    tester,
  ) async {
    final failure = Completer<String?>();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminRoleGate(
          role: failure.future,
          onDenied: () {},
          authorizedBuilder: (_) => const Text('privileged shell'),
        ),
      ),
    );
    failure.completeError(StateError('private-account-detail'));
    await tester.pumpAndSettle();
    expect(find.textContaining('private-account-detail'), findsNothing);
    expect(find.text('Không thể kiểm tra quyền truy cập'), findsOneWidget);
  });

  testWidgets('CM06: a stalled role read has a bounded wait and retry', (
    tester,
  ) async {
    final auth = FakeAdminAuth()..user = AuthTestUser('a');
    final pending = Completer<String?>();
    auth.roleLoader = (_) => pending.future;
    await tester.pumpWidget(LongvitaAdminApp(auth: auth));
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    pending.complete('staff');
    await tester.pump();
    await auth.close();
  });
}
