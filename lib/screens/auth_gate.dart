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

  /// Snackbars this gate showed for messages, each with the session it
  /// belongs to. They outlive a screen change, so they are closed here when
  /// that session ends; other snackbars are left alone.
  final List<({int epoch, ScaffoldFeatureController controller})> _shown = [];

  @override
  void initState() {
    super.initState();
    _profile = context.read<ProfileViewModel>();
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    _closeEndedSessions();
    _openTappedNotification();
    _showArrivedNotification();
  }

  /// True while [epoch] is the session in progress. Checked when a callback
  /// runs, not only when it is scheduled, because the session may end or
  /// change in between, including the same user signing out and back in.
  bool _isCurrent(int epoch) =>
      mounted &&
      context.read<AuthViewModel>().state is AuthSignedIn &&
      !_profile.isSessionStale(epoch);

  /// A tap waits here until someone is signed in. Temporary contract: every
  /// tap opens the notification center on Profile (owners agreed 02/11/2026).
  void _openTappedNotification() {
    final epoch = _profile.sessionEpoch;
    if (!_isCurrent(epoch)) return;
    if (!_profile.takeNotificationOpenRequest()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openProfile(epoch));
  }

  /// A message received while the app is open shows on whatever screen is in
  /// front, since Android puts nothing in the notification shade then.
  void _showArrivedNotification() {
    final epoch = _profile.sessionEpoch;
    if (!_isCurrent(epoch)) return;
    final arrival = _profile.takeArrivedNotification();
    if (arrival == null) return;
    final text = arrival.title ?? arrival.body;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrent(epoch)) return;
      final controller = showAppSnackBar(
        context,
        message: text == null ? 'Có thông báo mới.' : 'Thông báo mới: $text',
        actionLabel: 'Xem',
        onAction: () => _openProfile(epoch),
      );
      final entry = (epoch: epoch, controller: controller);
      _shown.add(entry);
      controller.closed.whenComplete(() => _shown.remove(entry));
    });
  }

  void _openProfile(int epoch) {
    if (!_isCurrent(epoch)) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(ProfileScreen.routeName, (route) => route.isFirst);
  }

  /// Removes message snackbars of a session that is no longer in progress,
  /// whether shown or still queued.
  void _closeEndedSessions() {
    final signedIn =
        mounted && context.read<AuthViewModel>().state is AuthSignedIn;
    for (final entry in List.of(_shown)) {
      if (!signedIn || _profile.isSessionStale(entry.epoch)) {
        _shown.remove(entry);
        entry.controller.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthViewModel>().state;

    final signedIn = state is AuthSignedIn;
    if (_wasSignedIn && !signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeEndedSessions();
        Navigator.of(context).popUntil((route) => route.isFirst);
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
