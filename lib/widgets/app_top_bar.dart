import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon_button.dart';

/// `Longvita/AppBar` (Figma 56:191): canvas bar, min height 64, padding 8,
/// gap 8. Back icon button (action/primary), Brand title (Fraunces,
/// action/primary) and optional [actions] (mode WithActions).
///
/// Use as `Scaffold.appBar`. The back button appears only when [onBack] is
/// given, so Back behaviour stays with the router.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final String backSemanticLabel;
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    this.title = 'Longvita',
    this.onBack,
    this.backSemanticLabel = 'Back',
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCanvas,
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.appBarHeight),
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Row(
            children: [
              if (onBack != null) ...[
                AppIconButton(
                  icon: AppIcons.arrowBack,
                  semanticLabel: backSemanticLabel,
                  onPressed: onBack,
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.brand
                        .copyWith(color: AppColors.actionPrimary),
                  ),
                ),
              ),
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.s8),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
