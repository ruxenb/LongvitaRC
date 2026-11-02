import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../models/view_state.dart';
import '../services/i_data_service.dart';
import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import '../firebase/remote_config_service.dart';
import 'base_viewmodel.dart';

class MealPlanViewModel extends BaseViewModel {
  final IDataService dataService;
  final AnalyticsService analytics;
  final CrashlyticsService crashlytics;
  final RemoteConfigService remoteConfig;

  ViewState<MealPlanModel> _currentPlanState = const ViewStateIdle();
  ViewState<List<MealPlanModel>> _savedPlansState = const ViewStateIdle();
  MealPlanModel? _activePlan;

  MealPlanViewModel({
    required this.dataService,
    required this.analytics,
    required this.crashlytics,
    required this.remoteConfig,
  });

  ViewState<MealPlanModel> get currentPlanState => _currentPlanState;
  ViewState<List<MealPlanModel>> get savedPlansState => _savedPlansState;
  MealPlanModel? get activePlan => _activePlan;

  Future<void> generatePlan({
    required String uid,
    required double weightKg,
    required int age,
    int mealsPerDay = 3,
  }) async {
    _currentPlanState = const ViewStateLoading('Đang tính toán dinh dưỡng trường thọ...');
    notifyListeners();

    try {
      final recipes = await dataService.getRecipes();
      if (recipes.isEmpty) {
        // Fallback sample recipes if Firestore is empty initially
        final sampleRecipes = _getInitialLongevityRecipes();
        _activePlan = dataService.generateLongevityMealPlan(
          uid: uid,
          weightKg: weightKg,
          age: age,
          mealsPerDay: mealsPerDay,
          availableRecipes: sampleRecipes,
        );
      } else {
        _activePlan = dataService.generateLongevityMealPlan(
          uid: uid,
          weightKg: weightKg,
          age: age,
          mealsPerDay: mealsPerDay,
          availableRecipes: recipes,
        );
      }

      await analytics.logGenerateMealPlan(
        targetAgeGroup: age >= 65 ? 'over_65' : 'under_65',
        mealsPerDay: mealsPerDay,
        eatingWindowHours: 12,
        fishMealsCount: 2,
      );

      _currentPlanState = ViewStateSuccess(_activePlan!);
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Failed to generate meal plan');
      _currentPlanState = ViewStateError('Không thể tạo thực đơn lúc này. Vui lòng thử lại.', e);
    }
    notifyListeners();
  }

  Future<bool> saveActivePlan() async {
    if (_activePlan == null) return false;

    try {
      final savedId = await dataService.saveMealPlan(_activePlan!);
      _activePlan = _activePlan!.copyWith(id: savedId);

      await analytics.logSaveMealPlan(
        planId: savedId,
        status: _activePlan!.status,
      );

      _currentPlanState = ViewStateSuccess(_activePlan!);
      notifyListeners();
      return true;
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Failed to save meal plan');
      return false;
    }
  }

  /// Cross-Role Flow: Gửi thực đơn cho chuyên gia duyệt (draft -> submitted)
  Future<bool> submitForReview(String planId) async {
    try {
      await dataService.updateMealPlanStatus(planId, 'submitted');
      if (_activePlan != null && _activePlan!.id == planId) {
        _activePlan = _activePlan!.copyWith(status: 'submitted');
        _currentPlanState = ViewStateSuccess(_activePlan!);
      }
      notifyListeners();
      return true;
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Failed to submit plan for review');
      return false;
    }
  }

  Future<void> fetchSavedPlans(String uid) async {
    _savedPlansState = const ViewStateLoading('Đang tải danh sách thực đơn đã lưu...');
    notifyListeners();

    try {
      final plans = await dataService.getUserMealPlans(uid);
      if (plans.isEmpty) {
        _savedPlansState = const ViewStateEmpty(message: 'Bạn chưa lưu thực đơn nào');
      } else {
        _savedPlansState = ViewStateSuccess(plans);
      }
    } catch (e, s) {
      await crashlytics.recordError(e, s, reason: 'Failed to fetch saved plans');
      _savedPlansState = ViewStateError('Không thể tải thực đơn đã lưu', e);
    }
    notifyListeners();
  }

  List<RecipeModel> _getInitialLongevityRecipes() {
    return const [
      RecipeModel(
        id: 'r_fish_1',
        name: 'Cá hồi áp chảo dầu olive và rau bina',
        description: 'Bữa cá giàu Omega-3 theo chuẩn 2 bữa cá/tuần của TS. Longo.',
        category: 'ca',
        proteinGrams: 28.0,
        calories: 380.0,
        ingredients: [],
        instructions: ['Áp chảo cá hồi với 1 thìa dầu olive', 'Trộn rau bina hấp'],
      ),
      RecipeModel(
        id: 'r_legume_1',
        name: 'Súp đậu gà hầm cà chua và hương thảo',
        description: 'Nguồn đạm thực vật trường thọ dồi dào chất xơ.',
        category: 'dau',
        proteinGrams: 18.0,
        calories: 320.0,
        ingredients: [],
        instructions: ['Hầm đậu gà 45 phút', 'Nêm hương thảo và cà chua'],
      ),
      RecipeModel(
        id: 'r_veg_1',
        name: 'Salad cải xoăn hạt óc chó và dầu hạt lanh',
        description: 'Chất chống oxy hóa mạnh mẽ bảo vệ tế bào.',
        category: 'rau_cu',
        proteinGrams: 8.0,
        calories: 220.0,
        ingredients: [],
        instructions: ['Rửa sạch cải xoăn', 'Thêm hạt óc chó giã nhỏ và trộn sốt'],
      ),
    ];
  }
}
