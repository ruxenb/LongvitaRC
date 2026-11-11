import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:longvita_core/longvita_core.dart';
import 'package:longvita_admin/admin/admin_auth.dart';
import 'package:longvita_admin/admin/admin_auth_viewmodel.dart';
import 'package:longvita_admin/admin/admin_instrumentation.dart';
import 'package:longvita_admin/admin/admin_shell.dart';
import 'package:longvita_admin/admin/admin_viewmodels.dart';
import 'package:longvita_admin/admin/announcement_viewmodel.dart';
import 'package:longvita_admin/admin/sign_in_web_screen.dart';

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
  final Widget Function(User user, String role)? authorizedBuilder;
  const AdminAccessGate({
    super.key,
    required this.auth,
    this.authorizedBuilder,
  });
  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  late AdminAuthViewModel model;
  @override
  void initState() {
    super.initState();
    model = AdminAuthViewModel(widget.auth);
  }

  @override
  void didUpdateWidget(AdminAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.auth, oldWidget.auth)) {
      model.dispose();
      model = AdminAuthViewModel(widget.auth);
    }
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: model,
    builder: (context, _) {
      final state = model.state;
      if (state.authorized) {
        final sessionModel = model;
        final sessionGeneration = model.sessionGeneration;
        return KeyedSubtree(
          key: ValueKey(model.sessionGeneration),
          child:
              widget.authorizedBuilder?.call(state.user!, state.role!) ??
              _AdminSession(
                user: state.user!,
                role: state.role!,
                onSignOut: model.signOut,
                sessionIsActive: () =>
                    mounted &&
                    identical(model, sessionModel) &&
                    sessionModel.state.authorized &&
                    sessionModel.sessionGeneration == sessionGeneration,
              ),
        );
      }
      return switch (state.phase) {
        AdminAuthPhase.signedOut => SignInWebScreen(
          busy: state.signingIn,
          message: state.message,
          onSignIn: model.signIn,
        ),
        AdminAuthPhase.denied => AdminAuthMessage(
          title: 'Tài khoản không có quyền',
          message: 'Trang quản trị chỉ dành cho tài khoản nhân viên hoặc quản trị viên.',
          actionText: 'Đổi tài khoản',
          action: model.signOut,
        ),
        AdminAuthPhase.roleError => AdminAuthMessage(
          title: 'Không thể kiểm tra quyền truy cập',
          message: state.message!,
          actionText: 'Thử lại',
          action: model.retryRole,
          changeAccount: model.signOut,
        ),
        AdminAuthPhase.authError => AdminAuthMessage(
          title: 'Không thể kết nối đăng nhập',
          message: state.message!,
          actionText: 'Thử lại',
          action: model.retryConnection,
          changeAccount: model.signOut,
        ),
        AdminAuthPhase.signOutError => AdminAuthMessage(
          title: 'Chưa đăng xuất được',
          message: state.message!,
          actionText: 'Thử đăng xuất lại',
          action: model.signOut,
        ),
        AdminAuthPhase.signingOut => const AdminAuthProgress(
          label: 'Đang đăng xuất…',
        ),
        AdminAuthPhase.checkingRole => AdminAuthProgress(
          label: 'Đang kiểm tra quyền truy cập…',
          changeAccount: model.signOut,
        ),
        _ => const AdminAuthProgress(label: 'Đang khôi phục phiên đăng nhập…'),
      };
    },
  );
}

/// Data/form ViewModels are disposed at logout or an auth-session change.
class _AdminSession extends StatelessWidget {
  final User user;
  final String role;
  final Future<void> Function() onSignOut;
  final bool Function() sessionIsActive;
  const _AdminSession({
    required this.user,
    required this.role,
    required this.onSignOut,
    required this.sessionIsActive,
  });
  @override
  Widget build(BuildContext context) {
    final service = context.read<IAdminService>();
    final instrumentation = context.read<AdminWebInstrumentation>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeAdminViewModel(service)),
        ChangeNotifierProvider(create: (_) => DashboardViewModel(service)),
        ChangeNotifierProvider(
          create: (_) => AnnouncementViewModel(
            publisher: context.read<IAnnouncementPublisher>(),
            uid: user.uid,
            role: role,
            sessionIsActive: sessionIsActive,
            trackSuccessfulPublish: instrumentation.logPublishAnnouncement,
          ),
        ),
      ],
      child: AdminShell(user: user, role: role, onSignOut: onSignOut),
    );
  }
}

/// Role-only presentation retained for existing callers; the app uses the VM.
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
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return AdminAuthMessage(
          title: 'Không thể kiểm tra quyền truy cập',
          message: 'Chưa thể xác minh quyền từ máy chủ. Hãy kiểm tra mạng rồi thử lại.',
          actionText: 'Đổi tài khoản',
          action: onDenied,
        );
      }
      if (!isAdminRole(snapshot.data)) {
        return AdminAuthMessage(
          title: 'Tài khoản không có quyền',
          message: 'Trang quản trị chỉ dành cho tài khoản nhân viên hoặc quản trị viên.',
          actionText: 'Đổi tài khoản',
          action: onDenied,
        );
      }
      return authorizedBuilder(snapshot.data!);
    },
  );
}
