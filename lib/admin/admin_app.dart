import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'admin_shell.dart';

class LongvitaAdminApp extends StatelessWidget {
  final IAdminAuthGateway auth;

  const LongvitaAdminApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Trang quản trị Longvita',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: AdminAccessGate(auth: auth),
  );
}

class AdminAccessGate extends StatefulWidget {
  final IAdminAuthGateway auth;

  const AdminAccessGate({super.key, required this.auth});

  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  int _sessionGeneration = 0;
  String? _activeUid;
  Future<String?>? _roleFuture;

  Future<String?> _roleFor(User user) {
    if (_activeUid == user.uid && _roleFuture != null) return _roleFuture!;
    if (_activeUid != user.uid) {
      _activeUid = user.uid;
      _sessionGeneration++;
    }
    final requestGeneration = _sessionGeneration;
    return _roleFuture = _guardRole(user, requestGeneration);
  }

  Future<String?> _guardRole(User user, int requestGeneration) async {
    final role = await widget.auth.loadAuthorizedRole(user);
    if (!mounted ||
        requestGeneration != _sessionGeneration ||
        _activeUid != user.uid) {
      throw const _StaleAdminSession();
    }
    return role;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: widget.auth.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const _CenteredProgress();
      }
      final user = auth.data;
      if (user == null) {
        if (_activeUid != null) {
          _activeUid = null;
          _roleFuture = null;
          _sessionGeneration++;
        }
        return _AdminSignIn(auth: widget.auth);
      }
      return AdminRoleGate(
        key: ValueKey(user.uid),
        role: _roleFor(user),
        onDenied: widget.auth.signOut,
        authorizedBuilder: (role) =>
            AdminShell(user: user, role: role, onSignOut: widget.auth.signOut),
      );
    },
  );
}

class AdminRoleGate extends StatelessWidget {
  final Future<String?> role;
  final VoidCallback onDenied;
  final Widget Function(String role) authorizedBuilder;

  const AdminRoleGate({
    super.key,
    required this.role,
    required this.onDenied,
    required this.authorizedBuilder,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: role,
    builder: (context, role) {
      if (role.connectionState != ConnectionState.done) {
        return const _CenteredProgress();
      }
      if (role.error is _StaleAdminSession) {
        return const _CenteredProgress();
      }
      if (role.hasError) {
        return _AccessMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Không thể kiểm tra quyền truy cập',
          message: role.error.toString(),
          action: onDenied,
        );
      }
      if (role.data == null) {
        return _AccessMessage(
          icon: Icons.lock_outline,
          title: 'Tài khoản không có quyền',
          message: 'Trang quản trị chỉ dành cho tài khoản nhân viên hoặc quản trị viên.',
          action: onDenied,
        );
      }
      return authorizedBuilder(role.data!);
    },
  );
}

class _AdminSignIn extends StatefulWidget {
  final IAdminAuthGateway auth;
  const _AdminSignIn({required this.auth});

  @override
  State<_AdminSignIn> createState() => _AdminSignInState();
}

class _AdminSignInState extends State<_AdminSignIn> {
  bool busy = false;
  String? error;

  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.signInWithGoogle();
    } catch (value) {
      if (mounted) setState(() => error = friendlyAdminAuthError(value));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.eco_outlined,
                  size: 56,
                  color: AppColors.actionPrimary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Trang quản trị Longvita',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quản trị dinh dưỡng trường thọ',
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.feedbackError),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: busy ? null : signIn,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Đăng nhập bằng Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _StaleAdminSession implements Exception {
  const _StaleAdminSession();
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AccessMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  const _AccessMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: AppColors.feedbackError),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: action,
                  child: const Text('Đổi tài khoản'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
