import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/meal_plan_model.dart';
import '../models/announcement_model.dart';
import 'i_data_service.dart';

class DataService implements IDataService {
  final FirebaseFirestore _firestore;

  DataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection('recipes');

  CollectionReference<Map<String, dynamic>> get _mealPlansRef =>
      _firestore.collection('meal_plans');

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection('announcements');

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) async {
    Query<Map<String, dynamic>> query = _recipesRef;
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<RecipeModel?> getRecipeById(String id) async {
    final doc = await _recipesRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return RecipeModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<List<MealPlanModel>> getUserMealPlans(String uid) async {
    final snapshot = await _mealPlansRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => MealPlanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<MealPlanModel>> streamUserMealPlans(String uid) {
    return _mealPlansRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MealPlanModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<String> saveMealPlan(MealPlanModel plan) async {
    if (plan.id.isNotEmpty && plan.id != 'temp_new') {
      await _mealPlansRef.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
      return plan.id;
    } else {
      final docRef = await _mealPlansRef.add(plan.toMap());
      return docRef.id;
    }
  }

  @override
  Future<void> updateMealPlanStatus(String planId, String status,
      {String? reason}) async {
    final updates = <String, dynamic>{
      'status': status,
    };
    if (reason != null) {
      updates['reviewerReason'] = reason;
    }
    await _mealPlansRef.doc(planId).update(updates);
  }

  @override
  Stream<List<AnnouncementModel>> streamAnnouncements() {
    return _announcementsRef
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  }) {
    // 1. Dr. Valter Longo: 0.8g protein per kg for age <= 65; 1.0g per kg for age > 65
    final proteinFactor = age > 65 ? 1.0 : 0.8;
    final targetProtein = (weightKg * proteinFactor).clamp(40.0, 95.0);
    // Estimated basal calorie requirement based on weight & longevity deficit (-10%)
    final targetCalories = (weightKg * 28.0 * 0.9).clamp(1400.0, 2400.0);

    final dayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];

    final fishRecipes =
        availableRecipes.where((r) => r.category == 'ca').toList();
    final legumeRecipes =
        availableRecipes.where((r) => r.category == 'dau').toList();
    final vegRecipes = availableRecipes
        .where((r) => r.category == 'rau_cu' || r.category == 'ngu_coc')
        .toList();

    final days = <DailyMeal>[];
    int fishAssignedCount = 0;

    for (int i = 0; i < 7; i++) {
      final dailyList = <RecipeModel>[];

      // Assign fish max 2 times a week (Dr. Longo rule: <= 2-3 fish meals/week)
      if (fishAssignedCount < 2 && (i == 1 || i == 4) && fishRecipes.isNotEmpty) {
        dailyList.add(fishRecipes[fishAssignedCount % fishRecipes.length]);
        fishAssignedCount++;
      } else if (legumeRecipes.isNotEmpty) {
        dailyList.add(legumeRecipes[i % legumeRecipes.length]);
      }

      // Add vegetable / wholegrain dishes
      if (vegRecipes.isNotEmpty) {
        dailyList.add(vegRecipes[i % vegRecipes.length]);
      }

      days.add(DailyMeal(
        dayIndex: i,
        dayName: dayNames[i],
        meals: dailyList,
      ));
    }

    return MealPlanModel(
      id: '',
      uid: uid,
      title: 'Thực đơn trường thọ 7 ngày ($age tuổi, ${weightKg.toStringAsFixed(1)} kg)',
      targetCalories: targetCalories,
      targetProteinGrams: targetProtein,
      status: 'draft',
      days: days,
      createdAt: DateTime.now(),
    );
  }
}
