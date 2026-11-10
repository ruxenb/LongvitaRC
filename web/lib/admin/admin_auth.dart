import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class IAdminAuthGateway {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<String?> loadAuthorizedRole(User user);
  void invalidateRoleCache();
}

bool isAdminRole(String? role) => role == 'staff' || role == 'admin';

/// Serialize SDK auth mutations so a delayed popup cannot finish after logout.
class AdminAuthMutations {
  final Future<void> Function() login;
  final Future<void> Function() logout;
  Future<void>? _loginRequest;
  Future<void>? _logoutRequest;

  AdminAuthMutations({required this.login, required this.logout});

  Future<void> signIn() {
    if (_logoutRequest != null) {
      return Future.error(const AdminAuthActionPending());
    }
    if (_loginRequest != null) return _loginRequest!;
    late final Future<void> request;
    request = Future.sync(login).whenComplete(() {
      if (identical(_loginRequest, request)) _loginRequest = null;
    });
    return _loginRequest = request;
  }

  Future<void> signOut() {
    if (_logoutRequest != null) return _logoutRequest!;
    final pendingLogin = _loginRequest;
    late final Future<void> request;
    request =
        () async {
          if (pendingLogin != null) {
            try {
              await pendingLogin;
            } catch (_) {
              /* Logout still runs after a cancelled popup. */
            }
          }
          await logout();
        }().whenComplete(() {
          if (identical(_logoutRequest, request)) _logoutRequest = null;
        });
    return _logoutRequest = request;
  }
}

class AdminAuthActionPending implements Exception {
  const AdminAuthActionPending();
}

class FirebaseAdminAuthGateway implements IAdminAuthGateway {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AdminRoleCache _roleCache = AdminRoleCache();
  late final AdminAuthMutations _mutations = AdminAuthMutations(
    login: () => _auth.signInWithPopup(GoogleAuthProvider()).then((_) {}),
    logout: _auth.signOut,
  );

  FirebaseAdminAuthGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() => _mutations.signIn();

  @override
  Future<void> signOut() async {
    _roleCache.clear();
    await _mutations.signOut();
  }

  @override
  void invalidateRoleCache() => _roleCache.clear();

  @override
  Future<String?> loadAuthorizedRole(User user) {
    return _roleCache.load(user.uid, () async {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final value = snapshot.data()?['role'];
      return value is String && isAdminRole(value) ? value : null;
    });
  }
}

class AdminRoleCache {
  final Map<String, String?> _values = {};
  final Map<String, Future<String?>> _requests = {};
  var _generation = 0;

  Future<String?> load(String uid, Future<String?> Function() loader) {
    if (_values.containsKey(uid)) return Future.value(_values[uid]);
    final existing = _requests[uid];
    if (existing != null) return existing;

    final generation = _generation;
    late final Future<String?> request;
    request = () async {
      try {
        final value = await loader();
        if (_generation == generation && identical(_requests[uid], request)) {
          _values[uid] = value;
        }
        return value;
      } finally {
        if (_generation == generation && identical(_requests[uid], request)) {
          _requests.remove(uid);
        }
      }
    }();
    _requests[uid] = request;
    return request;
  }

  void clear() {
    _generation++;
    _values.clear();
    _requests.clear();
  }
}

String friendlyAdminAuthError(Object error) {
  if (error is AdminAuthActionPending) {
    return 'Đang hoàn tất đăng xuất. Hãy đóng cửa sổ Google đang mở rồi thử lại.';
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-cancelled':
        return 'Bạn đã hủy đăng nhập. Hãy thử lại khi sẵn sàng.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ đăng nhập. Hãy cho phép popup rồi thử lại.';
      case 'network-request-failed':
        return 'Không thể kết nối đến Google. Hãy kiểm tra mạng rồi thử lại.';
      case 'operation-not-allowed':
        return 'Đăng nhập Google chưa được bật cho dự án Firebase.';
    }
  }
  return 'Đăng nhập không thành công. Vui lòng thử lại.';
}
