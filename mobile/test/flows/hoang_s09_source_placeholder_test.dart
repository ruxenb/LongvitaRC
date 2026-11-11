import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';

void main() {
  testWidgets('S09 is Vietnamese and never invents a book citation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: BookKnowledgeScreen()));
    await tester.pump();

    expect(find.text('Kiến thức sách'), findsOneWidget);
    expect(find.text('Nguồn tham khảo'), findsOneWidget);
    expect(
      find.text('Chưa có nguồn trích dẫn được xác minh cho nội dung này.'),
      findsOneWidget,
    );
    expect(find.text('Book knowledge'), findsNothing);
    expect(find.text('Source'), findsNothing);
    expect(find.textContaining('Phụ lục A'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
