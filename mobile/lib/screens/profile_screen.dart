import 'package:longvita_core/models/report_metadata_state.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita_core/models/app_notification.dart';
import 'package:longvita_core/models/user_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:longvita_core/widgets/longvita_widgets.dart';

/// Profile and Firebase Demo Area (S4-13). No approved Figma frame exists
/// (S1-5), so the layout is composed from the Longvita design system. All
/// logic lives in [ProfileViewModel] and [AuthViewModel]; `AuthGate` removes
/// this route when the session ends.
class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileViewModel>();
    profile.refreshInbox();
    _lifecycle = AppLifecycleListener(onResume: profile.refreshInbox);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Hồ sơ',
        backSemanticLabel: 'Quay lại',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) _IdentityCard(user: user),
              const SizedBox(height: AppSpacing.s24),
              Semantics(
                header: true,
                headingLevel: 2,
                child: const Text(
                  'Firebase Demo Area',
                  style: AppTypography.headingM,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              const _ExportCard(),
              const SizedBox(height: AppSpacing.s16),
              const _InboxCard(),
              const SizedBox(height: AppSpacing.s16),
              const _RemoteConfigCard(),
              const SizedBox(height: AppSpacing.s16),
              const _CrashlyticsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final UserModel user;

  const _IdentityCard({required this.user});

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: AppDialog.barrierLabel,
      builder: (dialogContext) => AppDialog.confirmation(
        icon: AppIcons.infoOutline,
        title: 'Đăng xuất?',
        message:
            'PDF đã lưu trên máy này sẽ bị xóa. '
            'Ứng dụng không lưu bản sao PDF trên đám mây. '
            'Thực đơn đã lưu vẫn còn.',
        primaryLabel: 'Đồng ý',
        onPrimary: () => Navigator.of(dialogContext).pop(true),
        secondaryLabel: 'Hủy',
        onSecondary: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.bgSelected,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  onBackgroundImageError: photoUrl != null ? (_, _) {} : null,
                  child: photoUrl == null
                      ? const Icon(
                          AppIcons.accountCircle,
                          size: AppSizes.icon,
                          color: AppColors.actionPrimary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // One stop for who is signed in; the card itself has no
                    // label, so focus does not frame the whole card.
                    Semantics(
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: AppTypography.title),
                          const SizedBox(height: AppSpacing.s4),
                          // A long address breaks before the @ rather than
                          // inside a word.
                          Text(
                            user.email.replaceFirst('@', '​@'),
                            semanticsLabel: user.email,
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AppBadge(
                      kind: AppBadgeKind.pending,
                      label: 'Vai trò: ${user.role}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            key: const Key('profile-sign-out'),
            text: 'Đăng xuất',
            variant: AppButtonVariant.secondary,
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

/// Title and one line of explanation shared by the demo cards.
///
/// Each is its own semantics node. Text that is not its own node merges into
/// the card's node, which then reads before everything in the card and, here,
/// would turn the description into part of the heading.
class _CardHeader extends StatelessWidget {
  final String title;
  final String description;

  const _CardHeader({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          header: true,
          headingLevel: 3,
          child: Text(title, style: AppTypography.title),
        ),
        const SizedBox(height: AppSpacing.s4),
        Semantics(
          container: true,
          child: Text(
            description,
            style: AppTypography.supporting.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// An outcome shown with an icon and text, never by colour alone.
class _Notice extends StatelessWidget {
  final String message;
  final bool isError;

  const _Notice({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.feedbackError : AppColors.textPrimary;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? AppIcons.errorOutline : AppIcons.infoOutline,
              size: AppSizes.icon,
              color: isError
                  ? AppColors.feedbackError
                  : AppColors.actionPrimary,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.supporting.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard();

  Future<void> _open(BuildContext context, Future<bool> Function() open) async {
    final opened = await open();
    if (!opened && context.mounted) {
      showAppSnackBar(context, message: 'Không mở được file PDF đã lưu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final plan = context.watch<MealPlanViewModel>().activePlan;
    final localState = profile.exportState;
    final uploadState = profile.uploadState;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: 'Báo cáo PDF',
            description: plan == null
                ? 'Chưa có thực đơn để xuất. Hãy tạo thực đơn trước.'
                : profile.isStorageDemo
                ? 'Demo: lưu PDF trên máy rồi tải lên Storage Emulator.'
                : 'Xuất thực đơn đang có và lưu PDF trên máy.',
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            key: const Key('profile-export'),
            text: 'Xuất báo cáo PDF',
            loadingText: 'Đang xuất PDF…',
            isLoading: profile.isExporting,
            onPressed: plan == null ? null : () => profile.exportPdf(plan),
          ),
          if (localState is ViewStateLoading<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            _Notice(message: localState.message ?? 'Đang xuất PDF…'),
          ],
          if (localState is ViewStateError<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            _Notice(message: localState.message, isError: true),
          ],
          if (profile.lastExport != null) ...[
            const SizedBox(height: AppSpacing.s16),
            const _Notice(message: 'Đã lưu PDF trên máy.'),
            const _ReportMetadataStatus(),
          ],
          if (profile.isStorageDemo &&
              uploadState is ViewStateLoading<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            _ExportProgress(
              message:
                  uploadState.message ?? 'Đang tải PDF lên Storage Emulator…',
              progress: profile.uploadProgress,
            ),
          ],
          if (profile.canCancelUpload) ...[
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              key: const Key('profile-cancel-upload'),
              text: 'Hủy tải lên',
              variant: AppButtonVariant.secondary,
              onPressed: profile.cancelUpload,
            ),
          ],
          if (profile.isStorageDemo &&
              uploadState is ViewStateEmpty<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            _Notice(message: uploadState.message),
          ],
          if (profile.isStorageDemo &&
              uploadState is ViewStateError<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            _Notice(message: uploadState.message, isError: true),
          ],
          if (profile.isStorageDemo &&
              uploadState is ViewStateSuccess<String>) ...[
            const SizedBox(height: AppSpacing.s16),
            const _Notice(message: 'Đã tải PDF lên Storage Emulator.'),
            const SizedBox(height: AppSpacing.s8),
            Semantics(
              container: true,
              child: SelectableText(
                uploadState.data,
                style: AppTypography.supporting,
              ),
            ),
          ],
          if (profile.canRetryUpload) ...[
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              key: const Key('profile-retry'),
              text: 'Thử tải lên lại',
              variant: AppButtonVariant.secondary,
              icon: AppIcons.refresh,
              onPressed: profile.retryUpload,
            ),
          ],
          if (profile.lastExport != null) ...[
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              key: const Key('profile-open'),
              text: 'Mở PDF đã lưu',
              variant: AppButtonVariant.secondary,
              onPressed: () => _open(context, profile.previewLastExport),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              key: const Key('profile-share'),
              text: 'Chia sẻ PDF đã lưu',
              variant: AppButtonVariant.secondary,
              onPressed: () => _open(context, profile.shareLastExport),
            ),
          ],
        ],
      ),
    );
  }
}

/// Information about the export, never a claim that Firestore stores the PDF.
/// State changes create one live-region announcement, not a changing counter.
class _ReportMetadataStatus extends StatelessWidget {
  const _ReportMetadataStatus();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final state = profile.metadataState;
    if (state == ReportMetadataState.idle) return const SizedBox.shrink();
    final message = switch (state) {
      ReportMetadataState.saving => 'Đang đồng bộ thông tin báo cáo…',
      ReportMetadataState.pending =>
        'Thông tin báo cáo đang chờ đồng bộ. Bạn vẫn có thể mở và chia sẻ PDF.',
      ReportMetadataState.confirmed => 'Đã đồng bộ thông tin báo cáo.',
      ReportMetadataState.error =>
        'Chưa đồng bộ được thông tin báo cáo. PDF vẫn có trên máy.',
      ReportMetadataState.idle => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s8),
        _Notice(message: message, isError: state == ReportMetadataState.error),
        if (profile.canRetryMetadata) ...[
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            key: const Key('profile-retry-metadata'),
            text: 'Thử đồng bộ lại',
            variant: AppButtonVariant.secondary,
            icon: AppIcons.refresh,
            onPressed: profile.retryMetadata,
          ),
        ],
      ],
    );
  }
}

class _ExportProgress extends StatelessWidget {
  final String message;
  final double progress;

  const _ExportProgress({required this.message, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    // A live region speaks again whenever its label changes, so the
    // percentage is the value: TalkBack announces each phase once and reads
    // the current percentage when focused.
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      value: '$percent%',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$message $percent%', style: AppTypography.supporting),
            const SizedBox(height: AppSpacing.s8),
            LinearProgressIndicator(
              value: progress,
              color: AppColors.actionPrimary,
              backgroundColor: AppColors.bgSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final items = profile.inbox;
    final permissionNotice = switch (profile.notificationPermission) {
      NotificationPermission.denied =>
        'Thông báo đang tắt. Bật lại trong Cài đặt của Android để nhận tin.',
      NotificationPermission.failed => 'Chưa kết nối được dịch vụ thông báo.',
      _ => null,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Thông báo',
            description:
                'Tin nhắn đã nhận, lưu trên máy này theo từng tài '
                'khoản.',
          ),
          if (permissionNotice != null) ...[
            const SizedBox(height: AppSpacing.s16),
            _Notice(message: permissionNotice, isError: true),
          ],
          const SizedBox(height: AppSpacing.s16),
          if (items.isEmpty)
            Semantics(
              container: true,
              child: Text(
                'Chưa có thông báo nào.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.s16),
            _InboxItem(item: item),
          ],
        ],
      ),
    );
  }
}

class _InboxItem extends StatelessWidget {
  final AppNotification item;

  const _InboxItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final body = item.body;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title ?? 'Thông báo', style: AppTypography.labelStrong),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(body, style: AppTypography.supporting),
          ],
          if (item.targetIssue != NotificationTargetIssue.none) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Không mở được nội dung liên quan của tin này.',
              style: AppTypography.supporting.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoteConfigCard extends StatelessWidget {
  const _RemoteConfigCard();

  Future<void> _refresh(BuildContext context, ProfileViewModel profile) async {
    final applied = await profile.refreshRemoteConfig();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: applied ? 'Đã áp dụng giá trị mới.' : 'Không có giá trị mới hoặc chưa tải được. Vẫn dùng giá trị hiện có.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Remote Config',
            description: 'Giá trị đang áp dụng trong ứng dụng.',
          ),
          const SizedBox(height: AppSpacing.s16),
          _ConfigRow(
            label: 'Số món gợi ý tối đa',
            value: '${profile.maxRecommendations}',
          ),
          _ConfigRow(
            label: 'Điểm trường thọ',
            value: profile.enableScore ? 'Bật' : 'Tắt',
          ),
          _ConfigRow(
            label: 'Banner',
            value: profile.bannerText.isEmpty ? 'Trống' : profile.bannerText,
          ),
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            key: const Key('profile-refresh-config'),
            text: 'Cập nhật Remote Config',
            loadingText: 'Đang cập nhật…',
            variant: AppButtonVariant.secondary,
            isLoading: profile.isRefreshingConfig,
            onPressed: () => _refresh(context, profile),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.supporting.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(value, style: AppTypography.labelStrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrashlyticsCard extends StatelessWidget {
  const _CrashlyticsCard();

  Future<void> _confirmCrash(BuildContext context) async {
    final profile = context.read<ProfileViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: AppDialog.barrierLabel,
      builder: (dialogContext) => AppDialog.error(
        title: 'Gây crash thử?',
        message:
            'Ứng dụng sẽ đóng ngay để gửi báo cáo lên Crashlytics. '
            'Chỉ dùng để kiểm thử.',
        primaryLabel: 'Gây crash',
        onPrimary: () => Navigator.of(dialogContext).pop(true),
        secondaryLabel: 'Hủy',
        onSecondary: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) profile.testCrashlytics();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Crashlytics',
            description: 'Gây một lỗi thử để kiểm tra báo cáo trên Console.',
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            key: const Key('profile-test-crash'),
            text: 'Gây crash thử',
            variant: AppButtonVariant.destructive,
            onPressed: () => _confirmCrash(context),
          ),
        ],
      ),
    );
  }
}
