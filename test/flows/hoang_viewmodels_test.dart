import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/ingredient_model.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/services/data_failure.dart';
import 'package:longvita/services/data_service.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

import '../auth/auth_fakes.dart';

const beans = RecipeModel(
  id: 'beans',
  name: 'Súp đậu',
  description: 'Món đậu',
  category: 'dau',
  proteinGrams: 14,
  calories: 300,
  ingredients: [
    IngredientModel(id: 'beans-100', name: 'Đậu', amount: 100, unit: 'g'),
  ],
  instructions: ['Luộc đậu'],
  sourceNote: 'Nguồn Firestore',
);

const vegetables = RecipeModel(
  id: 'veg',
  name: 'Rau hấp',
  description: 'Món rau',
  category: 'rau_cu',
  proteinGrams: 10,
  calories: 290,
  ingredients: [
    IngredientModel(id: 'beans-200', name: 'Đậu', amount: 50, unit: 'g'),
    IngredientModel(id: 'carrot', name: 'Cà rốt', amount: 70, unit: 'g'),
  ],
  instructions: ['Hấp rau'],
  sourceNote: 'Nguồn Firestore',
);

MealPlanModel fixturePlan({String id = '', String uid = 'uid-1'}) =>
    MealPlanModel(
      id: id,
      uid: uid,
      title: 'Thực đơn test',
      targetCalories: 1800,
      targetProteinGrams: 50,
      createdAt: DateTime(2026, 11, 4),
      days: List.generate(
        7,
        (index) => DailyMeal(
          dayIndex: index,
          dayName: 'Ngày test',
          meals: const [beans, vegetables],
        ),
      ),
    );

class RecordingAnalytics extends FakeAnalytics {
  @override
  Future<void> logReplaceMeal({
    required String oldRecipeId,
    required String newRecipeId,
    required int dayIndex,
  }) async => events.add('replace_meal');
}

class MemoryData implements IDataService {
  List<RecipeModel> recipes = [beans, vegetables];
  final Map<String, MealPlanModel> plans = {};
  final Map<String, List<IngredientModel>> checklists = {};
  bool failRead = false;
  bool failWrite = false;
  bool failChecklist = false;
  int saved = 0;

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) async {
    if (failRead) {
      throw const DataFailure(
        DataFailureKind.offline,
        'Mất mạng khi lấy recipes',
      );
    }
    return category == null
        ? [...recipes]
        : recipes.where((r) => r.category == category).toList();
  }

  @override
  Future<String> saveMealPlan(MealPlanModel plan) async {
    if (failWrite) {
      throw const DataFailure(
        DataFailureKind.offline,
        'Lưu Firestore thất bại',
      );
    }
    final id = plan.id.isNotEmpty ? plan.id : 'plan-${++saved}';
    plans[id] = plan.copyWith(id: id);
    return id;
  }

  @override
  Future<List<MealPlanModel>> getUserMealPlans(String uid) async {
    if (failRead) throw Exception('offline');
    return plans.values.where((p) => p.uid == uid).toList();
  }

  @override
  Future<List<IngredientModel>?> getShoppingItems(
    String uid,
    String planId,
  ) async {
    if (failRead) throw Exception('offline');
    return checklists['$uid/$planId'] == null
        ? null
        : [...checklists['$uid/$planId']!];
  }

  @override
  Future<void> saveShoppingItems(
    String uid,
    String planId,
    List<IngredientModel> items,
  ) async {
    if (failChecklist) throw Exception('offline');
    checklists['$uid/$planId'] = [...items];
  }

  @override
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  }) => fixturePlan(uid: uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class HeldSearchData extends MemoryData {
  final calls = <Completer<List<RecipeModel>>>[];

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) {
    final call = Completer<List<RecipeModel>>();
    calls.add(call);
    return call.future;
  }
}

class HeldShoppingData extends MemoryData {
  final oldSave = Completer<void>();

  @override
  Future<void> saveShoppingItems(
    String uid,
    String planId,
    List<IngredientModel> items,
  ) async {
    if (uid == 'uid-a') {
      await oldSave.future;
      return;
    }
    return super.saveShoppingItems(uid, planId, items);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryData data;
  late RecordingAnalytics analytics;
  late FakeCrashlytics crash;
  late MealPlanViewModel plans;
  late IngredientViewModel shopping;

  setUp(() {
    data = MemoryData();
    analytics = RecordingAnalytics();
    crash = FakeCrashlytics();
    plans = MealPlanViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
      remoteConfig: FakeRemoteConfig(),
    );
    shopping = IngredientViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
    );
    plans.onSessionStarted(testUser('uid-1'));
    shopping.onSessionStarted(testUser('uid-1'));
  });

  tearDown(() {
    plans.dispose();
    shopping.dispose();
  });

  test('PR10-CR-02: deterministic document ID prevents retry duplication', () {
    final original = fixturePlan();
    final same = original.copyWith(title: 'Modified name');
    expect(DataService.draftDocumentId(original),
        DataService.draftDocumentId(same));
    expect(DataService.draftDocumentId(original),
        isNot(DataService.draftDocumentId(original.copyWith(
            createdAt: DateTime(2026, 11, 5)))));
    expect(DataService.writeTimeout, const Duration(seconds: 15));
  });

  test('PR10-CR-03: older recipe search cannot overwrite newer results', () async {
    final held = HeldSearchData();
    final vm = MealPlanViewModel(
        dataService: held, analytics: analytics, crashlytics: crash,
        remoteConfig: FakeRemoteConfig());
    final older = vm.searchRecipes('đậu');
    final latest = vm.searchRecipes('rau');
    held.calls[1].complete([beans, vegetables]);
    await latest;
    expect((vm.recipesState as ViewStateSuccess<List<RecipeModel>>)
        .data.single.id, 'veg');
    held.calls[0].complete([beans, vegetables]);
    await older;
    expect((vm.recipesState as ViewStateSuccess<List<RecipeModel>>)
        .data.single.id, 'veg');
    vm.dispose();
  });

  test('PR10-CR-03: stale search errors do not override newer data', () async {
    final held = HeldSearchData();
    final vm = MealPlanViewModel(
        dataService: held, analytics: analytics, crashlytics: crash,
        remoteConfig: FakeRemoteConfig());
    final older = vm.searchRecipes('đậu');
    final latest = vm.searchRecipes('rau');
    held.calls[1].complete([vegetables]);
    await latest;
    held.calls[0].completeError(Exception('old request failed'));
    await older;
    expect((vm.recipesState as ViewStateSuccess<List<RecipeModel>>)
        .data.single.id, 'veg');
    vm.dispose();
  });

  test('PR10-CR-03: stale alternatives cannot overwrite newest options', () async {
    final held = HeldSearchData();
    final vm = MealPlanViewModel(
        dataService: held, analytics: analytics, crashlytics: crash,
        remoteConfig: FakeRemoteConfig());
    final older = vm.loadAlternatives(beans);
    final latest = vm.loadAlternatives(vegetables);
    held.calls[1].complete([beans, vegetables]);
    await latest;
    expect((vm.alternativesState as ViewStateSuccess<List<RecipeModel>>)
        .data.single.id, 'beans');
    held.calls[0].complete([beans, vegetables]);
    await older;
    expect((vm.alternativesState as ViewStateSuccess<List<RecipeModel>>)
        .data.single.id, 'beans');
    vm.dispose();
  });

  test('HOANG-F03: missing Firestore citation must not be fabricated', () {
    final recipe = RecipeModel.fromMap({
      'name': 'Firestore recipe',
      'description': '',
      'category': 'dau',
      'proteinGrams': 10,
      'calories': 300,
      'ingredients': <Object>[],
      'instructions': <Object>[],
    }, 'real-doc');
    expect(
      recipe.sourceNote,
      isEmpty,
      reason: 'No default book attribution when source was never provided',
    );
  });

  test('S4-4: no hardcoded recipes when Firestore is empty', () async {
    data.recipes = [];
    await plans.generatePlan(uid: 'uid-1', weightKg: 60, age: 30);
    expect(plans.currentPlanState, isA<ViewStateEmpty<MealPlanModel>>());
    expect(plans.activePlan, isNull);
  });

  test('S4-7: offline generation reports error and retry succeeds', () async {
    data.failRead = true;
    await plans.generatePlan(uid: 'uid-1', weightKg: 60, age: 30);
    expect(plans.currentPlanState, isA<ViewStateError<MealPlanModel>>());
    data.failRead = false;
    await plans.generatePlan(uid: 'uid-1', weightKg: 60, age: 30);
    expect(plans.currentPlanState, isA<ViewStateSuccess<MealPlanModel>>());
  });

  test('S4-4: save failure retains current plan; retry saves', () async {
    await plans.generatePlan(
      uid: 'uid-1',
      weightKg: 60,
      age: 65,
      mealsPerDay: 3,
      eatingWindowHours: 12,
    );
    final original = plans.activePlan;
    expect(analytics.events, contains('generate_meal_plan:over_65:3:12:0'));
    data.failWrite = true;
    expect(await plans.saveActivePlan(), false);
    expect(plans.activePlan, same(original));
    expect(plans.saveState, isA<ViewStateError<bool>>());
    data.failWrite = false;
    expect(await plans.saveActivePlan(), true);
    expect(plans.activePlan!.id, 'plan-1');
    expect(plans.saveState, isA<ViewStateSuccess<bool>>());
  });

  test('S4-6: replace failure never alters original; retry succeeds', () async {
    plans.selectSavedPlan(fixturePlan(id: 'plan-1'));
    data.failWrite = true;
    expect(
      await plans.replaceMeal(
        dayIndex: 0,
        originalId: 'beans',
        replacement: vegetables,
      ),
      false,
    );
    expect(plans.activePlan!.days.first.meals.first.id, 'beans');
    expect(plans.replaceState, isA<ViewStateError<bool>>());
    data.failWrite = false;
    expect(
      await plans.replaceMeal(
        dayIndex: 0,
        originalId: 'beans',
        replacement: vegetables,
      ),
      true,
    );
    expect(plans.activePlan!.days.first.meals.first.id, 'veg');
    expect(analytics.events, contains('replace_meal'));
  });

  test('S4-2/S10: empty, load and error saved plan states', () async {
    await plans.fetchSavedPlans('uid-1');
    expect(plans.savedPlansState, isA<ViewStateEmpty<List<MealPlanModel>>>());
    data.plans['p'] = fixturePlan(id: 'p');
    await plans.fetchSavedPlans('uid-1');
    expect(plans.savedPlansState, isA<ViewStateSuccess<List<MealPlanModel>>>());
    data.failRead = true;
    await plans.fetchSavedPlans('uid-1');
    expect(plans.savedPlansState, isA<ViewStateError<List<MealPlanModel>>>());
  });

  test('S4-5: totals, positive validation, delete and Undo', () {
    shopping.aggregateFromMealPlan(fixturePlan(id: 'plan-1'));
    final item = shopping.ingredients.firstWhere((x) => x.name == 'Đậu');
    expect(item.amount, 1050, reason: 'Seven days × (100 + 50 g)');
    expect(shopping.updateAmount(item.id, -50), false);
    expect(shopping.updateAmount(item.id, double.nan), false);
    expect(shopping.updateAmount(item.id, 100), true);
    shopping.deleteIngredient(item.id);
    expect(shopping.canUndo, true);
    expect(shopping.undoDelete(), true);
    expect(shopping.ingredients.any((x) => x.id == item.id), true);
  });

  test('S4-5: checklist survives reopening and empty deletion', () async {
    final plan = fixturePlan(id: 'plan-1');
    await shopping.loadForPlan(plan);
    final id = shopping.ingredients.first.id;
    shopping.togglePurchased(id);
    expect(await shopping.persistChanges(), true);
    final second = IngredientViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
    );
    await second.loadForPlan(plan);
    expect(second.ingredients.first.isPurchased, true);
    for (final item in [...second.ingredients]) {
      second.deleteIngredient(item.id);
    }
    expect(await second.persistChanges(), true);
    final third = IngredientViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crash,
    );
    await third.loadForPlan(plan);
    expect(third.state, isA<ViewStateEmpty<List<IngredientModel>>>());
    second.dispose();
    third.dispose();
  });

  test('HOANG-F02: old user save must not block new user', () async {
    final held = HeldShoppingData();
    final vm = IngredientViewModel(
      dataService: held,
      analytics: analytics,
      crashlytics: crash,
    );
    vm.onSessionStarted(testUser('uid-a'));
    await vm.loadForPlan(fixturePlan(id: 'old', uid: 'uid-a'));
    final oldWrite = vm.persistChanges();

    vm.clearSession();
    vm.onSessionStarted(testUser('uid-b'));
    await vm.loadForPlan(fixturePlan(id: 'new', uid: 'uid-b'));
    expect(await vm.persistChanges(), true);
    expect(
      held.checklists['uid-b/new'],
      isNotEmpty,
      reason: 'New user save is independent of old pending request',
    );
    held.oldSave.complete();
    expect(
      await oldWrite,
      false,
      reason: 'Old session cannot update the new session state',
    );
    vm.dispose();
  });

  test(
    'S4-5: shopping save failure preserves edited list and retry works',
    () async {
      await shopping.loadForPlan(fixturePlan(id: 'plan-1'));
      final id = shopping.ingredients.first.id;
      shopping.togglePurchased(id);
      data.failChecklist = true;
      expect(await shopping.persistChanges(), false);
      expect(shopping.persistenceState, isA<ViewStateError<bool>>());
      expect(shopping.ingredients.first.isPurchased, true);
      data.failChecklist = false;
      expect(await shopping.persistChanges(), true);
    },
  );
}
