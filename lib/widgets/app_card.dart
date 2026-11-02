import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Base surface of `Longvita/Card` (Figma 56:80): white, radius 12,
/// padding 16, Elevation/1. With [onTap] it shows the Pressed fill
/// (bg/pressed) while touched.
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final String? semanticLabel;

  /// Renders the Pressed variant without a pointer; for QA hosts only.
  @visibleForTesting
  final bool debugForcePressed;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.backgroundColor,
    this.semanticLabel,
    this.debugForcePressed = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final pressed = tappable && (_pressed || widget.debugForcePressed);

    final surface = Container(
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: pressed
            ? AppColors.bgPressed
            : (widget.backgroundColor ?? AppColors.bgSurface),
        borderRadius: AppRadius.rounded12,
        boxShadow: AppElevation.level1,
      ),
      child: widget.child,
    );

    if (!tappable) {
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        child: surface,
      );
    }

    return Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: surface,
      ),
    );
  }
}

/// `Longvita/Card` Kind=Meal: 80px photo (radius 16, cover crop), title
/// (Label/Strong) and description (Supporting), then a source badge and a
/// status row (info icon + Supporting).
///
/// [image] comes from recipe data; pass null to hide the photo.
class AppMealCard extends StatelessWidget {
  final String title;
  final String description;
  final ImageProvider? image;
  final Widget? sourceBadge;
  final String? status;
  final IconData statusIcon;
  final VoidCallback? onTap;

  @visibleForTesting
  final bool debugForcePressed;

  const AppMealCard({
    super.key,
    required this.title,
    required this.description,
    this.image,
    this.sourceBadge,
    this.status,
    this.statusIcon = AppIcons.infoOutline,
    this.onTap,
    this.debugForcePressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      debugForcePressed: debugForcePressed,
      semanticLabel: [title, description, if (status != null) status].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: AppRadius.rounded16,
                  child: Image(
                    image: image!,
                    width: AppSizes.mealPhoto,
                    height: AppSizes.mealPhoto,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.labelStrong),
                      const SizedBox(height: AppSpacing.s4),
                      Text(description, style: AppTypography.supporting),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (sourceBadge != null || status != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sourceBadge != null) Flexible(child: sourceBadge!),
                if (status != null)
                  ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 100),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: AppSizes.icon,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(status!, style: AppTypography.supporting),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `Longvita/Card` Kind=Summary: Title, Body (text/secondary) and a
/// bg/selected note row (radius 16, padding 12) with an action/primary icon
/// and Label text.
class AppSummaryCard extends StatelessWidget {
  final String title;
  final String description;
  final String? note;
  final IconData noteIcon;
  final VoidCallback? onTap;

  @visibleForTesting
  final bool debugForcePressed;

  const AppSummaryCard({
    super.key,
    required this.title,
    required this.description,
    this.note,
    this.noteIcon = AppIcons.calendarToday,
    this.onTap,
    this.debugForcePressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      debugForcePressed: debugForcePressed,
      semanticLabel: [title, description, if (note != null) note].join(', '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.title),
            const SizedBox(height: AppSpacing.s12),
            Text(
              description,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: const BoxDecoration(
                  color: AppColors.bgSelected,
                  borderRadius: AppRadius.rounded16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(noteIcon,
                        size: AppSizes.icon, color: AppColors.actionPrimary),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        note!,
                        style: AppTypography.label
                            .copyWith(color: AppColors.actionPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
