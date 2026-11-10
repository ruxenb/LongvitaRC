import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:longvita_admin/admin/admin_auth.dart';

enum AdminAuthPhase {
  restoring,
  signedOut,
  checkingRole,
  authorized,
  denied,
  authError,
  roleError,
  signingOut,
  signOutError,
}

@immutable
class AdminAuthState {
  final AdminAuthPhase phase;
  final User? user;
  final String? role;
  final String? message;
  final bool signingIn;

  const AdminAuthState(
    this.phase, {
    this.user,
    this.role,
    this.message,
    this.signingIn = false,
  });

  bool get authorized =>
      phase == AdminAuthPhase.authorized && user != null && isAdminRole(role);
}

/// Owns auth/role requests independently of frames and StreamBuilder scheduling.
class AdminAuthViewModel extends ChangeNotifier {
  final IAdminAuthGateway auth;
  final Duration roleTimeout;
  final Duration restoreTimeout;
  final Duration signOutTimeout;
  StreamSubscription<User?>? _subscription;
  Timer? _restoreTimer;
  bool _disposed = false;
  bool _loginInFlight = false;
  bool _logoutInFlight = false;
  bool _awaitExplicitLogin = false;
  int _streamGeneration = 0;
  int _sessionGeneration = 0;
  int _roleRequest = 0;
  int _loginRequest = 0;
  User? _user;
  AdminAuthState _state = const AdminAuthState(AdminAuthPhase.restoring);

  AdminAuthState get state => _state;
  int get sessionGeneration => _sessionGeneration;

  AdminAuthViewModel(
    this.auth, {
    this.roleTimeout = const Duration(seconds: 15),
    this.restoreTimeout = const Duration(seconds: 15),
    this.signOutTimeout = const Duration(seconds: 15),
  }) {
    _subscribe();
  }

  void _set(AdminAuthState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  void _subscribe() {
    final generation = ++_streamGeneration;
    _subscription?.cancel();
    _restoreTimer?.cancel();
    _restoreTimer = Timer(restoreTimeout, () {
      if (!_disposed &&
          generation == _streamGeneration &&
          _state.phase == AdminAuthPhase.restoring) {
        _set(
          const AdminAuthState(
            AdminAuthPhase.authError,
            message: 'Chưa thể khôi phục phiên đăng nhập. Hãy kiểm tra mạng rồi thử lại.',
          ),
        );
      }
    });
    try {
      _subscription = auth.authStateChanges().listen(
        (user) {
          if (!_disposed && generation == _streamGeneration) _onUser(user);
        },
        onError: (Object error) {
          if (_disposed || generation != _streamGeneration) return;
          _restoreTimer?.cancel();
          _endSession();
          if (_awaitExplicitLogin || _logoutInFlight) return;
          _set(
            const AdminAuthState(
              AdminAuthPhase.authError,
              message:
                  'Không thể theo dõi phiên đăng nhập. Hãy thử kết nối lại.',
            ),
          );
        },
      );
    } catch (_) {
      _restoreTimer?.cancel();
      _endSession();
      _set(
        const AdminAuthState(
          AdminAuthPhase.authError,
          message: 'Không thể kết nối dịch vụ đăng nhập. Hãy thử lại.',
        ),
      );
    }
  }

  void _endSession() {
    _sessionGeneration++;
    _roleRequest++;
    _user = null;
    auth.invalidateRoleCache();
  }

  void _onUser(User? user) {
    _restoreTimer?.cancel();
    if (user == null) {
      final message = _state.phase == AdminAuthPhase.signedOut
          ? _state.message
          : null;
      _endSession();
      if (!_logoutInFlight) {
        _set(
          AdminAuthState(
            AdminAuthPhase.signedOut,
            signingIn: _loginInFlight,
            message: message,
          ),
        );
      }
      return;
    }
    if (_awaitExplicitLogin || _logoutInFlight) return;
    if (_user?.uid == user.uid) return;
    _endSession();
    _user = user;
    _loadRole();
  }

  bool _ownsRole(int session, int request, String uid) =>
      !_disposed &&
      !_awaitExplicitLogin &&
      !_logoutInFlight &&
      session == _sessionGeneration &&
      request == _roleRequest &&
      _user?.uid == uid;

  Future<void> _loadRole() async {
    final user = _user;
    if (_disposed || user == null || _awaitExplicitLogin || _logoutInFlight) {
      return;
    }
    final session = _sessionGeneration;
    final request = ++_roleRequest;
    _set(
      AdminAuthState(
        AdminAuthPhase.checkingRole,
        user: user,
        signingIn: _loginInFlight,
      ),
    );
    try {
      final role = await auth.loadAuthorizedRole(user).timeout(roleTimeout);
      if (!_ownsRole(session, request, user.uid)) return;
      _set(
        AdminAuthState(
          isAdminRole(role) ? AdminAuthPhase.authorized : AdminAuthPhase.denied,
          user: user,
          role: isAdminRole(role) ? role : null,
          signingIn: _loginInFlight,
        ),
      );
    } catch (_) {
      if (!_ownsRole(session, request, user.uid)) return;
      _set(
        AdminAuthState(
          AdminAuthPhase.roleError,
          user: user,
          message: 'Chưa thể xác minh quyền từ máy chủ. Hãy kiểm tra mạng rồi thử lại.',
          signingIn: _loginInFlight,
        ),
      );
    }
  }

  Future<void> retryRole() async {
    if (_disposed || _state.phase != AdminAuthPhase.roleError) return;
    auth.invalidateRoleCache();
    await _loadRole();
  }

  void retryConnection() {
    if (_disposed ||
        _state.phase != AdminAuthPhase.authError ||
        _awaitExplicitLogin) {
      return;
    }
    _endSession();
    _set(const AdminAuthState(AdminAuthPhase.restoring));
    _subscribe();
  }

  Future<void> signIn() async {
    if (_disposed ||
        _loginInFlight ||
        _logoutInFlight ||
        !{
          AdminAuthPhase.signedOut,
          AdminAuthPhase.authError,
        }.contains(_state.phase)) {
      return;
    }
    _loginInFlight = true;
    _awaitExplicitLogin = false;
    final request = ++_loginRequest;
    _set(const AdminAuthState(AdminAuthPhase.signedOut, signingIn: true));
    try {
      await auth.signInWithGoogle();
      if (_disposed || request != _loginRequest || _awaitExplicitLogin) return;
      final user = auth.currentUser;
      if (user != null) {
        _onUser(user);
      } else if (_user == null) {
        _set(
          const AdminAuthState(
            AdminAuthPhase.signedOut,
            message: 'Chưa xác nhận được tài khoản Google. Hãy thử lại.',
          ),
        );
      }
    } catch (error) {
      if (!_disposed &&
          request == _loginRequest &&
          !_awaitExplicitLogin &&
          _user == null) {
        _set(
          AdminAuthState(
            AdminAuthPhase.signedOut,
            message: friendlyAdminAuthError(error),
          ),
        );
      }
    } finally {
      _loginInFlight = false;
      if (!_disposed && _state.signingIn) {
        _set(
          AdminAuthState(
            _state.phase,
            user: _state.user,
            role: _state.role,
            message: _state.message,
          ),
        );
      }
    }
  }

  Future<void> signOut() async {
    if (_disposed || _logoutInFlight) return;
    _logoutInFlight = true;
    _awaitExplicitLogin = true;
    _loginRequest++;
    _endSession();
    _set(const AdminAuthState(AdminAuthPhase.signingOut));
    try {
      await auth.signOut().timeout(signOutTimeout);
      if (_disposed) return;
      if (auth.currentUser != null) throw StateError('sign-out-not-confirmed');
      _set(const AdminAuthState(AdminAuthPhase.signedOut));
    } catch (_) {
      if (!_disposed) {
        _set(
          const AdminAuthState(
            AdminAuthPhase.signOutError,
            message: 'Chưa đăng xuất được. Hãy đóng cửa sổ Google đang mở rồi thử đăng xuất lại.',
          ),
        );
      }
    } finally {
      _logoutInFlight = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _streamGeneration++;
    _loginRequest++;
    _roleRequest++;
    _restoreTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
