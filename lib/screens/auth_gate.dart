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
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
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
  ///
  /// The snackbar may wait in the shared queue behind feedback of another
  /// screen, so it cannot be pulled out from here when the session ends.
  /// Its content checks the session instead whenever it is built.
  void _showArrivedNotification() {
    final epoch = _profile.sessionEpoch;
    if (!_isCurrent(epoch)) return;
    final arrival = _profile.takeArrivedNotification();
    if (arrival == null) return;
    final text = arrival.title ?? arrival.body;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrent(epoch)) return;
      final notice = _NoticeTicket(epoch);
      showAppSnackBar(
        context,
        message: text == null ? 'Có thông báo mới.' : 'Thông báo mới: $text',
        actionLabel: 'Xem',
        onAction: () => _openProfile(epoch),
        wrap: (content) => _SessionNotice(ticket: notice, child: content),
      );
    });
  }

  void _openProfile(int epoch) {
    if (!_isCurrent(epoch)) return;
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

/// One message snackbar. Every copy of its content shares it, because during
/// a route change the messenger builds the snackbar in more than one Scaffold.
class _NoticeTicket {
  final int epoch;
  bool removed = false;

  _NoticeTicket(this.epoch);
}

/// Shows [child] only while the session that received the message lasts.
///
/// A messenger builds only the snackbar at the head of its queue, so when
/// this is built it is the current snackbar. If the session has ended by
/// then, it shows nothing and removes itself. Snackbars of other screens,
/// ahead of it or behind it, are left alone.
class _SessionNotice extends StatelessWidget {
  final _NoticeTicket ticket;
  final Widget child;

  const _SessionNotice({required this.ticket, required this.child});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthViewModel>().state is AuthSignedIn;
    final profile = context.watch<ProfileViewModel>();
    if (signedIn && !profile.isSessionStale(ticket.epoch)) return child;

    if (!ticket.removed) {
      final messenger = ScaffoldMessenger.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Still mounted means still the head of the queue.
        if (ticket.removed || !context.mounted) return;
        ticket.removed = true;
        messenger.removeCurrentSnackBar();
      });
    }
    return const SizedBox.shrink();
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
