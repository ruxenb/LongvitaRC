import '../models/announcement_model.dart';
import '../models/ingredient_model.dart';
import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';

/// UI does not call Firebase directly; implement with Firestore or test fakes.
abstract class IDataService {
  Future<List<RecipeModel>> getRecipes({String? category});
  Future<RecipeModel?> getRecipeById(String id);
  Future<List<MealPlanModel>> getUserMealPlans(String uid);
  Stream<List<MealPlanModel>> streamUserMealPlans(String uid);
  Future<String> saveMealPlan(MealPlanModel plan);
  Future<void> updateMealPlanStatus(
    String planId,
    String status, {
    String? reason,
  });
  Stream<List<AnnouncementModel>> streamAnnouncements();
  Future<List<IngredientModel>?> getShoppingItems(String uid, String planId);
  Future<void> saveShoppingItems(
    String uid,
    String planId,
    List<IngredientModel> items,
  );
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  });
}
