import 'package:flutter/material.dart';

/// Spacing scale from Figma Foundations "03 Spacing": 4 · 8 · 12 · 16 · 24 · 32 · 48.
/// Page margin 16 · card padding 16–24 · icon 24.
class AppSpacing {
  AppSpacing._();

  static const double s0 = 0.0;
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  /// Horizontal page margin.
  static const double pageMargin = s16;

  // Short names kept from the skeleton.
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;
  static const double xxl = s48;

  /// Minimum interactive target (Figma `size/touch-min`).
  static const double minTouchTarget = AppSizes.touchMin;
}

/// Fixed component sizes bound as Figma variables.
class AppSizes {
  AppSizes._();

  /// `size/touch-min`
  static const double touchMin = 48.0;

  /// `size/button-height` — minimum; a button with a 24px icon renders 56.
  static const double buttonMinHeight = 52.0;

  /// `size/nav-height`
  static const double navHeight = 80.0;

  /// `Longvita/AppBar` min height.
  static const double appBarHeight = 64.0;

  /// Material Icons Round visual size.
  static const double icon = 24.0;

  /// Meal photo in `Longvita/Card` Kind=Meal.
  static const double mealPhoto = 80.0;
}

/// Corner radius from Foundations "04 Corner radius": 4 / 8 / 12 / 16 / full.
/// Control 8–12, card 12, dialog 16; full only for chips/segmented selection.
class AppRadius {
  AppRadius._();

  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double rFull = 9999.0;

  static const BorderRadius rounded4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius rounded8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius rounded12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius rounded16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(rFull),
  );
}

/// Elevation from Foundations "05 Elevation": 0 = flat · 1 = card/button · 2 = dialog.
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> level0 = [];

  /// `Longvita/Elevation/1`: drop shadow #2F3B2A14, y 1, blur 3.
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x142F3B2A), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// `Longvita/Elevation/2`: drop shadow #2F3B2A1F, y 4, blur 16.
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x1F2F3B2A), offset: Offset(0, 4), blurRadius: 16),
  ];
}
