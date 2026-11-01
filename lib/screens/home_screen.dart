import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/announcement_model.dart';
import '../models/view_state.dart';
import '../services/i_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final profileViewModel = context.watch<ProfileViewModel>();
    final mealPlanViewModel = context.watch<MealPlanViewModel>();
    final dataService = context.read<IDataService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Longvita Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => authViewModel.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header & Role Badge
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Người dùng Longvita',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.outline,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Role Badge (user | staff | admin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user?.isAdmin == true
                                ? AppColors.error.withAlpha(30)
                                : AppColors.primaryContainer,
                            borderRadius: AppRadius.roundedFull,
                          ),
                          child: Text(
                            'ROLE: ${user?.role.toUpperCase() ?? 'USER'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: user?.isAdmin == true
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Remote Config Announcement Banner
            if (profileViewModel.bannerText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withAlpha(120),
                  borderRadius: AppRadius.rounded12,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded,
                        color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        profileViewModel.bannerText,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Quick Actions: Tạo thực đơn 7 ngày
            Text(
              'Hành Động Nhanh',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sinh thực đơn 7 ngày khoa học',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dựa theo trọng lượng và tuổi theo khuyến nghị của TS. Valter Longo.',
                    style: TextStyle(fontSize: 13, color: AppColors.outline),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Tạo thực đơn mẫu ngay',
                    icon: Icons.auto_awesome_rounded,
                    isLoading:
                        mealPlanViewModel.currentPlanState is ViewStateLoading,
                    onPressed: () async {
                      if (user != null) {
                        await mealPlanViewModel.generatePlan(
                          uid: user.uid,
                          weightKg: 62.0,
                          age: 24,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã tạo thực đơn 7 ngày thành công!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  if (mealPlanViewModel.activePlan != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await mealPlanViewModel.saveActivePlan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(saved
                                  ? 'Đã lưu thực đơn vào Firestore!'
                                  : 'Lỗi lưu thực đơn.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Lưu vào Firestore (meal_plans)'),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await profileViewModel.exportAndUploadPdf(
                            mealPlanViewModel.activePlan!);
                        if (context.mounted &&
                            profileViewModel.lastUploadedUrl != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xuất PDF và tải lên Storage thành công!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Xuất báo cáo PDF & Upload Storage'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Real-time Announcements Inbox (Sẵn sàng cho Web Admin post lên)
            Text(
              'Hộp Thư Thông Báo (Real-time Inbox)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<List<AnnouncementModel>>(
              stream: dataService.streamAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        'Chưa có thông báo mới từ ban quản trị.',
                        style: TextStyle(color: AppColors.outline),
                      ),
                    ),
                  );
                }
                return Column(
                  children: list.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '[${a.authorRole.toUpperCase()}]',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.content,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
