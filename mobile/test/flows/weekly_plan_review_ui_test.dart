import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:longvita/screens/meal_flow_screens.dart';
import 'package:longvita_core/theme/app_theme.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../qa/qa_support.dart';
import 'hoang_viewmodels_test.dart' show MemoryData, fixturePlan;

void main() {
  setUpAll(loadQaFonts);

  late MemoryData data;
  late MealPlanViewModel vm;

  setUp(() {
    data = MemoryData();
    vm = MealPlanViewModel(
      dataService: data,
      analytics: FakeAnalytics(),
      crashlytics: FakeCrashlytics(),
      remoteConfig: FakeRemoteConfig(),
    );
    vm.onSessionStarted(testUser('uid-1'));
    final draft = fixturePlan(id: 'review-ui');
    data.plans[draft.id] = draft;
    vm.selectSavedPlan(draft);
  });

  tearDown(() {
    vm.dispose();
    data.planEvents.close();
  });

  Widget app() => ChangeNotifierProvider<MealPlanViewModel>.value(
    value: vm,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const WeeklyPlanScreen(),
    ),
  );

  testWidgets('S04: điều hướng 7 ngày với các nút chọn ngày từ Figma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byKey(const Key('weekly-day-0')), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(-400, 0));
    await tester.pump();
    expect(find.byKey(const Key('weekly-day-6')), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(400, 0));
    await tester.pump();
    expect(find.text('Chọn ngày trong tuần'), findsOneWidget);
    expect(find.byKey(const Key('submit-plan-review')), findsNothing);

    await tester.tap(find.byKey(const Key('weekly-day-0')));
    await tester.pump();
    expect(find.textContaining('Bữa 1: Súp đậu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S04: thực đơn nháp không hiển thị nút gửi chuyên gia', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pump();

    expect(vm.activePlan?.status, 'draft');
    expect(find.byKey(const Key('submit-plan-review')), findsNothing);
    expect(find.text('Gửi chuyên gia xét duyệt'), findsNothing);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(find.text('Xem nguyên liệu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
