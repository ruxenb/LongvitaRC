import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Minimum Touch Target according to WCAG & ARTEMIS
  static const double minTouchTarget = 48.0;
}

class AppRadius {
  AppRadius._();

  // D08 Decisions: radius 4 / 8 / 12 / 16 / full
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double rFull = 999.0;

  static const BorderRadius rounded4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius rounded8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius rounded12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius rounded16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(rFull));
}
