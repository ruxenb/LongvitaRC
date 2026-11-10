import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita/screens/flow_ui.dart';
import 'package:longvita_core/services/data_service.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

import '../auth/auth_fakes.dart';
import 'hoang_viewmodels_test.dart'
    show MemoryData, fixturePlan, beans, vegetables;

/// Each request has its own manually completed Firestore result.
class DeferredRecipeData extends MemoryData {
  final requests = <Completer<List<RecipeModel>>>[];

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) {
    final next = Completer<List<RecipeModel>>();
    requests.add(next);
    return next.future;
  }
}

MealPlanViewModel _viewModel(DeferredRecipeData data) => MealPlanViewModel(
  dataService: data,
  analytics: FakeAnalytics(),
  crashlytics: FakeCrashlytics(),
  remoteConfig: FakeRemoteConfig(),
)..onSessionStarted(testUser('uid-1'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PR10-CR-03: older search success must not overwrite latest results',
    () async {
      final data = DeferredRecipeData();
      final vm = _viewModel(data);
      addTearDown(vm.dispose);

      final older = vm.searchRecipes('đậu');
      final newer = vm.searchRecipes('rau');
      expect(data.requests, hasLength(2));

      data.requests[1].complete([beans, vegetables]);
      await newer;
      var state = vm.recipesState as ViewStateSuccess<List<RecipeModel>>;
      expect(state.data.map((item) => item.id), ['veg']);

      data.requests[0].complete([beans, vegetables]);
      await older;
      state = vm.recipesState as ViewStateSuccess<List<RecipeModel>>;
      expect(state.data.map((item) => item.id), ['veg']);
    },
  );

  test(
    'PR10-CR-03: stale search failure cannot replace newer success',
    () async {
      final data = DeferredRecipeData();
      final vm = _viewModel(data);
      addTearDown(vm.dispose);

      final older = vm.searchRecipes('older');
      final newer = vm.searchRecipes('rau');
      data.requests[1].complete([vegetables]);
      await newer;
      data.requests[0].completeError(StateError('outdated query failed'));
      await older;

      final state = vm.recipesState as ViewStateSuccess<List<RecipeModel>>;
      expect(state.data.single.id, 'veg');
    },
  );

  test('PR10-CR-03: old alternatives cannot overwrite newer meal', () async {
    final data = DeferredRecipeData();
    final vm = _viewModel(data);
    addTearDown(vm.dispose);

    final older = vm.loadAlternatives(beans);
    final newer = vm.loadAlternatives(vegetables);
    data.requests[1].complete([beans, vegetables]);
    await newer;
    final before = vm.alternativesState as ViewStateSuccess<List<RecipeModel>>;
    expect(before.data.single.id, 'beans');

    data.requests[0].complete([beans, vegetables]);
    await older;
    final after = vm.alternativesState as ViewStateSuccess<List<RecipeModel>>;
    expect(after.data.single.id, 'beans');
  });

  test('PR10-CR-03: stale alternatives failure is ignored', () async {
    final data = DeferredRecipeData();
    final vm = _viewModel(data);
    addTearDown(vm.dispose);

    final older = vm.loadAlternatives(beans);
    final newer = vm.loadAlternatives(vegetables);
    data.requests[1].complete([beans, vegetables]);
    await newer;
    data.requests[0].completeError(StateError('old alternatives failed'));
    await older;
    expect(vm.alternativesState, isA<ViewStateSuccess<List<RecipeModel>>>());
  });

  test('PR10-CR-02: retrying a queued draft uses the same document id', () {
    final plan = fixturePlan();
    final id = DataService.draftDocumentId(plan);
    expect(id, DataService.draftDocumentId(plan));
    expect(id, isNotEmpty);
    expect(
      id.contains('/'),
      isFalse,
      reason: 'Firestore document ID must not introduce a new path segment',
    );
  });

  testWidgets('PR10-CR-01: card has one labelled accessible tap target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlowItemCard(
            title: 'Thực đơn thứ Hai',
            subtitle: 'Xem chi tiết món',
            onTap: () => taps++,
          ),
        ),
      ),
    );
    final semantics = tester.getSemantics(find.byType(FlowItemCard));
    expect(
      semantics,
      matchesSemantics(
        label: 'Thực đơn thứ Hai. Xem chi tiết món',
        isButton: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('Thực đơn thứ Hai'));
    expect(taps, 1);
  });
}
