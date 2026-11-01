import '../models/recipe_model.dart';
import '../models/meal_plan_model.dart';
import '../models/announcement_model.dart';

abstract class IDataService {
  Future<List<RecipeModel>> getRecipes({String? category});
  Future<RecipeModel?> getRecipeById(String id);
  Future<List<MealPlanModel>> getUserMealPlans(String uid);
  Stream<List<MealPlanModel>> streamUserMealPlans(String uid);
  Future<String> saveMealPlan(MealPlanModel plan);
  Future<void> updateMealPlanStatus(String planId, String status, {String? reason});
  Stream<List<AnnouncementModel>> streamAnnouncements();

  /// Business logic calculation based on Dr. Valter Longo's Longevity Diet
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  });
}
