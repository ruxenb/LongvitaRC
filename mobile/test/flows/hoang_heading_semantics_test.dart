import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita/screens/flow_ui.dart';

void main() {
  testWidgets('Hoang flow screen and section expose Android heading levels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: FlowFrame(
          title: 'S02 • Sở thích ăn uống',
          child: FlowSection(
            title: 'Thông tin để lập thực đơn',
            child: Text('Nội dung'),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('S02 • Sở thích ăn uống')).headingLevel,
      1,
    );
    expect(
      tester.getSemantics(find.text('Thông tin để lập thực đơn')).headingLevel,
      2,
    );
    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        // Flutter's route wrapper has an empty, unlevelled namesRoute node.
        return data.flagsCollection.isHeader &&
            data.headingLevel == 0 &&
            data.label.isNotEmpty;
      }),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('loading copy uses a single ellipsis for TalkBack', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlowFrame(
          title: 'Trạng thái',
          child: FlowStateView<int>(
            state: const ViewStateLoading<int>(),
            onData: (_) => const Text('Xong'),
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(find.text('Vui lòng chờ dữ liệu…'), findsOneWidget);
    expect(find.textContaining('...'), findsNothing);
  });
}
