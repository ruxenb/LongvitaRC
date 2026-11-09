import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `Longvita/Badge` kinds (Figma 56:35).
enum AppBadgeKind { fromBook, appSuggestion, logged, pending, plantRich }

/// `Longvita/Badge` (Figma 56:35): pill, padding 8, gap 4, 24px icon +
/// Label. Every kind pairs its colour with an icon and text, so meaning never
/// relies on colour alone. [label] overrides the Figma default text.
class AppBadge extends StatelessWidget {
  final AppBadgeKind kind;
  final String? label;

  const AppBadge({super.key, required this.kind, this.label});

  static String defaultLabel(AppBadgeKind kind) => switch (kind) {
    AppBadgeKind.fromBook => 'Từ sách',
    AppBadgeKind.appSuggestion => 'Ứng dụng gợi ý',
    AppBadgeKind.logged => 'Đã ghi nhận',
    AppBadgeKind.pending => 'Đang chờ',
    AppBadgeKind.plantRich => 'Giàu thực vật',
  };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color background, Color foreground) = switch (kind) {
      AppBadgeKind.fromBook => (
        AppIcons.menuBook,
        AppColors.bgSelected,
        AppColors.actionPrimary,
      ),
      AppBadgeKind.appSuggestion => (
        AppIcons.eco,
        AppColors.bgSoft,
        AppColors.actionPrimary,
      ),
      AppBadgeKind.logged => (
        AppIcons.check,
        AppColors.bgSelected,
        AppColors.actionPrimary,
      ),
      AppBadgeKind.pending => (
        AppIcons.infoOutline,
        AppColors.bgCanvas,
        AppColors.textSecondary,
      ),
      AppBadgeKind.plantRich => (
        AppIcons.spa,
        AppColors.bgSelected,
        AppColors.actionPrimary,
      ),
    };
    final text = label ?? defaultLabel(kind);

    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.roundedFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.icon, color: foreground),
              const SizedBox(width: AppSpacing.s4),
              Flexible(
                child: Text(
                  text,
                  style: AppTypography.label.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
