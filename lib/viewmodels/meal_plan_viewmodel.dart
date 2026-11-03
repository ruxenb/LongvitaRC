import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../models/view_state.dart';
import '../services/data_failure.dart';
import '../services/i_data_service.dart';
import 'base_viewmodel.dart';
import 'session_scoped.dart';

/// S4-2/3/4/6: domain decisions are here, never in Widget.build().
class MealPlanViewModel extends BaseViewModel implements SessionScoped {
  final IDataService dataService;
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;
  final RemoteConfigService remoteConfig;

  final SessionEpoch _epoch = SessionEpoch();
  String? _sessionUid;
  MealPlanModel? _activePlan;
  ViewState<MealPlanModel> _currentPlanState = const ViewStateIdle();
  ViewState<List<MealPlanModel>> _savedPlansState = const ViewStateIdle();
  ViewState<List<RecipeModel>> _recipesState = const ViewStateIdle();
  ViewState<List<RecipeModel>> _alternativesState = const ViewStateIdle();
  ViewState<bool> _saveState = const ViewStateIdle();
  ViewState<bool> _replaceState = const ViewStateIdle();

  MealPlanViewModel({
    required this.dataService,
    required this.analytics,
    required this.crashlytics,
    required this.remoteConfig,
  });

  ViewState<MealPlanModel> get currentPlanState => _currentPlanState;
  ViewState<List<MealPlanModel>> get savedPlansState => _savedPlansState;
  ViewState<List<RecipeModel>> get recipesState => _recipesState;
  ViewState<List<RecipeModel>> get alternativesState => _alternativesState;
  ViewState<bool> get saveState => _saveState;
  ViewState<bool> get replaceState => _replaceState;
  MealPlanModel? get activePlan => _activePlan;

  /// S4-3: ReportService can consume the same immutable MealPlanModel.
  MealPlanModel? get reportablePlan => _activePlan;

  @override
  void onSessionStarted(UserModel user) => _sessionUid = user.uid;

  @override
  void clearSession() {
    _epoch.advance();
    _sessionUid = null;
    _activePlan = null;
    _currentPlanState = const ViewStateIdle();
    _savedPlansState = const ViewStateIdle();
    _recipesState = const ViewStateIdle();
    _alternativesState = const ViewStateIdle();
    _saveState = const ViewStateIdle();
    _replaceState = const ViewStateIdle();
    notifyListeners();
  }

  void selectSavedPlan(MealPlanModel plan) {
    if (_sessionUid != null && plan.uid != _sessionUid) {
      _currentPlanState = const ViewStateError(
        'Không thể mở kế hoạch của tài khoản khác.',
      );
      notifyListeners();
      return;
    }
    _activePlan = plan;
    _currentPlanState = ViewStateSuccess(plan);
    _saveState = const ViewStateIdle();
    _replaceState = const ViewStateIdle();
    notifyListeners();
  }

  Future<void> generatePlan({
    required String uid,
    required double weightKg,
    required int age,
    int mealsPerDay = 3,
    int? eatingWindowHours,
  }) async {
    final epoch = _epoch.current;
    if ((_sessionUid != null && _sessionUid != uid) ||
        !weightKg.isFinite ||
        weightKg < 25 ||
        weightKg > 300 ||
        age < 18 ||
        age > 120 ||
        mealsPerDay < 1 ||
        mealsPerDay > 5 ||
        (eatingWindowHours != null &&
            (eatingWindowHours < 1 || eatingWindowHours > 24))) {
      _currentPlanState = const ViewStateError(
        'Thông tin chưa hợp lệ. Hãy kiểm tra tuổi, cân nặng và số bữa.',
      );
      notifyListeners();
      return;
    }

    _activePlan = null;
    _currentPlanState = const ViewStateLoading(
      'Đang tải công thức từ Firestore và lập thực đơn 7 ngày...',
    );
    _saveState = const ViewStateIdle();
    notifyListeners();
    try {
      final recipes = await dataService.getRecipes();
      if (_epoch.isStale(epoch)) return;
      if (recipes.isEmpty) {
        _currentPlanState = const ViewStateEmpty(
          message: 'Firestore chưa có công thức. Nhờ nhóm bổ sung recipes rồi thử lại.',
        );
        notifyListeners();
        return;
      }
      final generated = dataService.generateLongevityMealPlan(
        uid: uid,
        weightKg: weightKg,
        age: age,
        mealsPerDay: mealsPerDay,
        availableRecipes: recipes,
      );
      // No fabricated eating window is sent to Analytics.
      if (eatingWindowHours != null) {
        await analytics.logGenerateMealPlan(
          targetAgeGroup: age >= 65 ? 'over_65' : 'under_65',
          mealsPerDay: mealsPerDay,
          eatingWindowHours: eatingWindowHours,
          fishMealsCount: generated.days
              .expand((day) => day.meals)
              .where((r) => r.category == 'ca')
              .length,
        );
      }
      if (_epoch.isStale(epoch)) return;
      _activePlan = generated;
      _currentPlanState = ViewStateSuccess(generated);
      notifyListeners();
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return;
      _currentPlanState = ViewStateError(
        DataFailure.from(error).message,
        error,
      );
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to generate meal plan',
      );
    }
  }

  Future<bool> saveActivePlan() async {
    final plan = _activePlan;
    if (plan == null || (_sessionUid != null && plan.uid != _sessionUid)) {
      _saveState = const ViewStateError('Chưa có thực đơn hợp lệ để lưu.');
      notifyListeners();
      return false;
    }
    final epoch = _epoch.current;
    _saveState = const ViewStateLoading('Đang lưu thực đơn trên Firestore...');
    notifyListeners();
    try {
      final id = await dataService.saveMealPlan(plan);
      if (_epoch.isStale(epoch)) return false;
      final saved = plan.copyWith(id: id);
      _activePlan = saved;
      _currentPlanState = ViewStateSuccess(saved);
      _saveState = const ViewStateSuccess(true);
      notifyListeners();
      await analytics.logSaveMealPlan(planId: id, status: plan.status);
      return !_epoch.isStale(epoch);
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return false;
      _saveState = ViewStateError(DataFailure.from(error).message, error);
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to save meal plan',
      );
      return false;
    }
  }

  Future<void> fetchSavedPlans(String uid) async {
    final epoch = _epoch.current;
    _savedPlansState = const ViewStateLoading('Đang tải thực đơn đã lưu...');
    notifyListeners();
    try {
      final plans = await dataService.getUserMealPlans(uid);
      if (_epoch.isStale(epoch)) return;
      _savedPlansState = plans.isEmpty
          ? const ViewStateEmpty(message: 'Bạn chưa lưu thực đơn nào.')
          : ViewStateSuccess(plans);
      notifyListeners();
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return;
      _savedPlansState = ViewStateError(DataFailure.from(error).message, error);
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to fetch saved plans',
      );
    }
  }

  /// S05/09: query and text matching are ViewModel concerns.
  Future<void> searchRecipes(String term) async {
    final epoch = _epoch.current;
    _recipesState = const ViewStateLoading('Đang tra cứu công thức...');
    notifyListeners();
    try {
      final all = await dataService.getRecipes();
      if (_epoch.isStale(epoch)) return;
      final needle = term.trim().toLowerCase();
      final result = needle.isEmpty
          ? all
          : all
                .where(
                  (recipe) =>
                      recipe.name.toLowerCase().contains(needle) ||
                      recipe.description.toLowerCase().contains(needle) ||
                      recipe.category.toLowerCase().contains(needle),
                )
                .toList();
      _recipesState = result.isEmpty
          ? const ViewStateEmpty(message: 'Không tìm thấy món phù hợp.')
          : ViewStateSuccess(result);
      notifyListeners();
      if (needle.isNotEmpty) {
        await analytics.logSearch(
          searchTerm: needle,
          resultCount: result.length,
        );
      }
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return;
      _recipesState = ViewStateError(DataFailure.from(error).message, error);
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to query recipes',
      );
    }
  }

  /// S06: pick alternatives with similar nutrition and never offer same ID.
  Future<void> loadAlternatives(RecipeModel recipe) async {
    final epoch = _epoch.current;
    _alternativesState = const ViewStateLoading('Đang tìm món thay thế...');
    _replaceState = const ViewStateIdle();
    notifyListeners();
    try {
      final all = await dataService.getRecipes();
      if (_epoch.isStale(epoch)) return;
      final filtered = all
          .where(
            (candidate) =>
                candidate.id != recipe.id &&
                (candidate.calories - recipe.calories).abs() <=
                    (recipe.calories * 0.5).clamp(100.0, 500.0) &&
                (candidate.proteinGrams - recipe.proteinGrams).abs() <=
                    (recipe.proteinGrams * 0.6).clamp(8.0, 30.0),
          )
          .toList();
      filtered.sort((a, b) {
        final scoreA =
            (a.calories - recipe.calories).abs() +
            (a.proteinGrams - recipe.proteinGrams).abs() * 10;
        final scoreB =
            (b.calories - recipe.calories).abs() +
            (b.proteinGrams - recipe.proteinGrams).abs() * 10;
        return scoreA.compareTo(scoreB);
      });
      final candidates = filtered
          .take(remoteConfig.maxRecommendations.clamp(1, 20))
          .toList(growable: false);
      _alternativesState = candidates.isEmpty
          ? const ViewStateEmpty(
              message: 'Chưa có món thay thế phù hợp. Hãy điều chỉnh sở thích hoặc bổ sung recipes.',
            )
          : ViewStateSuccess(candidates);
      notifyListeners();
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return;
      _alternativesState = ViewStateError(
        DataFailure.from(error).message,
        error,
      );
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to fetch alternatives',
      );
    }
  }

  /// Keep old meal until cloud write succeeds; on error UI shows Retry.
  Future<bool> replaceMeal({
    required int dayIndex,
    required String originalId,
    required RecipeModel replacement,
  }) async {
    final plan = _activePlan;
    if (plan == null ||
        !plan.isDraft ||
        dayIndex < 0 ||
        dayIndex >= plan.days.length ||
        (_sessionUid != null && plan.uid != _sessionUid)) {
      _replaceState = const ViewStateError(
        'Không thể đổi món ở thực đơn này. Hãy mở bản nháp hợp lệ.',
      );
      notifyListeners();
      return false;
    }
    final day = plan.days[dayIndex];
    final slot = day.meals.indexWhere((recipe) => recipe.id == originalId);
    if (slot < 0 || replacement.id == originalId) {
      _replaceState = const ViewStateError('Món ăn đã thay đổi. Hãy tải lại.');
      notifyListeners();
      return false;
    }
    // Dietary selection rule: do not increase fish meals beyond two/week.
    final fishCount = plan.days
        .expand((d) => d.meals)
        .where((recipe) => recipe.category == 'ca')
        .length;
    if (replacement.category == 'ca' &&
        day.meals[slot].category != 'ca' &&
        fishCount >= 2) {
      _replaceState = const ViewStateError(
        'Thực đơn đã có hai bữa cá. Hãy chọn món khác.',
      );
      notifyListeners();
      return false;
    }
    final changedMeals = [...day.meals]..[slot] = replacement;
    final updatedDays = [...plan.days]
      ..[dayIndex] = DailyMeal(
        dayIndex: day.dayIndex,
        dayName: day.dayName,
        meals: changedMeals,
      );
    final changed = plan.copyWith(days: updatedDays);
    final epoch = _epoch.current;
    _replaceState = const ViewStateLoading('Đang cập nhật thực đơn...');
    notifyListeners();
    try {
      if (plan.id.isNotEmpty) {
        await dataService.saveMealPlan(changed);
        if (_epoch.isStale(epoch)) return false;
      }
      _activePlan = changed;
      _currentPlanState = ViewStateSuccess(changed);
      _replaceState = const ViewStateSuccess(true);
      notifyListeners();
      try {
        await analytics.logReplaceMeal(
          oldRecipeId: originalId,
          newRecipeId: replacement.id,
          dayIndex: dayIndex + 1,
        );
      } catch (_) {
        /* Analytics must never roll back a successful write. */
      }
      return !_epoch.isStale(epoch);
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return false;
      _replaceState = ViewStateError(
        'Chưa cập nhật được món; món gốc vẫn được giữ. ${DataFailure.from(error).message}',
        error,
      );
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to replace meal',
      );
      return false;
    }
  }

  Future<bool> submitForReview(String planId) async {
    final epoch = _epoch.current;
    try {
      await dataService.updateMealPlanStatus(planId, 'submitted');
      if (_epoch.isStale(epoch)) return false;
      if (_activePlan?.id == planId) {
        _activePlan = _activePlan!.copyWith(status: 'submitted');
        _currentPlanState = ViewStateSuccess(_activePlan!);
        notifyListeners();
      }
      return true;
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return false;
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to submit plan for review',
      );
      return false;
    }
  }
}
