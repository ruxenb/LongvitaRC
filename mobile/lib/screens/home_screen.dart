import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/models/announcement_model.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/services/i_data_service.dart';
import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita_core/widgets/app_button.dart';
import 'package:longvita_core/widgets/app_card.dart';
import 'package:longvita_core/widgets/app_navigation_bar.dart';
import 'package:longvita_core/widgets/state_views.dart';
import 'package:longvita/screens/meal_flow_screens.dart';
import 'package:longvita/screens/profile_screen.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';
import 'package:longvita/screens/shopping_flow_screens.dart';

/// S01: Firebase-backed entry point for all three business flows.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<AnnouncementModel>> _announcements;

  @override
  void initState() {
    super.initState();
    _announcements = context
        .read<IDataService>()
        .streamAnnouncements()
        .asBroadcastStream();
  }

  void _refreshAnnouncements() => setState(
    () => _announcements = context
        .read<IDataService>()
        .streamAnnouncements()
        .asBroadcastStream(),
  );

  void _navigateTo(int index) {
    final widget = switch (index) {
      1 => const SavedPlansScreen(),
      2 => const RecipeCatalogScreen(),
      _ => null,
    };
    if (index == 3) {
      Navigator.of(context).pushNamed(ProfileScreen.routeName);
    } else if (widget != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
    }
  }

  Future<void> _signOut() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất Longvita?'),
        content: const Text('Bạn sẽ rời khỏi phiên làm việc hiện tại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    await context.read<AuthViewModel>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final profile = context.watch<ProfileViewModel>();
    final plan = context.watch<MealPlanViewModel>().activePlan;
    RecipeModel? todayMeal;
    final todayIndex = DateTime.now().weekday - DateTime.monday;
    if (plan != null) {
      for (final day in plan.days) {
        if (day.dayIndex == todayIndex && day.meals.isNotEmpty) {
          todayMeal = day.meals.first;
          break;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Longvita'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            child: Center(
              child: Text(
                user?.displayName.split(' ').first ?? 'Minh Anh',
                style: AppTypography.label,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hồ sơ',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _navigateTo(3),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _signOut,
          ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: _navigateTo,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pageMargin),
              children: [
                Text(
                  'Xin chào, ${user?.displayName.split(' ').first ?? 'bạn'}',
                  style: AppTypography.headingM,
                ),
                const SizedBox(height: AppSpacing.s16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nhịp sống 7 ngày của bạn',
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      const Text(
                        'Theo dõi bữa ăn, công thức và mua sắm tại một nơi.',
                        style: AppTypography.supporting,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: const BoxDecoration(
                          color: AppColors.bgSelected,
                          borderRadius: AppRadius.rounded12,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.actionPrimary,
                            ),
                            SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                'Sẵn sàng cho một tuần mới',
                                style: AppTypography.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AppButton(
                  text: 'Tạo thực đơn tuần',
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PreferencesScreen(),
                    ),
                  ),
                ),
                if (profile.bannerText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(profile.bannerText)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s24),
                const Text('Hôm nay', style: AppTypography.title),
                const SizedBox(height: AppSpacing.s8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (todayMeal == null)
                        const Text(
                          'Chưa có thực đơn. Hãy tạo thực đơn tuần để xem món hôm nay.',
                          style: AppTypography.supporting,
                        )
                      else
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 34,
                              backgroundColor: AppColors.bgSelected,
                              child: Icon(
                                Icons.soup_kitchen_outlined,
                                color: AppColors.actionPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayMeal.name,
                                    style: AppTypography.labelStrong,
                                  ),
                                  if (todayMeal.sourceNote.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.s4),
                                    Text(
                                      todayMeal.sourceNote,
                                      style: AppTypography.supporting,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.s12),
                      if (todayMeal?.isBookCitation == true)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Từ sách', style: AppTypography.label),
                            Text('Đang chờ', style: AppTypography.supporting),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.s16),
                      AppButton(
                        text: 'Thực đơn đã lưu',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _navigateTo(1),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      AppButton(
                        text: 'Danh sách mua sắm',
                        variant: AppButtonVariant.secondary,
                        onPressed: plan == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const IngredientSummaryScreen(),
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      AppButton(
                        text: 'Xuất báo cáo PDF ở Hồ sơ',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _navigateTo(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Hộp thư thông báo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<AnnouncementModel>>(
                  stream: _announcements,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorView(
                        title: 'Không tải được thông báo',
                        message: 'Kiểm tra kết nối và thử lại.',
                        onRetry: _refreshAnnouncements,
                        retryLabel: 'Thử lại',
                      );
                    }
                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView(
                        title: 'Đang tải thông báo',
                        message: 'Đang đồng bộ hộp thư...',
                      );
                    }
                    final list = snapshot.data ?? const <AnnouncementModel>[];
                    if (list.isEmpty) {
                      return const EmptyView(
                        title: 'Chưa có thông báo',
                        message: 'Hiện chưa có tin mới từ ban quản trị.',
                      );
                    }
                    return Column(
                      children: [
                        for (final announcement in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    announcement.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(announcement.content),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vai trò: ${_roleLabel(announcement.authorRole)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'admin' => 'Quản trị viên',
    'staff' => 'Nhân viên',
    _ => 'Người dùng',
  };
}
