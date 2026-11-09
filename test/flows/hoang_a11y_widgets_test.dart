import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:longvita/firebase/analytics_service.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/screens/meal_flow_screens.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';
import 'package:longvita/screens/shopping_flow_screens.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

import '../auth/auth_fakes.dart';
import 'hoang_viewmodels_test.dart' show MemoryData, fixturePlan, beans;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('S04/S07/S08/S05 fit width $width at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final data = MemoryData();
        final analytics = FakeAnalytics();
        final crash = FakeCrashlytics();
        final meals = MealPlanViewModel(
          dataService: data,
          analytics: analytics,
          crashlytics: crash,
          remoteConfig: FakeRemoteConfig(),
        );
        final shopping = IngredientViewModel(
          dataService: data,
          analytics: analytics,
          crashlytics: crash,
        );
        meals.onSessionStarted(testUser('uid-1'));
        shopping.onSessionStarted(testUser('uid-1'));
        meals.selectSavedPlan(fixturePlan(id: 'plan-1'));

        Widget app(Widget screen) => MultiProvider(
          providers: [
            ChangeNotifierProvider<MealPlanViewModel>.value(value: meals),
            ChangeNotifierProvider<IngredientViewModel>.value(value: shopping),
            Provider<AnalyticsService>.value(value: analytics),
          ],
          child: MaterialApp(
            builder: (_, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: scale,
              maxScaleFactor: scale,
              child: child!,
            ),
            home: screen,
          ),
        );

        await tester.pumpWidget(app(const WeeklyPlanScreen()));
        await tester.pumpAndSettle();
        expect(find.text('S04 • Thực đơn 7 ngày'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(app(const IngredientSummaryScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Nguyên liệu'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(app(const ShoppingListScreen()));
        await tester.pump();
        expect(find.text('Danh sách mua sắm'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(app(const RecipeDetailsScreen(recipe: beans)));
        await tester.pump();
        expect(find.text('Recipe details'), findsOneWidget);
        expect(find.text(beans.name), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 'loading' is not a proof of accessibility: test actual labels.
        expect(
          find.text(
            '${beans.proteinGrams.toStringAsFixed(0)} g protein · 1 serving',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Chưa có ảnh được xác minh cho món này'),
          findsOneWidget,
        );
        final insecureRecipe = RecipeModel.fromMap({
          ...beans.toMap(),
          'imageUrl': 'http://invalid.example/meal.jpg',
        }, beans.id);
        await tester.pumpWidget(
          app(RecipeDetailsScreen(recipe: insecureRecipe)),
        );
        await tester.pump();
        expect(find.byKey(const Key('recipe-hero-image')), findsNothing);
        expect(
          find.text('Chưa có ảnh được xác minh cho món này'),
          findsOneWidget,
        );

        // A pending verified HTTPS fetch must not announce a missing image.
        final loadingRecipe = RecipeModel.fromMap({
          ...beans.toMap(),
          'imageUrl': 'https://example.invalid/meal.jpg',
        }, beans.id);
        await tester.pumpWidget(
          app(RecipeDetailsScreen(recipe: loadingRecipe)),
        );
        expect(find.byKey(const Key('recipe-hero-loading')), findsOneWidget);
        expect(find.text('Đang tải ảnh món…'), findsOneWidget);
        expect(
          find.text('Chưa có ảnh được xác minh cho món này'),
          findsNothing,
        );
      });
    }
  }

  testWidgets('S02 validates missing preferences before navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PreferencesScreen()));
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(find.text('Nhập tuổi trong khoảng 18–120'), findsOneWidget);
    expect(find.text('Nhập cân nặng hợp lệ từ 25–300 kg'), findsOneWidget);
  });

  testWidgets('S07 requires a positive quantity', (tester) async {
    final data = MemoryData();
    final analytics = FakeAnalytics();
    final crash = FakeCrashlytics();
    final meals = MealPlanViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
      remoteConfig: FakeRemoteConfig(),
    )..selectSavedPlan(fixturePlan(id: 'plan-1'));
    final items = IngredientViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MealPlanViewModel>.value(value: meals),
          ChangeNotifierProvider<IngredientViewModel>.value(value: items),
        ],
        child: const MaterialApp(home: IngredientSummaryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.ensureVisible(find.byTooltip('Sửa số lượng Đậu').first);
    await tester.tap(find.byTooltip('Sửa số lượng Đậu').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-ingredient-amount')),
      '-50',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Số lượng phải lớn hơn 0'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('edit-ingredient-amount')),
      '150',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(items.ingredients.firstWhere((x) => x.name == 'Đậu').amount, 150);
  });
}
