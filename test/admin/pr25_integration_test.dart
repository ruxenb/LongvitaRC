import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/admin/admin_service.dart';
import 'package:longvita/admin/admin_viewmodels.dart';
import 'package:longvita/admin/recipe_management_screen.dart';
import 'package:longvita/admin/review_queue_item.dart';
import 'package:longvita/admin/review_queue_screen.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/models/ingredient_model.dart';
import 'package:provider/provider.dart';

import 'admin_web_test.dart' as fixtures;

class _DelayedAdminService extends fixtures.FakeAdminService {
  final saveGate = Completer<void>();
  final reviewGate = Completer<void>();
  final metricsGate = Completer<AdminDashboardMetrics>();

  @override
  Future<void> saveRecipe(RecipeModel recipe) => saveGate.future;

  @override
  Future<void> reviewPlan(String id, String status, {String? reason}) =>
      reviewGate.future;

  @override
  Future<AdminDashboardMetrics> loadMetrics() => metricsGate.future;
}

void main() {
  test(
    'editing preserves ingredient names with commas and duplicate names',
    () {
      const original = [
        IngredientModel(
          id: 'tomato-1',
          name: 'Tomatoes, raw',
          amount: 2.25,
          unit: 'g',
          category: 'vegetables',
        ),
        IngredientModel(
          id: 'tomato-2',
          name: 'Tomatoes, raw',
          amount: 0.04,
          unit: 'kg',
          category: 'vegetables',
        ),
      ];
      final edited = editableRecipe(
        name: 'Salad',
        description: 'Updated',
        category: 'rau_cu',
        calories: 200,
        protein: 12,
        ingredients: original.map((row) => row.name).join('\n'),
        instructions: 'Mix',
        existingIngredients: original,
      );
      expect(
        edited.ingredients.map((row) => row.toMap()).toList(),
        original.map((row) => row.toMap()).toList(),
      );
    },
  );

  testWidgets('editing an existing source category preserves its value', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = fixtures.FakeAdminService();
    final vm = RecipeAdminViewModel(service);
    final source = RecipeModel.fromMap({
      ...fixtures.recipe().toMap(),
      'category': 'vegetables',
    }, 'source-recipe');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: fixtures.app(const RecipeManagementScreen()),
      ),
    );
    await tester.pump();
    service.recipes.add([source]);
    await tester.pump();
    await tester.tap(find.byTooltip('Chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sửa công thức'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    expect(service.saved.single.category, 'vegetables');
    expect(
      service.saved.single.ingredients.single.toMap(),
      source.ingredients.single.toMap(),
    );
    expect(service.saved.single.imageUrl, source.imageUrl);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    await service.recipes.close();
    await service.plans.close();
  });

  test(
    'a save finishing after navigation does not notify a disposed VM',
    () async {
      final service = _DelayedAdminService();
      final vm = RecipeAdminViewModel(service);
      final operation = vm.save(fixtures.recipe());
      vm.dispose();
      service.saveGate.complete();
      await expectLater(operation, completes);
    },
  );

  test(
    'a review finishing after logout does not notify a disposed VM',
    () async {
      final service = _DelayedAdminService();
      final vm = ReviewQueueViewModel(service);
      final operation = vm.review(
        ReviewQueueItem.fromMap(fixtures.plan().toMap(), 'p1'),
        'approved',
      );
      vm.dispose();
      service.reviewGate.complete();
      await expectLater(operation, completes);
    },
  );

  test('metrics finishing after logout do not notify a disposed VM', () async {
    final service = _DelayedAdminService();
    final vm = DashboardViewModel(service);
    final operation = vm.load();
    vm.dispose();
    service.metricsGate.complete(service.metrics);
    await expectLater(operation, completes);
  });

  for (final badData in <String, Map<String, dynamic>>{
    'non-map days': {'days': List.filled(7, 'not-a-day')},
    'non-map meal': {
      'days': [...fixtures.plan().toMap()['days'] as List]
        ..[0] = {
          'dayIndex': 0,
          'meals': [42],
        },
    },
    'non-map ingredient': {
      'days': List.generate(
        7,
        (index) => {
          'dayIndex': index,
          'meals': [
            {
              ...fixtures.recipe().toMap(),
              'ingredients': ['bad'],
            },
          ],
        },
      ),
    },
    'duplicate day indices': {
      'days': List.generate(7, (_) => fixtures.plan().days.first.toMap()),
    },
  }.entries) {
    test('malformed ${badData.key} remains an isolated unapprovable row', () {
      final rows = [
        ReviewQueueItem.fromMap(fixtures.plan().toMap(), 'good'),
        ReviewQueueItem.fromMap({
          ...fixtures.plan().toMap(),
          ...badData.value,
        }, 'bad'),
      ];
      expect(rows.first.canApprove, isTrue);
      expect(rows.last.canApprove, isFalse);
      expect(rows.last.id, 'bad');
      expect(rows.last.uid, 'u1');
    });
  }

  test('VM refuses approval of an invalid row but allows rejection', () async {
    final service = fixtures.FakeAdminService();
    final vm = ReviewQueueViewModel(service);
    final row = ReviewQueueItem.fromMap({
      ...fixtures.plan().toMap(),
      'days': List.filled(7, 'invalid'),
    }, 'bad');
    await expectLater(vm.review(row, 'approved'), throwsStateError);
    expect(service.reviewed, isEmpty);
    await vm.review(row, 'rejected', reason: 'Dữ liệu không hợp lệ');
    expect(service.reviewed, [('bad', 'rejected', 'Dữ liệu không hợp lệ')]);
    vm.dispose();
  });

  testWidgets(
    'a bad submission stays visible without disabling valid reviews',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = fixtures.FakeAdminService();
      final vm = ReviewQueueViewModel(service);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: fixtures.app(const ReviewQueueScreen()),
        ),
      );
      await tester.pump();
      service.plans.add([
        ReviewQueueItem.fromMap(fixtures.plan().toMap(), 'good'),
        ReviewQueueItem.fromMap({
          ...fixtures.plan().toMap(),
          'title': 'Thực đơn lỗi cấu trúc',
          'days': List.filled(7, 'invalid'),
        }, 'bad'),
      ]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Dữ liệu thực đơn lỗi.'), findsOneWidget);
      final approve = find.widgetWithText(FilledButton, 'Duyệt');
      expect(approve, findsNWidgets(2));
      expect(tester.widget<FilledButton>(approve.last).onPressed, isNull);
      await tester.tap(approve.first);
      await tester.pump();
      expect(service.reviewed, [('good', 'approved', null)]);
      await tester.tap(find.text('Từ chối').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Dữ liệu không hợp lệ');
      await tester.tap(find.text('Xác nhận từ chối'));
      await tester.pumpAndSettle();
      expect(service.reviewed.last, (
        'bad',
        'rejected',
        'Dữ liệu không hợp lệ',
      ));
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await service.recipes.close();
      await service.plans.close();
    },
  );
}
