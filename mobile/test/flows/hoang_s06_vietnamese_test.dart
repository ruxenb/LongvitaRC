import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita_core/theme/app_theme.dart';

import '../auth/auth_fakes.dart';
import '../qa/qa_support.dart';
import 'hoang_viewmodels_test.dart' show MemoryData, beans, vegetables;

void main() {
  setUpAll(loadQaFonts);

  testWidgets(
    'S06: titles, explanation and original recipe are in Vietnamese',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = MemoryData()..recipes = [beans, vegetables];
      final vm = MealPlanViewModel(
        dataService: data,
        analytics: FakeAnalytics(),
        crashlytics: FakeCrashlytics(),
        remoteConfig: FakeRemoteConfig(),
      );
      addTearDown(() {
        vm.dispose();
        data.planEvents.close();
      });
      vm.onSessionStarted(testUser('uid-1'));

      await tester.pumpWidget(
        ChangeNotifierProvider<MealPlanViewModel>.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MealAlternativesScreen(original: beans, dayIndex: 0),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Món thay thế'), findsOneWidget);
      expect(find.text('Chọn món thay thế'), findsOneWidget);
      expect(
        find.text('Món hiện tại chỉ thay đổi sau khi bạn xác nhận.'),
        findsOneWidget,
      );
      expect(find.text('Món hiện tại: Súp đậu'), findsOneWidget);

      expect(find.text('Meal alternatives'), findsNothing);
      expect(find.text('Choose a replacement'), findsNothing);
      expect(find.text('Original: Súp đậu'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
