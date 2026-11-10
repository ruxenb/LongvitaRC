import 'package:flutter/material.dart';

import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_icons.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';

/// One destination of [AppNavigationBar].
class AppNavigationDestination {
  final IconData icon;
  final String label;

  const AppNavigationDestination({required this.icon, required this.label});
}

/// `Longvita/Navigation` (Figma 56:174) built from `Longvita/NavigationItem`
/// (56:89): canvas bar, min height 80, padding 8; equal-width pill items
/// (min 48, padding 4, gap 4). The selected item is action/primary with
/// on-primary icon and label; others are text/secondary.
///
/// Routing stays with the caller: pass [selectedIndex] and handle
/// [onDestinationSelected].
class AppNavigationBar extends StatelessWidget {
  /// Legacy English Figma labels for callers not yet migrated.
  /// New Vietnamese flows use [vietnameseDestinations].
  static const List<AppNavigationDestination> longvitaDestinations = [
    AppNavigationDestination(icon: AppIcons.home, label: 'Trang chủ'),
    AppNavigationDestination(icon: AppIcons.calendarToday, label: 'Thực đơn'),
    AppNavigationDestination(icon: AppIcons.spa, label: 'Dinh dưỡng'),
    AppNavigationDestination(icon: AppIcons.accountCircle, label: 'Hồ sơ'),
  ];

  /// Vietnamese labels agreed by the team on 09/11/2026. Flows opt in
  /// during migration so labels and their navigation tests change together.
  static const List<AppNavigationDestination> vietnameseDestinations = [
    AppNavigationDestination(icon: AppIcons.home, label: 'Trang chủ'),
    AppNavigationDestination(icon: AppIcons.calendarToday, label: 'Kế hoạch'),
    AppNavigationDestination(icon: AppIcons.spa, label: 'Dinh dưỡng'),
    AppNavigationDestination(icon: AppIcons.accountCircle, label: 'Hồ sơ'),
  ];

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<AppNavigationDestination> destinations;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.destinations = longvitaDestinations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCanvas,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.navHeight),
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavigationItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: onDestinationSelected == null
                        ? null
                        : () => onDestinationSelected!(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback? onTap;

  const _NavigationItem({
    required this.destination,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.actionOnPrimary
        : AppColors.textSecondary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: selected ? AppColors.actionPrimary : Colors.transparent,
              borderRadius: AppRadius.roundedFull,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: AppSizes.icon, color: foreground),
                const SizedBox(height: AppSpacing.s4),
                // Large text scales shrink the label to its quarter of the bar
                // instead of letting neighbouring labels overlap.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.label.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
