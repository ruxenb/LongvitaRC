import 'package:longvita/config/pdf_export_mode.dart';
// User A signs out, user B signs in: B must not see A's local data.
// Uses the real ViewModels wired like main.dart, with fake services.
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/announcement_model.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/ingredient_model.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import 'auth_fakes.dart';

MealPlanModel planFor(String uid) => MealPlanModel(
      id: 'plan-$uid',
      uid: uid,
      title: 'Plan of $uid',
      targetCalories: 1800,
      targetProteinGrams: 50,
      createdAt: DateTime(2026, 11, 2),
      days: const [
        DailyMeal(dayIndex: 0, dayName: 'Thứ Hai', meals: [
          RecipeModel(
            id: 'r1',
            name: 'Lentil soup',
            description: 'fixture',
            category: 'dau',
            proteinGrams: 18,
            calories: 320,
            ingredients: [
              IngredientModel(id: 'i1', name: 'Lentils', amount: 120, unit: 'g'),
            ],
            instructions: ['fixture'],
          ),
        ]),
      ],
    );

class FakeDataService implements IDataService {
  @override
  Future<List<RecipeModel>> getRecipes({String? category}) async =>
      planFor('x').days.first.meals;

  @override
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  }) =>
      planFor(uid);

  @override
  Future<List<MealPlanModel>> getUserMealPlans(String uid) async =>
      [planFor(uid)];

  @override
  Stream<List<AnnouncementModel>> streamAnnouncements() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('B does not see A\'s plan, ingredients, export URL or inbox', () async {
    final auth = FakeAuthService();
    final analytics = FakeAnalytics();
    final crashlytics = FakeCrashlytics();
    final notifications = FakeNotificationService();

    final mealPlan = MealPlanViewModel(
      dataService: FakeDataService(),
      analytics: analytics,
      crashlytics: crashlytics,
      remoteConfig: FakeRemoteConfig(),
    );
    final ingredients =
        IngredientViewModel(analytics: analytics, crashlytics: crashlytics);
    final profile = ProfileViewModel(
      metadataRepository: FakeReportMetadataRepository(),
      exportMode: PdfExportMode.storageEmulatorDemo,
      authService: auth,
      storageService: FakeStorageService(),
      notificationService: notifications,
      reportService: FakeReportService(),
      reportStore: FakeLocalReportStore(),
      reportViewer: FakeReportViewer(),
      remoteConfigService: FakeRemoteConfig(),
      crashlyticsService: crashlytics,
      analyticsService: analytics,
    );
    final vm = AuthViewModel(
      authService: auth,
      analytics: analytics,
      crashlytics: crashlytics,
      sessionScoped: [mealPlan, ingredients, profile],
    );
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));
    await settle();

    // User A works in the app.
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    await vm.signInWithGoogle();
    await settle();
    expect(notifications.initializeCalls, 1,
        reason: 'FCM permission is requested after sign-in, not at start');

    await mealPlan.generatePlan(uid: 'uid-a', weightKg: 60, age: 30);
    ingredients.aggregateFromMealPlan(mealPlan.activePlan!);
    await mealPlan.fetchSavedPlans('uid-a');
    await profile.exportAndUploadPdf(mealPlan.activePlan!);
    expect(mealPlan.activePlan?.uid, 'uid-a');
    expect(ingredients.ingredients, isNotEmpty);
    expect(profile.lastUploadedUrl, contains('uid-a'));

    // A signs out, B signs in.
    await vm.signOut();
    await settle();
    expect(mealPlan.activePlan, isNull);
    expect(mealPlan.currentPlanState, isA<ViewStateIdle>());
    expect(mealPlan.savedPlansState, isA<ViewStateIdle>());
    expect(ingredients.ingredients, isEmpty);
    expect(ingredients.canUndo, isFalse);
    expect(profile.lastUploadedUrl, isNull);
    expect(profile.exportState, isA<ViewStateIdle>());
    expect(notifications.messages, isEmpty);

    auth.nextSignIn = const AuthSignInSucceeded('uid-b');
    await vm.signInWithGoogle();
    await settle();
    expect(vm.currentUser?.uid, 'uid-b');
    expect(profile.user?.uid, 'uid-b');
    expect(mealPlan.activePlan, isNull);
    expect(auth.signOutCalls, 1, reason: 'sign-out never deletes cloud data');
  });
}
