import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:longvita_admin/admin/admin_auth.dart';

class AuthTestUser implements User {
  @override
  final String uid;
  @override
  String? get email => '$uid@example.test';
  AuthTestUser(this.uid);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminAuth implements IAdminAuthGateway {
  User? user;
  int signIns = 0;
  int signOuts = 0;
  int invalidations = 0;
  final roleCalls = <String>[];
  final changes = StreamController<User?>.broadcast(sync: true);
  Future<void> Function()? googleAction;
  Future<void> Function()? logoutAction;
  Future<String?> Function(User user) roleLoader = (_) async => 'staff';
  late final Stream<User?> stream = Stream<User?>.multi((sink) {
    sink.add(user);
    final subscription = changes.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.onCancel = subscription.cancel;
  });

  @override
  User? get currentUser => user;
  @override
  void invalidateRoleCache() => invalidations++;
  void emit(User? value) {
    user = value;
    changes.add(value);
  }

  @override
  Stream<User?> authStateChanges() => stream;
  @override
  Future<void> signInWithGoogle() async {
    signIns++;
    await googleAction?.call();
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (logoutAction != null) {
      await logoutAction!();
    } else {
      emit(null);
    }
  }

  @override
  Future<String?> loadAuthorizedRole(User user) {
    roleCalls.add(user.uid);
    return roleLoader(user);
  }

  Future<void> close() => changes.close();
}
