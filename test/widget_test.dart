import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/main.dart';

void main() {
  testWidgets('App barebone smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LongvitaApp());
    expect(find.text('Longvita - Barebone Ready'), findsOneWidget);
  });
}
