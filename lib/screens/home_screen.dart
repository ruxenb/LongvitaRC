import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement_model.dart';
import '../services/i_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/state_views.dart';
import 'meal_flow_screens.dart';
import 'profile_screen.dart';
import 'recipe_flow_screens.dart';

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
    _announcements = context.read<IDataService>().streamAnnouncements();
  }

  void _refreshAnnouncements() => setState(
    () => _announcements = context.read<IDataService>().streamAnnouncements(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Longvita Dashboard'),
        actions: [
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
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.bgSelected,
                        backgroundImage: user?.photoUrl == null
                            ? null
                            : NetworkImage(user!.photoUrl!),
                        child: user?.photoUrl == null
                            ? const Icon(Icons.person, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Người dùng Longvita',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              user?.email ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ROLE: ${user?.role.toUpperCase() ?? 'USER'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Hành Động Nhanh',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Lập thực đơn 7 ngày từ dữ liệu thật',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập sở thích và xem gợi ý từ Firestore. '
                        'Không tạo món mẫu hoặc tự điền tuổi/cân nặng.',
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Tạo thực đơn',
                        icon: Icons.restaurant_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PreferencesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Kế hoạch đã lưu',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _navigateTo(1),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Tra cứu công thức',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _navigateTo(2),
                      ),
                      const SizedBox(height: 12),
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
                                  Text('Vai trò: ${announcement.authorRole}'),
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
}
