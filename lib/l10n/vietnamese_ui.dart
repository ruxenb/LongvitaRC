import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Team language decision, 09/11/2026: Vietnamese UI. Apply to completed
/// flows while other owners migrate their screens. This also translates
/// Flutter's built-in text-selection controls; it does not translate data.
class VietnameseUi extends StatelessWidget {
  final Widget child;
  const VietnameseUi({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('vi'),
    delegates: GlobalMaterialLocalizations.delegates,
    child: child,
  );
}
