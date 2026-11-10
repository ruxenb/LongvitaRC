import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:longvita_core/theme/app_colors.dart';

/// Text styles from Figma Foundations "02 Typography" (node 53:45).
///
/// Fraunces = brand · Newsreader = headings · Quicksand = body and actions.
/// Fonts are bundled from google/fonts (SIL OFL 1.1) as variable fonts, so
/// each style sets its `wght` axis explicitly; Newsreader/Fraunces also set
/// `opsz` to the font size, matching Figma's automatic optical size.
/// Fraunces Brand uses `SOFT 0, WONK 1` exactly as the Figma style does.
class AppTypography {
  AppTypography._();

  static const String fraunces = 'packages/longvita_core/Fraunces';
  static const String newsreader = 'packages/longvita_core/Newsreader';
  static const String quicksand = 'packages/longvita_core/Quicksand';

  /// Adds the bundled fonts' SIL OFL 1.1 texts to the app's licence page,
  /// as the licence requires when the fonts are redistributed.
  static void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final family in const ['Quicksand', 'Newsreader', 'Fraunces']) {
        final text = await rootBundle.loadString(
          'packages/longvita_core/assets/fonts/$family-OFL.txt',
        );
        yield LicenseEntryWithLineBreaks([family], text);
      }
    });
  }

  /// Longvita/Brand — Fraunces Bold 20/28.
  static const TextStyle brand = TextStyle(
    fontFamily: fraunces,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [
      FontVariation('wght', 700),
      FontVariation('opsz', 20),
      FontVariation('SOFT', 0),
      FontVariation('WONK', 1),
    ],
  );

  /// Longvita/Heading/L — Newsreader Bold 28/36.
  static const TextStyle headingL = TextStyle(
    fontFamily: newsreader,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 28)],
  );

  /// Longvita/Heading/M — Newsreader SemiBold 24/32.
  static const TextStyle headingM = TextStyle(
    fontFamily: newsreader,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 24)],
  );

  /// Longvita/Title — Newsreader SemiBold 20/28.
  static const TextStyle title = TextStyle(
    fontFamily: newsreader,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 20)],
  );

  /// Longvita/Body — Quicksand Regular 16/26.
  static const TextStyle body = TextStyle(
    fontFamily: quicksand,
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 400)],
  );

  /// Longvita/Supporting — Quicksand Medium 14/22.
  static const TextStyle supporting = TextStyle(
    fontFamily: quicksand,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    fontVariations: [FontVariation('wght', 500)],
  );

  /// Longvita/Label — Quicksand SemiBold 14/20.
  static const TextStyle label = TextStyle(
    fontFamily: quicksand,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 600)],
  );

  /// Longvita/Label/Strong — Quicksand Bold 14/20.
  static const TextStyle labelStrong = TextStyle(
    fontFamily: quicksand,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontVariations: [FontVariation('wght', 700)],
  );

  /// Material [TextTheme] slots mapped onto the eight Figma styles. Prefer the
  /// named styles above in Longvita widgets; this mapping keeps plain Material
  /// widgets (and existing screens) on approved fonts.
  static const TextTheme textTheme = TextTheme(
    displayLarge: headingL,
    displayMedium: headingL,
    displaySmall: headingL,
    headlineLarge: headingL,
    headlineMedium: headingL,
    headlineSmall: headingM,
    titleLarge: title,
    titleMedium: labelStrong,
    titleSmall: label,
    bodyLarge: body,
    bodyMedium: supporting,
    bodySmall: supporting,
    labelLarge: labelStrong,
    labelMedium: label,
    labelSmall: label,
  );
}
