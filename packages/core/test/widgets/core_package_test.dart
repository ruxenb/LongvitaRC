import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/longvita_core.dart';

void main() {
  testWidgets('Core widgets work without importing either client', (
    tester,
  ) async {
    var presses = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(text: 'Tiếp tục', onPressed: () => presses++),
          ),
        ),
      );
      await tester.tap(find.text('Tiếp tục'));
      expect(presses, 1);
      expect(tester.getSize(find.byType(AppButton)).height, 52);
      expect(
        tester.getSemantics(find.byType(AppButton)),
        matchesSemantics(
          label: 'Tiếp tục',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });
}
