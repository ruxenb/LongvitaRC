import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:longvita/models/ingredient_model.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/screens/shopping_flow_screens.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/widgets/app_navigation_bar.dart';
import 'package:longvita/widgets/app_supporting.dart';
import 'package:longvita/widgets/app_icon_button.dart';
import 'package:longvita/widgets/app_button.dart';

import '../auth/auth_fakes.dart';
import '../qa/qa_support.dart';
import 'hoang_viewmodels_test.dart' show MemoryData, fixturePlan;

const sampleItems = [
  IngredientModel(
    id: 'broccoli',
    name: 'Broccoli',
    amount: 600,
    unit: 'g',
    category: 'rau',
  ),
  IngredientModel(
    id: 'tomatoes',
    name: 'Tomatoes',
    amount: 8,
    unit: 'medium',
    category: 'vegetables',
    isPurchased: true,
  ),
  IngredientModel(
    id: 'lentils',
    name: 'Lentils',
    amount: 500,
    unit: 'g',
    category: 'đậu',
  ),
  IngredientModel(
    id: 'beans',
    name: 'Cannellini beans',
    amount: 3,
    unit: 'cans',
    category: 'legumes',
  ),
  IngredientModel(
    id: 'walnuts',
    name: 'Walnuts',
    amount: 210,
    unit: 'g',
    category: 'hạt',
  ),
  IngredientModel(
    id: 'oil',
    name: 'Extra virgin olive oil',
    amount: 315,
    unit: 'ml',
    category: 'dầu hạt',
  ),
];

class FlowFixture {
  final data = MemoryData();
  final analytics = FakeAnalytics();
  final crash = FakeCrashlytics();
  late final meals = MealPlanViewModel(
    dataService: data,
    analytics: analytics,
    crashlytics: crash,
    remoteConfig: FakeRemoteConfig(),
  );
  late final items = IngredientViewModel(
    dataService: data,
    analytics: analytics,
    crashlytics: crash,
  );

  FlowFixture({List<IngredientModel> source = sampleItems}) {
    data.checklists['uid-1/plan-1'] = [...source];
    meals.onSessionStarted(testUser('uid-1'));
    items.onSessionStarted(testUser('uid-1'));
    meals.selectSavedPlan(fixturePlan(id: 'plan-1'));
  }

  Widget host(Widget screen, {double scale = 1, GlobalKey? boundary}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MealPlanViewModel>.value(value: meals),
          ChangeNotifierProvider<IngredientViewModel>.value(value: items),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          routes: {
            '/profile': (_) =>
                const Scaffold(body: Text('Profile route destination')),
          },
          home: RepaintBoundary(key: boundary, child: screen),
        ),
      );

  void dispose() {
    meals.dispose();
    items.dispose();
  }
}

void main() {
  setUpAll(loadQaFonts);

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Flow2 screenshot/layout width=$width scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final f = FlowFixture();
        addTearDown(f.dispose);
        for (final shopping in [false, true]) {
          final boundary = GlobalKey();
          await f.items.loadForPlan(fixturePlan(id: 'plan-1'));
          await tester.pumpWidget(
            f.host(
              shopping
                  ? const ShoppingListScreen()
                  : const IngredientSummaryScreen(),
              scale: scale,
              boundary: boundary,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(
              shopping ? 'Ready for the store' : 'Ingredients for the week',
            ),
            findsOneWidget,
          );
          expect(find.text('Vegetables'), findsOneWidget);
          expect(find.text('Legumes'), findsOneWidget);
          expect(find.text('Nuts and oils'), findsOneWidget);
          await captureQa(
            tester,
            boundary,
            '${shopping ? 's08' : 's07'}-${width.toInt()}-text$scale',
            pixelRatio: 1,
            metadata: {
              'figmaNode': shopping ? '106:235' : '106:189',
              'textScale': scale,
              'host': 'Flutter widget host with real bundled fonts; fake data, not native Firebase',
            },
          );
          if (!shopping) {
            await tester.ensureVisible(
              find.byKey(const Key('create-shopping-list')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          } else {
            expect(
              tester.getSize(find.byType(AppNavigationBar)).height,
              greaterThanOrEqualTo(80),
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }
  }

  testWidgets(
    'Edit, create, tick entire row, Back and persistence stay connected',
    (tester) async {
      final f = FlowFixture();
      addTearDown(f.dispose);
      await tester.pumpWidget(f.host(const IngredientSummaryScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sửa số lượng Broccoli'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-ingredient-amount')),
        '650,5',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('650.5 g'), findsOneWidget);
      expect(f.data.checklists['uid-1/plan-1']!.first.amount, 650.5);
      await tester.drag(find.byType(SnackBar), const Offset(0, 200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('create-shopping-list')));
      await tester.tap(find.byKey(const Key('create-shopping-list')));
      await tester.pumpAndSettle();
      expect(find.text('Shopping list'), findsOneWidget);
      await tester.tap(find.text('Broccoli · 650.5 g'));
      await tester.pumpAndSettle();
      expect(f.items.ingredients.first.isPurchased, true);
      expect(f.data.checklists['uid-1/plan-1']!.first.isPurchased, true);
      await tester.tap(find.byType(AppIconButton));
      await tester.pumpAndSettle();
      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('650.5 g'), findsOneWidget);
    },
  );

  testWidgets(
    'Delete is in edit dialog; Undo restores the original category and position',
    (tester) async {
      final f = FlowFixture();
      addTearDown(f.dispose);
      await tester.pumpWidget(f.host(const IngredientSummaryScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sửa số lượng Broccoli'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa nguyên liệu'));
      await tester.pumpAndSettle();
      expect(find.text('Broccoli'), findsNothing);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(f.items.ingredients.first.id, 'broccoli');
      expect(f.data.checklists['uid-1/plan-1']!.first.category, 'rau');
      expect(find.text('Broccoli'), findsOneWidget);
    },
  );

  testWidgets(
    'Semantics headings, ingredient identity, checked state and hit targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final f = FlowFixture();
      addTearDown(f.dispose);
      await tester.pumpWidget(f.host(const IngredientSummaryScreen()));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Ingredients for the week')).headingLevel,
        2,
      );
      expect(tester.getSemantics(find.text('Vegetables')).headingLevel, 3);
      expect(find.bySemanticsLabel('Edit Broccoli'), findsOneWidget);
      expect(find.bySemanticsLabel('Broccoli, 600 g'), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('Sửa số lượng Broccoli')).shortestSide,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(f.host(const ShoppingListScreen()));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.text('Shopping list')).headingLevel, 1);
      expect(
        tester.getSemantics(find.byKey(const Key('shopping-tomatoes'))),
        matchesSemantics(
          label: 'Tomatoes · 8 medium',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('shopping-broccoli'))).height,
        greaterThanOrEqualTo(64),
      );
      expect(find.byType(AppCheckboxRow), findsNWidgets(6));
      semantics.dispose();
    },
  );

  testWidgets(
    'Read error has retry; empty saved checklist stays empty and CTA disabled',
    (tester) async {
      final f = FlowFixture(source: []);
      addTearDown(f.dispose);
      f.data.failRead = true;
      await tester.pumpWidget(f.host(const IngredientSummaryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Không thể hoàn thành'), findsOneWidget);
      f.data.failRead = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Danh sách trống'), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(find.byKey(const Key('create-shopping-list')))
            .onPressed,
        isNull,
      );
      expect(f.items.ingredients, isEmpty);
      expect(f.items.state, isA<ViewStateEmpty<List<IngredientModel>>>());
    },
  );

  testWidgets(
    'Failed checklist save preserves tick, then inline retry persists it',
    (tester) async {
      final f = FlowFixture();
      addTearDown(f.dispose);
      await f.items.loadForPlan(fixturePlan(id: 'plan-1'));
      f.data.failChecklist = true;
      await tester.pumpWidget(f.host(const ShoppingListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Broccoli · 600 g'));
      await tester.pumpAndSettle();
      expect(f.items.ingredients.first.isPurchased, true);
      expect(f.data.checklists['uid-1/plan-1']!.first.isPurchased, false);
      f.data.failChecklist = false;
      await tester.drag(find.byType(SnackBar), const Offset(0, 200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thử lại đồng bộ'));
      await tester.tap(find.text('Thử lại đồng bộ'));
      await tester.pumpAndSettle();
      expect(f.data.checklists['uid-1/plan-1']!.first.isPurchased, true);
    },
  );

  testWidgets(
    'Unknown categories and long Vietnamese names remain readable at text2',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const name =
          'Rau xanh hữu cơ và các loại nguyên liệu có tên dài cần hiển thị đầy đủ';
      final f = FlowFixture(
        source: [
          const IngredientModel(
            id: 'long',
            name: name,
            amount: 1234.5,
            unit: 'g',
            category: 'Nhóm nguồn riêng',
          ),
        ],
      );
      addTearDown(f.dispose);
      await tester.pumpWidget(
        f.host(const IngredientSummaryScreen(), scale: 2),
      );
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
      expect(find.text('Nhóm nguồn riêng'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byTooltip('Sửa số lượng $name'));
      await tester.tap(find.byTooltip('Sửa số lượng $name'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Hủy'));
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('Nutrition keeps current route; Profile destination is wired', (
    tester,
  ) async {
    final f = FlowFixture();
    addTearDown(f.dispose);
    await f.items.loadForPlan(fixturePlan(id: 'plan-1'));
    await tester.pumpWidget(f.host(const ShoppingListScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingListScreen), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile route destination'), findsOneWidget);
  });
  testWidgets(
    'Actual plan category aliases preserve data while grouping for display',
    (tester) async {
      final f = FlowFixture(
        source: [
          sampleItems.first,
          sampleItems.last.copyWith(category: 'dầu'),
          const IngredientModel(
            id: 'cheese',
            name: 'Phô mai',
            amount: 30,
            unit: 'g',
            category: 'phô mai',
          ),
        ],
      );
      addTearDown(f.dispose);
      await tester.pumpWidget(f.host(const IngredientSummaryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Nuts and oils'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(f.items.ingredients.map((i) => i.category), [
        'rau',
        'dầu',
        'phô mai',
      ]);
    },
  );
}
