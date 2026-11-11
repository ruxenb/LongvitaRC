import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita_core/models/ingredient_model.dart';
import 'package:longvita_core/models/meal_plan_model.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/theme/app_theme.dart';
import 'package:longvita/screens/meal_flow_screens.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

import '../auth/auth_fakes.dart';
import '../qa/qa_support.dart';
import 'hoang_viewmodels_test.dart' show MemoryData;

const longSource =
    '[web] Thành phần bữa ăn mẫu của Quỹ Valter Longo; '
    'ghi chú nghiên cứu chi tiết và đường dẫn nguồn được giữ trong '
    'màn Chi tiết công thức, không nhồi đầy trên thẻ thực đơn.';

const longRecipe = RecipeModel(
  id: 'native-qa-long-recipe',
  name:
      'Farro (spelt) với rau diếp xoăn, cà rốt và '
      'Grana Padano — tên món rất dài để kiểm tra xuống dòng',
  description: 'Công thức thử giao diện, không ghi vào Firestore.',
  category: 'rau_cu',
  proteinGrams: 13,
  calories: 375,
  sourceNote: longSource,
  ingredients: [
    IngredientModel(
      id: 'ingredient-long',
      name: 'Rau diếp xoăn (cicoria, phần lá) loại có tên rất dài để kiểm tra 200%',
      amount: 150,
      unit: 'g',
    ),
  ],
  instructions: ['Rửa rau sạch.'],
);

Widget scaledApp(Widget home) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: home,
);

void main() {
  setUpAll(loadQaFonts);

  testWidgets(
    'HD-02 S04: tên món dài không chồng nhãn chờ giả, nguồn giới hạn hai dòng',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = MemoryData();
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
      final plan = MealPlanModel(
        id: 'long-card',
        uid: 'uid-1',
        title: 'Kiểm tra thẻ món',
        targetCalories: 1800,
        targetProteinGrams: 55,
        createdAt: DateTime(2026, 11, 11),
        days: List.generate(
          7,
          (index) => DailyMeal(
            dayIndex: index,
            dayName: 'Ngày kiểm tra',
            meals: const [longRecipe, longRecipe],
          ),
        ),
      );
      data.plans[plan.id] = plan;
      vm.selectSavedPlan(plan);
      await tester.pumpWidget(
        ChangeNotifierProvider<MealPlanViewModel>.value(
          value: vm,
          child: scaledApp(const WeeklyPlanScreen()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Bữa 2:'), findsOneWidget);
      expect(find.text('375 kcal • 13.0 g đạm'), findsNWidgets(2));
      expect(find.text('Đang chờ'), findsNothing);
      final source = tester.widget<Text>(find.text(longSource).first);
      expect(source.maxLines, 2);
      expect(source.overflow, TextOverflow.ellipsis);
      await tester.ensureVisible(find.textContaining('Bữa 2:'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HD-02 S05: nhãn tiếng Việt và tên nguyên liệu dài không tràn ở 200%',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Provider<AnalyticsService>.value(
          value: FakeAnalytics(),
          child: scaledApp(const RecipeDetailsScreen(recipe: longRecipe)),
        ),
      );
      await tester.pump();
      expect(find.text('Nguồn tham khảo'), findsOneWidget);
      expect(find.text(longSource), findsOneWidget);
      expect(find.text('Nguyên liệu'), findsOneWidget);
      expect(find.text('Các bước thực hiện'), findsOneWidget);
      expect(find.text('Ingredients'), findsNothing);
      expect(find.text('Steps'), findsNothing);
      expect(find.textContaining('g đạm · 1 khẩu phần'), findsOneWidget);
      await tester.ensureVisible(find.text('Các bước thực hiện'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
