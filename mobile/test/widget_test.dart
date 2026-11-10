import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/widgets/app_button.dart';
import 'package:longvita_core/theme/app_theme.dart';

void main() {
  testWidgets('AppButton renders properly with Design System theme', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(
            text: 'Bắt đầu ngay',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Bắt đầu ngay'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu ngay'));
    expect(tapped, isTrue);
  });
}
