// PM-S3-5-01 / PM-S3-5-02: async work started in one session must not touch
// the state of the next session, including when the same uid signs back in.
// Uses the real ViewModels with fake services that hold their responses open.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/auth_state.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/models/view_state.dart';
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

import 'auth_fakes.dart';
import 'session_isolation_test.dart' show FakeDataService, planFor;

const lateUrl = 'https://storage.test/reports/uid-a/late.pdf';

class HeldStorage extends FakeStorageService {
  final started = Completer<void>();
  final response = Completer<String?>();
  void Function(double progress)? progress;
  int uploads = 0;

  @override
  Future<String?> uploadReportPdf({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) {
    uploads++;
    progress = onProgress;
    started.complete();
    return response.future;
  }
}

class HeldReport extends FakeReportService {
  final started = Completer<void>();
  final response = Completer<Uint8List>();

  @override
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan) {
    started.complete();
    return response.future;
  }
}

class HeldData extends FakeDataService {
  final started = Completer<void>();
  Completer<List<MealPlanModel>>? plans;
  Completer<List<RecipeModel>>? recipes;
  Completer<String>? save;
  Completer<void>? status;

  @override
  Future<List<MealPlanModel>> getUserMealPlans(String uid) {
    started.complete();
    return (plans ??= Completer()).future;
  }

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) {
    final held = recipes;
    if (held == null) return super.getRecipes(category: category);
    started.complete();
    return held.future;
  }

  @override
  Future<String> saveMealPlan(MealPlanModel plan) {
    started.complete();
    return (save ??= Completer()).future;
  }

  @override
  Future<void> updateMealPlanStatus(String planId, String status,
      {String? reason}) {
    started.complete();
    return (this.status ??= Completer()).future;
  }
}

/// Real session wiring around the participants under test.
class Session {
  final FakeAuthService auth = FakeAuthService();
  final FakeAnalytics analytics = FakeAnalytics();
  final FakeCrashlytics crashlytics = FakeCrashlytics();
  late final AuthViewModel vm;

  void wire(Iterable<dynamic> participants) {
    vm = AuthViewModel(
      authService: auth,
      analytics: analytics,
      crashlytics: crashlytics,
      sessionScoped: participants.cast(),
    );
  }

  Future<void> signIn(String uid) async {
    // The auth stream reports signed-out first; sign-in is ignored before it.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    auth.nextSignIn = AuthSignInSucceeded(uid);
    await vm.signInWithGoogle();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(vm.currentUser?.uid, uid);
  }
}

void main() {
  late Session session;

  setUp(() async {
    session = Session();
  });

  ProfileViewModel profileWith({
    FakeStorageService? storage,
    FakeReportService? report,
  }) {
    final profile = ProfileViewModel(
      authService: session.auth,
      storageService: storage ?? FakeStorageService(),
      notificationService: FakeNotificationService(),
      reportService: report ?? FakeReportService(),
      remoteConfigService: FakeRemoteConfig(),
      crashlyticsService: session.crashlytics,
      analyticsService: session.analytics,
    );
    session.wire([profile]);
    return profile;
  }

  MealPlanViewModel plansWith(HeldData data) {
    final plans = MealPlanViewModel(
      dataService: data,
      analytics: session.analytics,
      crashlytics: session.crashlytics,
      remoteConfig: FakeRemoteConfig(),
    );
    session.wire([plans]);
    return plans;
  }

  /// A -> logout -> [next] signs in, the usual way a session changes.
  Future<void> switchTo(String next) async {
    await session.vm.signOut();
    await session.signIn(next);
  }

  group('ProfileViewModel', () {
    // A -> logout -> B, and A -> logout -> A, which a uid check would miss.
    for (final next in ['uid-b', 'uid-a']) {
      group('after switching to $next', () {
        test('PM-S3-5-01: late upload is ignored', () async {
          final storage = HeldStorage();
          final profile = profileWith(storage: storage);
          await session.signIn('uid-a');

          final upload = profile.exportAndUploadPdf(planFor('uid-a'));
          await storage.started.future;
          await switchTo(next);
          session.analytics.events.clear();

          storage.response.complete(lateUrl);
          await upload;

          expect(profile.lastUploadedUrl, isNull);
          expect(profile.exportState, isA<ViewStateIdle>());
          expect(session.analytics.events, isEmpty,
              reason: 'no export event for a task of the previous session');
        });

        test('late progress is ignored', () async {
          final storage = HeldStorage();
          final profile = profileWith(storage: storage);
          await session.signIn('uid-a');

          final upload = profile.exportAndUploadPdf(planFor('uid-a'));
          await storage.started.future;
          await switchTo(next);

          storage.progress!(0.8);
          expect(profile.uploadProgress, 0);

          storage.response.complete(null);
          await upload;
          expect(profile.exportState, isA<ViewStateIdle>(),
              reason: 'a late null result is not an error of this session');
        });

        test('late upload error is ignored', () async {
          final storage = HeldStorage();
          final profile = profileWith(storage: storage);
          await session.signIn('uid-a');

          final upload = profile.exportAndUploadPdf(planFor('uid-a'));
          await storage.started.future;
          await switchTo(next);

          storage.response.completeError(Exception('network'));
          await upload;

          expect(profile.exportState, isA<ViewStateIdle>());
          expect(session.crashlytics.errors, isEmpty,
              reason: 'must not be reported under the new session user id');
        });

        test('logout during PDF generation never starts the upload', () async {
          final storage = HeldStorage();
          final report = HeldReport();
          final profile = profileWith(storage: storage, report: report);
          await session.signIn('uid-a');

          final export = profile.exportAndUploadPdf(planFor('uid-a'));
          await report.started.future;
          await switchTo(next);

          report.response.complete(Uint8List.fromList([1, 2, 3]));
          await export;

          expect(storage.uploads, 0);
          expect(profile.exportState, isA<ViewStateIdle>());
        });
      });
    }

    test('a new export in the new session still works', () async {
      final profile = profileWith();
      await session.signIn('uid-a');
      await switchTo('uid-b');

      await profile.exportAndUploadPdf(planFor('uid-b'));

      expect(profile.lastUploadedUrl, contains('uid-b'));
      expect(profile.exportState, isA<ViewStateSuccess<String>>());
    });

    test('progress and completion apply within the same session', () async {
      final storage = HeldStorage();
      final profile = profileWith(storage: storage);
      await session.signIn('uid-a');

      final upload = profile.exportAndUploadPdf(planFor('uid-a'));
      await storage.started.future;
      storage.progress!(0.5);
      expect(profile.uploadProgress, 0.5);

      storage.response.complete(lateUrl);
      await upload;
      expect(profile.lastUploadedUrl, lateUrl);
      expect(profile.exportState, isA<ViewStateSuccess<String>>());
      expect(session.analytics.events, contains('export_report:1:0'),
          reason: 'file size comes from the real PDF bytes');
    });
  });

  group('Analytics contract', () {
    test('generate_meal_plan is skipped without an eating window', () async {
      final plans = plansWith(HeldData());
      await session.signIn('uid-a');

      await plans.generatePlan(uid: 'uid-a', weightKg: 60, age: 30);

      expect(plans.activePlan, isNotNull);
      expect(session.analytics.events.where((e) => e.startsWith('generate')),
          isEmpty,
          reason: 'no invented eating_window_hours');
    });

    test('generate_meal_plan uses real values when the window is known',
        () async {
      final plans = plansWith(HeldData());
      await session.signIn('uid-a');

      await plans.generatePlan(
          uid: 'uid-a', weightKg: 60, age: 70, eatingWindowHours: 12);

      // The fixture plan has one legume meal and no fish.
      expect(session.analytics.events,
          contains('generate_meal_plan:over_65:3:12:0'));
    });

    test('sign-out logs the logout event', () async {
      profileWith();
      await session.signIn('uid-a');

      await session.vm.signOut();

      expect(session.analytics.events, contains('logout'));
    });
  });

  group('MealPlanViewModel', () {
    for (final next in ['uid-b', 'uid-a']) {
      group('after switching to $next', () {
        test('PM-S3-5-02: late saved plans are ignored', () async {
          final data = HeldData();
          final plans = plansWith(data);
          await session.signIn('uid-a');

          final fetch = plans.fetchSavedPlans('uid-a');
          await data.started.future;
          await switchTo(next);

          data.plans!.complete([planFor('uid-a')]);
          await fetch;

          expect(plans.savedPlansState, isA<ViewStateIdle>());
        });

        test('late saved plans error is ignored', () async {
          final data = HeldData();
          final plans = plansWith(data);
          await session.signIn('uid-a');

          final fetch = plans.fetchSavedPlans('uid-a');
          await data.started.future;
          await switchTo(next);

          data.plans!.completeError(Exception('network'));
          await fetch;

          expect(plans.savedPlansState, isA<ViewStateIdle>());
          expect(session.crashlytics.errors, isEmpty);
        });

        test('late generate is ignored', () async {
          final data = HeldData()..recipes = Completer();
          final plans = plansWith(data);
          await session.signIn('uid-a');

          final generate =
              plans.generatePlan(uid: 'uid-a', weightKg: 60, age: 30);
          await data.started.future;
          await switchTo(next);

          data.recipes!.complete(planFor('x').days.first.meals);
          await generate;

          expect(plans.activePlan, isNull);
          expect(plans.currentPlanState, isA<ViewStateIdle>());
        });

        test('late save is ignored', () async {
          final data = HeldData();
          final plans = plansWith(data);
          await session.signIn('uid-a');
          await plans.generatePlan(uid: 'uid-a', weightKg: 60, age: 30);

          final save = plans.saveActivePlan();
          await data.started.future;
          await switchTo(next);

          data.save!.complete('saved-id');

          expect(await save, isFalse);
          expect(plans.activePlan, isNull);
          expect(plans.currentPlanState, isA<ViewStateIdle>());
        });

        test('late submit is ignored', () async {
          final data = HeldData();
          final plans = plansWith(data);
          await session.signIn('uid-a');
          await plans.generatePlan(uid: 'uid-a', weightKg: 60, age: 30);

          final submit = plans.submitForReview('plan-uid-a');
          await data.started.future;
          await switchTo(next);

          data.status!.complete();

          expect(await submit, isFalse);
          expect(plans.activePlan, isNull);
          expect(plans.currentPlanState, isA<ViewStateIdle>());
        });
      });
    }

    test('fetch started in the new session still applies', () async {
      final data = HeldData();
      final plans = plansWith(data);
      await session.signIn('uid-a');
      await switchTo('uid-b');

      final fetch = plans.fetchSavedPlans('uid-b');
      await data.started.future;
      data.plans!.complete([planFor('uid-b')]);
      await fetch;

      expect(plans.savedPlansState, isA<ViewStateSuccess<List<MealPlanModel>>>());
    });
  });
}
