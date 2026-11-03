import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/app_supporting.dart';
import '../widgets/state_views.dart';
import '../theme/app_spacing.dart';
import 'auth_recovery_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'sign_in_screen.dart';

/// Routes by [AuthState] (S3-6, owner Thắng; auth states from S3-3).
///
/// Only [AuthSignedIn] reaches protected content. When the session ends,
/// routes pushed above this gate are removed so Back cannot return to
/// protected screens of the previous user.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wasSignedIn = false;
  late final ProfileViewModel _profile;

  @override
  void initState() {
    super.initState();
    _profile = context.read<ProfileViewModel>();
    _profile.addListener(_openTappedNotification);
    _profile.addListener(_showArrivedNotification);
  }

  @override
  void dispose() {
    _profile.removeListener(_openTappedNotification);
    _profile.removeListener(_showArrivedNotification);
    super.dispose();
  }

  bool get _signedIn => context.read<AuthViewModel>().state is AuthSignedIn;

  /// A tap waits here until someone is signed in. Temporary contract: every
  /// tap opens the notification center on Profile (owners agreed 02/11/2026).
  void _openTappedNotification() {
    if (!mounted || !_signedIn) return;
    if (!_profile.takeNotificationOpenRequest()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openProfile());
  }

  /// A message received while the app is open shows on whatever screen is in
  /// front, since Android puts nothing in the notification shade then.
  void _showArrivedNotification() {
    if (!mounted || !_signedIn) return;
    final arrival = _profile.takeArrivedNotification();
    if (arrival == null) return;
    final text = arrival.title ?? arrival.body;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: text == null ? 'Có thông báo mới.' : 'Thông báo mới: $text',
        actionLabel: 'Xem',
        onAction: _openProfile,
      );
    });
  }

  void _openProfile() {
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(ProfileScreen.routeName, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthViewModel>().state;

    final signedIn = state is AuthSignedIn;
    if (_wasSignedIn && !signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    if (signedIn && !_wasSignedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openTappedNotification());
    }
    _wasSignedIn = signedIn;

    return switch (state) {
      AuthInitializing() => const _GateLoading(
          title: 'Đang kiểm tra phiên đăng nhập',
        ),
      AuthLoadingProfile() => const _GateLoading(
          title: 'Đang tải hồ sơ của bạn',
        ),
      AuthSignedOut() || AuthSigningIn() => const SignInScreen(),
      AuthProfileError(:final failure) => AuthRecoveryScreen(failure: failure),
      AuthSignedIn() => const HomeScreen(),
    };
  }
}

class _GateLoading extends StatelessWidget {
  final String title;
  const _GateLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            child: LoadingView(title: title),
          ),
        ),
      ),
    );
  }
}
