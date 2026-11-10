import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';
import 'review_queue_item.dart';

class AdminDashboardMetrics {
  final int activeRecipes;
  final int submittedPlans;
  final int approvedPlans;

  const AdminDashboardMetrics({
    required this.activeRecipes,
    required this.submittedPlans,
    required this.approvedPlans,
  });
}

abstract class IAdminService {
  Stream<List<RecipeModel>> watchRecipes();
  Future<void> saveRecipe(RecipeModel recipe);
  Future<void> setRecipeArchived(String id, bool archived);
  Stream<List<ReviewQueueItem>> watchSubmittedPlans();
  Future<void> reviewPlan(String id, String status, {String? reason});
  Future<AdminDashboardMetrics> loadMetrics();
}

class AdminService implements IAdminService {
  final FirebaseFirestore _firestore;

  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _firestore.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('meal_plans');

  @override
  Stream<List<RecipeModel>> watchRecipes() => _recipes.snapshots().map((event) {
    final rows = event.docs
        .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
        .toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  });

  @override
  Future<void> saveRecipe(RecipeModel recipe) async {
    final ref = recipe.id.isEmpty ? _recipes.doc() : _recipes.doc(recipe.id);
    await ref.set(recipe.toMap(), SetOptions(merge: recipe.id.isNotEmpty));
  }

  @override
  Future<void> setRecipeArchived(String id, bool archived) =>
      _recipes.doc(id).update({'isArchived': archived});

  @override
  Stream<List<ReviewQueueItem>> watchSubmittedPlans() =>
      _plans.where('status', isEqualTo: 'submitted').snapshots().map((event) {
        final rows = event.docs
            .map((doc) => ReviewQueueItem.fromMap(doc.data(), doc.id))
            .toList();
        rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return rows;
      });

  @override
  Future<void> reviewPlan(String id, String status, {String? reason}) =>
      _plans.doc(id).update({
        'status': status,
        'reviewerReason': status == 'rejected' ? reason : null,
      });

  @override
  Future<AdminDashboardMetrics> loadMetrics() async {
    final results = await Future.wait([
      _recipes.count().get(),
      _recipes.where('isArchived', isEqualTo: true).count().get(),
      _plans.where('status', isEqualTo: 'submitted').count().get(),
      _plans.where('status', isEqualTo: 'approved').count().get(),
    ]);
    return AdminDashboardMetrics(
      activeRecipes: (results[0].count ?? 0) - (results[1].count ?? 0),
      submittedPlans: results[2].count ?? 0,
      approvedPlans: results[3].count ?? 0,
    );
  }
}

RecipeModel editableRecipe({
  String id = '',
  required String name,
  required String description,
  required String category,
  required double calories,
  required double protein,
  required String ingredients,
  required String instructions,
  String sourceNote = '',
  bool isArchived = false,
  String? imageUrl,
  List<IngredientModel> existingIngredients = const [],
}) {
  final remainingIngredients = List<IngredientModel>.of(existingIngredients);
  final ingredientRows = ingredients
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .map((value) {
        final index = remainingIngredients.indexWhere(
          (existing) =>
              existing.name.trim().toLowerCase() == value.toLowerCase(),
        );
        if (index >= 0) {
          return remainingIngredients.removeAt(index);
        }
        return IngredientModel(id: '', name: value, amount: 1, unit: 'phần');
      })
      .toList();
  final instructionRows = instructions
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  return RecipeModel(
    id: id,
    name: name.trim(),
    description: description.trim(),
    category: category,
    calories: calories,
    proteinGrams: protein,
    ingredients: ingredientRows,
    instructions: instructionRows,
    sourceNote: sourceNote.trim(),
    isArchived: isArchived,
    imageUrl: imageUrl,
  );
}
