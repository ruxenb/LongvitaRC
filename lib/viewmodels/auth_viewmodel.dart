import 'dart:async';
import '../models/user_model.dart';
import '../models/view_state.dart';
import '../services/i_auth_service.dart';
import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  final IAuthService authService;
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;

  StreamSubscription<UserModel?>? _authSubscription;
  UserModel? _currentUser;
  ViewState<UserModel?> _state = const ViewStateIdle();

  AuthViewModel({
    required this.authService,
    required this.analytics,
    required this.crashlytics,
  }) {
    _init();
  }

  ViewState<UserModel?> get state => _state;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void _init() {
    _state = const ViewStateLoading('Đang kiểm tra phiên đăng nhập...');
    _authSubscription = authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        analytics.setUserId(user.uid);
        crashlytics.setUserId(user.uid);
        crashlytics.setCustomKey('user_role', user.role);
        _state = ViewStateSuccess(user);
      } else {
        _state = const ViewStateEmpty(message: 'Chưa đăng nhập');
      }
      notifyListeners();
    }, onError: (e, s) {
      crashlytics.recordError(e, s, reason: 'Auth state stream error');
      _state = ViewStateError('Lỗi xác thực người dùng', e);
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _state = const ViewStateLoading('Đang kết nối tài khoản Google...');
    notifyListeners();

    try {
      final user = await authService.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        await analytics.logLogin(method: 'google');
        _state = ViewStateSuccess(user);
        notifyListeners();
        return true;
      } else {
        _state = const ViewStateEmpty(message: 'Đăng nhập bị hủy');
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Google Sign-In failed');
      _state = ViewStateError('Không thể đăng nhập bằng Google. Vui lòng thử lại.', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _state = const ViewStateLoading('Đang đăng xuất...');
    notifyListeners();

    try {
      await authService.signOut();
      _currentUser = null;
      await analytics.logEvent('logout');
      _state = const ViewStateEmpty(message: 'Đã đăng xuất');
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Sign-Out failed');
      _state = ViewStateError('Lỗi khi đăng xuất', e);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
