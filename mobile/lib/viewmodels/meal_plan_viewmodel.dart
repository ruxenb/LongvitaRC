import 'dart:async';

import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita/firebase/crashlytics_service.dart';
import 'package:longvita_core/firebase/remote_config_service.dart';
import 'package:longvita_core/models/meal_plan_model.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/models/user_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita_core/services/data_failure.dart';
import 'package:longvita_core/services/i_data_service.dart';
import 'package:longvita/viewmodels/base_viewmodel.dart';
import 'package:longvita/viewmodels/session_scoped.dart';

/// S4-2/3/4/6: domain decisions are here, never in Widget.build().
class MealPlanViewModel extends BaseViewModel implements SessionScoped {
  final IDataService dataService;
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;
  final RemoteConfigService remoteConfig;

  final SessionEpoch _epoch = SessionEpoch();
  int _searchSeq = 0;
  int _alternativeSeq = 0;
  String? _sessionUid;
  MealPlanModel? _activePlan;
  ViewState<MealPlanModel> _currentPlanState = const ViewStateIdle();
  ViewState<List<MealPlanModel>> _savedPlansState = const ViewStateIdle();
  ViewState<List<RecipeModel>> _recipesState = const ViewStateIdle();
  ViewState<List<RecipeModel>> _alternativesState = const ViewStateIdle();
  ViewState<bool> _saveState = const ViewStateIdle();
  ViewState<bool> _replaceState = const ViewStateIdle();
  ViewState<bool> _submitState = const ViewStateIdle();
  StreamSubscription<List<MealPlanModel>>? _reviewSubscription;
  int _reviewListenGeneration = 0;
  String? _reviewSyncError;

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
  ViewState<bool> get submitState => _submitState;
  String? get reviewSyncError => _reviewSyncError;
  MealPlanModel? get activePlan => _activePlan;

  /// S4-3: ReportService can consume the same immutable MealPlanModel.
  MealPlanModel? get reportablePlan => _activePlan;

  @override
  void onSessionStarted(UserModel user) {
    if (_sessionUid != user.uid) _stopReviewSync();
    _sessionUid = user.uid;
    if (_activePlan?.uid == user.uid && _activePlan!.id.isNotEmpty) {
      _watchSelectedPlan();
    }
  }

  void _stopReviewSync() {
    _reviewListenGeneration++;
    final old = _reviewSubscription;
    _reviewSubscription = null;
    if (old != null) unawaited(old.cancel());
    _reviewSyncError = null;
  }

  /// HD-05: follow only the current user's saved plan. Update review status,
  /// never replace a locally edited draft with a stale Firestore cache event.
  void _watchSelectedPlan() {
    _stopReviewSync();
    final plan = _activePlan;
    final uid = _sessionUid;
    if (uid == null || plan == null || plan.id.isEmpty || plan.uid != uid) {
      return;
    }
    final epoch = _epoch.current;
    final generation = _reviewListenGeneration;
    try {
      _reviewSubscription = dataService
          .streamUserMealPlans(uid)
          .listen(
            (plans) {
              if (_epoch.isStale(epoch) ||
                  generation != _reviewListenGeneration) {
                return;
              }
              final current = _activePlan;
              if (current == null ||
                  current.id != plan.id ||
                  current.uid != uid) {
                return;
              }
              for (final remote in plans) {
                if (remote.id != current.id || remote.uid != uid) continue;
                if (current.status == 'submitted' && remote.status == 'draft') {
                  return;
                }
                if ((current.isApproved || current.isRejected) &&
                    remote.status != current.status) {
                  return;
                }
                if (current.status != remote.status ||
                    current.reviewerReason != remote.reviewerReason) {
                  final updated = current.copyWith(
                    status: remote.status,
                    reviewerReason: remote.reviewerReason,
                  );
                  _activePlan = updated;
                  _currentPlanState = ViewStateSuccess(updated);
                  _reviewSyncError = null;
                  notifyListeners();
                } else if (_reviewSyncError != null) {
                  _reviewSyncError = null;
                  notifyListeners();
                }
                return;
              }
            },
            onError: (Object error, StackTrace trace) {
              if (_epoch.isStale(epoch) ||
                  generation != _reviewListenGeneration) {
                return;
              }
              _reviewSyncError =
                  'Không thể đồng bộ trạng thái xét duyệt. '
                  '${DataFailure.from(error).message}';
              notifyListeners();
              unawaited(
                crashlytics.recordError(
                  error,
                  trace,
                  reason: 'Failed to watch plan review',
                ),
              );
            },
          );
    } catch (error) {
      _reviewSyncError = DataFailure.from(error).message;
      notifyListeners();
    }
  }

  void retryReviewSync() {
    _watchSelectedPlan();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopReviewSync();
    super.dispose();
  }

  @override
  void clearSession() {
    _epoch.advance();
    _stopReviewSync();
    _searchSeq++;
    _alternativeSeq++;
    _sessionUid = null;
    _activePlan = null;
    _currentPlanState = const ViewStateIdle();
    _savedPlansState = const ViewStateIdle();
    _recipesState = const ViewStateIdle();
    _alternativesState = const ViewStateIdle();
    _saveState = const ViewStateIdle();
    _replaceState = const ViewStateIdle();
    _submitState = const ViewStateIdle();
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
    _submitState = const ViewStateIdle();
    notifyListeners();
    _watchSelectedPlan();
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

    _stopReviewSync();
    _activePlan = null;
    _currentPlanState = const ViewStateLoading(
      'Đang tải công thức từ Firestore và lập thực đơn 7 ngày…',
    );
    _saveState = const ViewStateIdle();
    notifyListeners();
    try {
      final recipes = await dataService.getRecipes();
      if (_epoch.isStale(epoch)) return;
      if (recipes.isEmpty) {
        _currentPlanState = const ViewStateEmpty(
          message: 'Firestore chưa có công thức. Nhờ nhóm bổ sung công thức rồi thử lại.',
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
    if (plan == null ||
        !plan.isDraft ||
        (_sessionUid != null && plan.uid != _sessionUid)) {
      _saveState = const ViewStateError('Chưa có thực đơn hợp lệ để lưu.');
      notifyListeners();
      return false;
    }
    final epoch = _epoch.current;
    _saveState = const ViewStateLoading('Đang lưu thực đơn trên Firestore…');
    notifyListeners();
    try {
      final id = await dataService.saveMealPlan(plan);
      if (_epoch.isStale(epoch)) return false;
      final saved = plan.copyWith(id: id);
      _activePlan = saved;
      _currentPlanState = ViewStateSuccess(saved);
      _saveState = const ViewStateSuccess(true);
      _watchSelectedPlan();
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
    _savedPlansState = const ViewStateLoading('Đang tải thực đơn đã lưu…');
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
    final seq = ++_searchSeq;
    _recipesState = const ViewStateLoading('Đang tra cứu công thức…');
    notifyListeners();
    try {
      final all = await dataService.getRecipes();
      if (_epoch.isStale(epoch) || seq != _searchSeq) return;
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
      if (_epoch.isStale(epoch) || seq != _searchSeq) return;
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
    final seq = ++_alternativeSeq;
    _alternativesState = const ViewStateLoading('Đang tìm món thay thế…');
    _replaceState = const ViewStateIdle();
    notifyListeners();
    try {
      final all = await dataService.getRecipes();
      if (_epoch.isStale(epoch) || seq != _alternativeSeq) return;
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
              message: 'Chưa có món thay thế phù hợp. Hãy điều chỉnh sở thích hoặc bổ sung công thức.',
            )
          : ViewStateSuccess(candidates);
      notifyListeners();
    } catch (error, trace) {
      if (_epoch.isStale(epoch) || seq != _alternativeSeq) return;
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
    _replaceState = const ViewStateLoading('Đang cập nhật thực đơn…');
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
      final failure = DataFailure.from(error);
      _replaceState = ViewStateError(
        failure.kind == DataFailureKind.offline
            ? 'Chưa cập nhật được món trên màn hình. Lệnh ghi có thể được đồng bộ sau khi có mạng; hãy tải lại thực đơn để kiểm tra. ${failure.message}'
            : 'Chưa cập nhật được món; món gốc vẫn được giữ. ${failure.message}',
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
    final active = _activePlan;
    if (active == null ||
        active.id.isEmpty ||
        active.id != planId ||
        _sessionUid == null ||
        active.uid != _sessionUid ||
        !active.isDraft ||
        active.days.length != 7) {
      _submitState = const ViewStateError(
        'Chỉ gửi được thực đơn 7 ngày đã lưu, còn là bản nháp và thuộc tài khoản của bạn.',
      );
      notifyListeners();
      return false;
    }
    if (_submitState is ViewStateLoading<bool>) return false;
    final epoch = _epoch.current;
    _submitState = const ViewStateLoading('Đang gửi thực đơn xét duyệt…');
    notifyListeners();
    try {
      await dataService.updateMealPlanStatus(planId, 'submitted');
      if (_epoch.isStale(epoch) || _activePlan?.id != planId) return false;
      _activePlan = _activePlan!.copyWith(status: 'submitted');
      _currentPlanState = ViewStateSuccess(_activePlan!);
      _submitState = const ViewStateSuccess(true);
      notifyListeners();
      return true;
    } catch (error, trace) {
      if (_epoch.isStale(epoch)) return false;
      _submitState = ViewStateError(DataFailure.from(error).message, error);
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to submit plan for review',
      );
      return false;
    }
  }
}
