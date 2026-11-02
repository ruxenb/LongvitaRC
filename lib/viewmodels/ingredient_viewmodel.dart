import '../models/ingredient_model.dart';
import '../models/meal_plan_model.dart';
import '../models/view_state.dart';
import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import '../models/user_model.dart';
import 'base_viewmodel.dart';
import 'session_scoped.dart';

class IngredientViewModel extends BaseViewModel implements SessionScoped {
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;

  List<IngredientModel> _ingredients = [];
  IngredientModel? _recentlyDeleted;
  int? _recentlyDeletedIndex;
  ViewState<List<IngredientModel>> _state = const ViewStateIdle();

  IngredientViewModel({
    required this.analytics,
    required this.crashlytics,
  });

  ViewState<List<IngredientModel>> get state => _state;
  List<IngredientModel> get ingredients => List.unmodifiable(_ingredients);
  bool get canUndo => _recentlyDeleted != null;

  @override
  void onSessionStarted(UserModel user) {}

  /// Drops the previous user's ingredient list and Undo buffer when the
  /// session ends (CHARLIE-AUTH-01).
  @override
  void clearSession() {
    _ingredients = [];
    _recentlyDeleted = null;
    _recentlyDeletedIndex = null;
    _state = const ViewStateIdle();
    notifyListeners();
  }

  void aggregateFromMealPlan(MealPlanModel plan) {
    _state = const ViewStateLoading('Đang tổng hợp danh sách nguyên liệu...');
    notifyListeners();

    try {
      final map = <String, IngredientModel>{};
      for (final day in plan.days) {
        for (final meal in day.meals) {
          for (final ing in meal.ingredients) {
            final key = '${ing.name.toLowerCase()}_${ing.unit}';
            if (map.containsKey(key)) {
              final existing = map[key]!;
              map[key] = existing.copyWith(
                amount: existing.amount + ing.amount,
              );
            } else {
              map[key] = ing;
            }
          }
        }
      }

      _ingredients = map.values.toList();
      if (_ingredients.isEmpty) {
        _state = const ViewStateEmpty(message: 'Không tìm thấy nguyên liệu nào trong thực đơn');
      } else {
        _state = ViewStateSuccess(_ingredients);
      }
    } catch (e, s) {
      crashlytics.recordError(e, s, reason: 'Failed to aggregate ingredients');
      _state = ViewStateError('Lỗi tổng hợp nguyên liệu', e);
    }
    notifyListeners();
  }

  /// Validation: Số lượng nguyên liệu phải > 0
  bool updateAmount(String id, double newAmount) {
    if (newAmount <= 0) {
      return false;
    }
    final index = _ingredients.indexWhere((element) => element.id == id);
    if (index != -1) {
      _ingredients[index] = _ingredients[index].copyWith(amount: newAmount);
      analytics.logEvent('edit_ingredient_quantity', {'ingredient_id': id, 'new_amount': newAmount});
      _state = ViewStateSuccess(_ingredients);
      notifyListeners();
      return true;
    }
    return false;
  }

  void togglePurchased(String id) {
    final index = _ingredients.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _ingredients[index];
      _ingredients[index] = item.copyWith(isPurchased: !item.isPurchased);
      _state = ViewStateSuccess(_ingredients);
      notifyListeners();
    }
  }

  void deleteIngredient(String id) {
    final index = _ingredients.indexWhere((element) => element.id == id);
    if (index != -1) {
      _recentlyDeleted = _ingredients[index];
      _recentlyDeletedIndex = index;
      _ingredients.removeAt(index);
      analytics.logEvent('delete_ingredient', {'ingredient_id': id});

      if (_ingredients.isEmpty) {
        _state = const ViewStateEmpty(message: 'Đã xóa hết nguyên liệu');
      } else {
        _state = ViewStateSuccess(_ingredients);
      }
      notifyListeners();
    }
  }

  bool undoDelete() {
    if (_recentlyDeleted != null && _recentlyDeletedIndex != null) {
      final insertIndex = _recentlyDeletedIndex!.clamp(0, _ingredients.length);
      _ingredients.insert(insertIndex, _recentlyDeleted!);
      _recentlyDeleted = null;
      _recentlyDeletedIndex = null;
      _state = ViewStateSuccess(_ingredients);
      notifyListeners();
      return true;
    }
    return false;
  }
}
