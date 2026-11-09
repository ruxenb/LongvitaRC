// S4-10: the PDF is built from the plan the user is viewing at the moment of
// the export, not from an earlier plan or from the plan before a meal change.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/notification_service.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/screens/profile_screen.dart';
import 'package:longvita/services/i_data_service.dart';
import 'package:longvita/services/i_report_service.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

import '../auth/auth_fakes.dart';
import '../fcm/notification_service_test.dart' show FakeGateway;
import '../profile/profile_screen_test.dart' show MemoryHistory;

RecipeModel recipe(String id, String name, double protein, double kcal) =>
    RecipeModel(
      id: id,
      name: name,
      description: 'fixture',
      category: 'rau',
      proteinGrams: protein,
      calories: kcal,
      ingredients: const [],
      instructions: const ['fixture'],
    );

MealPlanModel plan(String id, String title, List<RecipeModel> monday) =>
    MealPlanModel(
      id: id,
      uid: 'uid-a',
      title: title,
      targetCalories: 1800,
      targetProteinGrams: 50,
      createdAt: DateTime(2026, 11, 2),
      days: [DailyMeal(dayIndex: 0, dayName: 'Thứ Hai', meals: monday)],
    );

/// Saves succeed; everything else is unused here.
class SavingDataService implements IDataService {
  final saved = <MealPlanModel>[];

  @override
  Future<String> saveMealPlan(MealPlanModel plan) async {
    saved.add(plan);
    return plan.id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the plan each PDF is built from.
class RecordingReportService implements IReportService {
  final plans = <MealPlanModel>[];

  @override
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan) async {
    plans.add(plan);
    return Uint8List.fromList([plans.length]);
  }
}

void main() {
  final soup = recipe('soup', 'Súp đậu gà', 18, 320);
  final salad = recipe('salad', 'Salad cải xoăn', 8, 220);
  final salmon = recipe('salmon', 'Cá hồi áp chảo', 28, 380);
  final planA = plan('plan-a', 'Thực đơn A', [soup, salad]);
  final planB = plan('plan-b', 'Thực đơn B', [salmon, salad]);

  late SavingDataService data;
  late RecordingReportService reports;
  late FakeLocalReportStore store;
  late MealPlanViewModel mealPlan;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = FakeAuthService();
    final analytics = FakeAnalytics();
    final crashlytics = FakeCrashlytics();
    data = SavingDataService();
    reports = RecordingReportService();
    store = FakeLocalReportStore();
    mealPlan = MealPlanViewModel(
      dataService: data,
      analytics: analytics,
      crashlytics: crashlytics,
      remoteConfig: FakeRemoteConfig(),
    );
    final profile = ProfileViewModel(
      metadataRepository: FakeReportMetadataRepository(),
      authService: auth,
      notificationService:
          NotificationService(gateway: FakeGateway(), history: MemoryHistory()),
      reportService: reports,
      reportStore: store,
      reportViewer: FakeReportViewer(),
      remoteConfigService: FakeRemoteConfig(),
      crashlyticsService: crashlytics,
      analyticsService: analytics,
    );
    final session = AuthViewModel(
      authService: auth,
      analytics: analytics,
      crashlytics: crashlytics,
      sessionScoped: [mealPlan, profile],
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: session),
        ChangeNotifierProvider<MealPlanViewModel>.value(value: mealPlan),
        ChangeNotifierProvider<ProfileViewModel>.value(value: profile),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    ));
    await settle(tester);
    auth.nextSignIn = const AuthSignInSucceeded('uid-a');
    unawaited(session.signInWithGoogle());
    await settle(tester);
  }

  Future<MealPlanModel> export(WidgetTester tester) async {
    final button = find.byKey(const Key('profile-export'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settle(tester);
    expect(find.text('Đã lưu PDF trên máy.'), findsOneWidget);
    return reports.plans.last;
  }

  testWidgets('after switching plans, the PDF is built from the new plan',
      (tester) async {
    await pumpProfile(tester);

    mealPlan.selectSavedPlan(planA);
    await settle(tester);
    expect((await export(tester)).id, 'plan-a');

    mealPlan.selectSavedPlan(planB);
    await settle(tester);
    final second = await export(tester);
    expect(second.id, 'plan-b');
    expect(second.title, 'Thực đơn B');
    expect(second.days.single.meals.map((r) => r.name),
        ['Cá hồi áp chảo', 'Salad cải xoăn']);
    expect(store.files.keys.last, matches(RegExp(r'^uid-a/pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$')));
    expect(store.files.values.last, [2], reason: 'saved bytes belong to the second generated PDF');
  });

  testWidgets('after a meal change, the PDF has the new meal and totals',
      (tester) async {
    await pumpProfile(tester);
    mealPlan.selectSavedPlan(planA);
    await settle(tester);
    final before = await export(tester);

    expect(
      await mealPlan.replaceMeal(
          dayIndex: 0, originalId: 'soup', replacement: salmon),
      isTrue,
    );
    await settle(tester);
    final after = await export(tester);

    expect(after.id, 'plan-a');
    expect(after.days.single.meals.map((r) => r.name),
        ['Cá hồi áp chảo', 'Salad cải xoăn']);
    expect(after.days.single.totalProtein, 36);
    expect(after.days.single.totalCalories, 600);
    // The first PDF keeps what was shown when it was made.
    expect(before.days.single.meals.first.name, 'Súp đậu gà');
    expect(data.saved.single.days.single.meals.first.id, 'salmon');
    expect(reports.plans, hasLength(2));
  });
}
