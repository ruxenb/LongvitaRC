import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'admin_shell.dart';

class LongvitaAdminApp extends StatelessWidget {
  const LongvitaAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Trang quản trị Longvita',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const AdminAccessGate(),
  );
}

class AdminAccessGate extends StatelessWidget {
  const AdminAccessGate({super.key});

  Future<String?> _role(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = snapshot.data()?['role'] as String?;
    return role == 'staff' || role == 'admin' ? role : null;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const _CenteredProgress();
      }
      final user = auth.data;
      if (user == null) return const _AdminSignIn();
      return FutureBuilder<String?>(
        future: _role(user),
        builder: (context, role) {
          if (role.connectionState != ConnectionState.done) {
            return const _CenteredProgress();
          }
          if (role.hasError) {
            return _AccessMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Không thể kiểm tra quyền truy cập',
              message: role.error.toString(),
              action: () => FirebaseAuth.instance.signOut(),
            );
          }
          if (role.data == null) {
            return _AccessMessage(
              icon: Icons.lock_outline,
              title: 'Tài khoản không có quyền',
              message: 'Trang quản trị chỉ dành cho tài khoản nhân viên hoặc quản trị viên.',
              action: () => FirebaseAuth.instance.signOut(),
            );
          }
          return AdminShell(user: user, role: role.data!);
        },
      );
    },
  );
}

class _AdminSignIn extends StatefulWidget {
  const _AdminSignIn();

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
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
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
