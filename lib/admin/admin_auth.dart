import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class IAdminAuthGateway {
  Stream<User?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<String?> loadAuthorizedRole(User user);
}

class FirebaseAdminAuthGateway implements IAdminAuthGateway {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AdminRoleCache _roleCache = AdminRoleCache();

  FirebaseAdminAuthGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() =>
      _auth.signInWithPopup(GoogleAuthProvider()).then((_) {});

  @override
  Future<void> signOut() async {
    _roleCache.clear();
    await _auth.signOut();
  }

  @override
  Future<String?> loadAuthorizedRole(User user) {
    return _roleCache.load(user.uid, () async {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final value = snapshot.data()?['role'] as String?;
      return value == 'staff' || value == 'admin' ? value : null;
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
