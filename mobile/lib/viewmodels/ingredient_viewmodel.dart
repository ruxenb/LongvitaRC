import 'dart:async';

import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita/firebase/crashlytics_service.dart';
import 'package:longvita_core/models/ingredient_model.dart';
import 'package:longvita_core/models/meal_plan_model.dart';
import 'package:longvita_core/models/user_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita_core/services/data_failure.dart';
import 'package:longvita_core/services/i_data_service.dart';
import 'package:longvita/viewmodels/base_viewmodel.dart';
import 'package:longvita/viewmodels/session_scoped.dart';

/// S4-5: aggregation, validation, Undo and cloud persistence for S07/S08.
class IngredientViewModel extends BaseViewModel implements SessionScoped {
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;
  final IDataService? dataService;

  final SessionEpoch _epoch = SessionEpoch();
  Future<void> _writeTail = Future<void>.value();
  List<IngredientModel> _ingredients = [];
  IngredientModel? _recentlyDeleted;
  int? _recentlyDeletedIndex;
  ViewState<List<IngredientModel>> _state = const ViewStateIdle();
  ViewState<bool> _persistenceState = const ViewStateIdle();
  String? _planId;
  String? _uid;

  IngredientViewModel({
    required this.analytics,
    required this.crashlytics,
    this.dataService,
  });

  ViewState<List<IngredientModel>> get state => _state;
  ViewState<bool> get persistenceState => _persistenceState;
  List<IngredientModel> get ingredients => List.unmodifiable(_ingredients);
  bool get canUndo => _recentlyDeleted != null;
  bool get isSavedPlan => _planId?.isNotEmpty == true;

  @override
  void onSessionStarted(UserModel user) => _uid = user.uid;

  @override
  void clearSession() {
    _epoch.advance();
    // Never let an old session's pending cloud write block the next user.
    // The old write still targets the captured old uid/plan, and its callback
    // is discarded by SessionEpoch when it completes.
    _writeTail = Future<void>.value();
    _uid = null;
    _planId = null;
    _ingredients = [];
    _recentlyDeleted = null;
    _recentlyDeletedIndex = null;
    _state = const ViewStateIdle();
    _persistenceState = const ViewStateIdle();
    notifyListeners();
  }

  /// Aggregation is pure local business logic over Firestore-loaded meals.
  void aggregateFromMealPlan(MealPlanModel plan) {
    _state = const ViewStateLoading('Đang tổng hợp nguyên liệu…');
    notifyListeners();
    try {
      _uid = plan.uid;
      _planId = plan.id;
      final grouped = <String, IngredientModel>{};
      for (final day in plan.days) {
        for (final recipe in day.meals) {
          for (final item in recipe.ingredients) {
            if (item.amount <= 0 || !item.amount.isFinite) continue;
            final key =
                '${item.name.trim().toLowerCase()}|${item.unit.trim().toLowerCase()}';
            final existing = grouped[key];
            if (existing == null) {
              grouped[key] = item.copyWith(id: Uri.encodeComponent(key));
            } else {
              grouped[key] = existing.copyWith(
                amount: existing.amount + item.amount,
              );
            }
          }
        }
      }
      _ingredients = grouped.values.toList();
      _recentlyDeleted = null;
      _recentlyDeletedIndex = null;
      _persistenceState = const ViewStateIdle();
      _updateState();
    } catch (error, trace) {
      _state = ViewStateError('Không thể tổng hợp nguyên liệu.', error);
      notifyListeners();
      unawaited(
        crashlytics.recordError(
          error,
          trace,
          reason: 'Failed to aggregate ingredients',
        ),
      );
    }
  }

  /// A saved empty list remains empty (distinct from no Firestore document).
  Future<void> loadForPlan(MealPlanModel plan) async {
    aggregateFromMealPlan(plan);
    final service = dataService;
    if (plan.id.isEmpty || service == null) return;
    final epoch = _epoch.current;
    _state = const ViewStateLoading('Đang đồng bộ danh sách mua sắm…');
    notifyListeners();
    try {
      final savedItems = await service.getShoppingItems(plan.uid, plan.id);
      if (_epoch.isStale(epoch) || _planId != plan.id) return;
      if (savedItems != null) _ingredients = [...savedItems];
      _persistenceState = const ViewStateIdle();
      _updateState();
    } catch (error, trace) {
      if (_epoch.isStale(epoch) || _planId != plan.id) return;
      _state = ViewStateError(DataFailure.from(error).message, error);
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to load shopping checklist',
      );
    }
  }

  void _updateState() {
    _state = _ingredients.isEmpty
        ? const ViewStateEmpty(message: 'Chưa có nguyên liệu trong danh sách.')
        : ViewStateSuccess(List<IngredientModel>.unmodifiable(_ingredients));
    notifyListeners();
  }

  /// Local edit is synchronous; screens await persistChanges() before
  /// confirming an operation is durable.
  bool updateAmount(String id, double amount) {
    if (!amount.isFinite || amount <= 0) return false;
    final index = _ingredients.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    _ingredients[index] = _ingredients[index].copyWith(amount: amount);
    _updateState();
    unawaited(
      analytics.logEvent('edit_ingredient_quantity', {
        'ingredient_id': id,
        'new_amount': amount,
      }),
    );
    return true;
  }

  void togglePurchased(String id) {
    final index = _ingredients.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = _ingredients[index];
    _ingredients[index] = item.copyWith(isPurchased: !item.isPurchased);
    _updateState();
    unawaited(
      analytics.logToggleShoppingItem(
        ingredientId: id,
        isChecked: !item.isPurchased ? 1 : 0,
      ),
    );
  }

  void deleteIngredient(String id) {
    final index = _ingredients.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _recentlyDeleted = _ingredients[index];
    _recentlyDeletedIndex = index;
    _ingredients.removeAt(index);
    _updateState();
    unawaited(analytics.logEvent('delete_ingredient', {'ingredient_id': id}));
  }

  bool undoDelete() {
    final previous = _recentlyDeleted;
    final index = _recentlyDeletedIndex;
    if (previous == null || index == null) return false;
    _ingredients.insert(index.clamp(0, _ingredients.length), previous);
    _recentlyDeleted = null;
    _recentlyDeletedIndex = null;
    _updateState();
    return true;
  }

  /// Serialise writes so rapid checkbox toggles cannot reorder snapshots.
  Future<bool> persistChanges() async {
    final service = dataService;
    final uid = _uid;
    final planId = _planId;
    if (service == null || uid == null || planId == null || planId.isEmpty) {
      _persistenceState = const ViewStateError(
        'Hãy lưu thực đơn trước khi đồng bộ danh sách mua sắm.',
      );
      notifyListeners();
      return false;
    }
    final epoch = _epoch.current;
    final snapshot = List<IngredientModel>.unmodifiable(_ingredients);
    _persistenceState = const ViewStateLoading('Đang lưu danh sách…');
    notifyListeners();

    final write = _writeTail.then(
      (_) => service.saveShoppingItems(uid, planId, snapshot),
    );
    _writeTail = write.catchError((Object _) {});
    try {
      await write;
      if (_epoch.isStale(epoch) || _planId != planId) return false;
      _persistenceState = const ViewStateSuccess(true);
      notifyListeners();
      return true;
    } catch (error, trace) {
      if (_epoch.isStale(epoch) || _planId != planId) return false;
      _persistenceState = ViewStateError(
        'Chưa xác nhận lưu. ${DataFailure.from(error).message}',
        error,
      );
      notifyListeners();
      await crashlytics.recordError(
        error,
        trace,
        reason: 'Failed to persist shopping checklist',
      );
      return false;
    }
  }
}
