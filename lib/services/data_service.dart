import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement_model.dart';
import '../models/ingredient_model.dart';
import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import 'data_failure.dart';
import 'i_data_service.dart';

/// Business data comes from Cloud Firestore. Empty catalogue is an explicit
/// state, never a pretext for showing fabricated sample recipes.
class DataService implements IDataService {
  final FirebaseFirestore _firestore;
  DataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('meal_plans');
  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection('announcements');
  DocumentReference<Map<String, dynamic>> _shoppingRef(
    String uid,
    String planId,
  ) => _firestore
      .collection('shopping_lists')
      .doc(uid)
      .collection('plans')
      .doc(planId);

  @override
  Future<List<RecipeModel>> getRecipes({String? category}) async {
    try {
      Query<Map<String, dynamic>> query = _recipesRef;
      if (category != null && category.trim().isNotEmpty) {
        query = query.where('category', isEqualTo: category.trim());
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
          .toList(growable: false);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final doc = await _recipesRef.doc(id).get();
      final data = doc.data();
      return data == null ? null : RecipeModel.fromMap(data, doc.id);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  List<MealPlanModel> _mapSortedPlans(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final plans = snapshot.docs
        .map((doc) => MealPlanModel.fromMap(doc.data(), doc.id))
        .toList();
    // Client sort avoids an index failure for uid + createdAt in small lab data.
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
  }

  @override
  Future<List<MealPlanModel>> getUserMealPlans(String uid) async {
    try {
      final snapshot = await _plansRef.where('uid', isEqualTo: uid).get();
      return _mapSortedPlans(snapshot);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Stream<List<MealPlanModel>> streamUserMealPlans(String uid) async* {
    try {
      await for (final snapshot
          in _plansRef.where('uid', isEqualTo: uid).snapshots()) {
        yield _mapSortedPlans(snapshot);
      }
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<String> saveMealPlan(MealPlanModel plan) async {
    if (plan.uid.isEmpty || plan.days.length != 7) {
      throw const DataFailure(
        DataFailureKind.invalid,
        'Thực đơn cần đủ 7 ngày và tài khoản hợp lệ.',
      );
    }
    try {
      if (plan.id.isNotEmpty && plan.id != 'temp_new') {
        await _plansRef.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
        return plan.id;
      }
      if (plan.status != 'draft') {
        throw const DataFailure(
          DataFailureKind.invalid,
          'Thực đơn mới phải ở trạng thái bản nháp.',
        );
      }
      final doc = await _plansRef.add(plan.toMap());
      return doc.id;
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<void> updateMealPlanStatus(
    String planId,
    String status, {
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (reason != null) updates['reviewerReason'] = reason;
      await _plansRef.doc(planId).update(updates);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Stream<List<AnnouncementModel>> streamAnnouncements() async* {
    try {
      await for (final snapshot
          in _announcementsRef
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots()) {
        yield snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .toList(growable: false);
      }
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<List<IngredientModel>?> getShoppingItems(
    String uid,
    String planId,
  ) async {
    if (uid.isEmpty || planId.isEmpty) {
      throw const DataFailure(
        DataFailureKind.invalid,
        'Vui lòng lưu thực đơn trước khi dùng danh sách mua sắm.',
      );
    }
    try {
      final doc = await _shoppingRef(uid, planId).get();
      final data = doc.data();
      if (data == null) return null;
      final rows = data['items'] as List<dynamic>? ?? const [];
      return rows
          .map(
            (row) =>
                IngredientModel.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  @override
  Future<void> saveShoppingItems(
    String uid,
    String planId,
    List<IngredientModel> items,
  ) async {
    if (uid.isEmpty ||
        planId.isEmpty ||
        items.any((item) => item.amount <= 0 || !item.amount.isFinite)) {
      throw const DataFailure(
        DataFailureKind.invalid,
        'Danh sách mua sắm chưa hợp lệ. Kiểm tra lại số lượng.',
      );
    }
    try {
      await _shoppingRef(uid, planId).set({
        'uid': uid,
        'planId': planId,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (error) {
      throw DataFailure.from(error);
    }
  }

  /// Illustrative 7-day selection from real Firestore recipes. Numerical
  /// nutrition targets are estimates; not personalised medical advice.
  @override
  MealPlanModel generateLongevityMealPlan({
    required String uid,
    required double weightKg,
    required int age,
    required int mealsPerDay,
    required List<RecipeModel> availableRecipes,
  }) {
    if (uid.isEmpty ||
        !weightKg.isFinite ||
        weightKg < 25 ||
        weightKg > 300 ||
        age < 18 ||
        age > 120 ||
        mealsPerDay < 1 ||
        mealsPerDay > 5) {
      throw const DataFailure(
        DataFailureKind.invalid,
        'Tuổi, cân nặng hoặc số bữa chưa hợp lệ.',
      );
    }
    final recipes = availableRecipes
        .where((recipe) => recipe.id.isNotEmpty && recipe.name.isNotEmpty)
        .toList(growable: false);
    if (recipes.isEmpty) {
      throw const DataFailure(
        DataFailureKind.unavailable,
        'Firestore chưa có công thức món ăn để tạo thực đơn.',
      );
    }
    final nonFish = recipes.where((r) => r.category != 'ca').toList();
    if (nonFish.isEmpty) {
      throw const DataFailure(
        DataFailureKind.unavailable,
        'Cần bổ sung ít nhất một món không phải cá trong Firestore.',
      );
    }
    const names = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    var fishMeals = 0;
    final days = <DailyMeal>[];
    for (var day = 0; day < 7; day++) {
      final chosen = <RecipeModel>[];
      for (var meal = 0; meal < mealsPerDay; meal++) {
        final offerFish = fishMeals < 2 && (day == 1 || day == 4) && meal == 0;
        final candidates = offerFish ? recipes : nonFish;
        final unused = candidates
            .where((r) => !chosen.any((other) => other.id == r.id))
            .toList();
        final pool = unused.isEmpty ? candidates : unused;
        final selected = pool[(day * mealsPerDay + meal) % pool.length];
        chosen.add(selected);
        if (selected.category == 'ca') fishMeals++;
      }
      days.add(DailyMeal(dayIndex: day, dayName: names[day], meals: chosen));
    }
    final protein = (weightKg * (age >= 65 ? 1.0 : 0.8))
        .clamp(40.0, 95.0)
        .toDouble();
    final calories = (weightKg * 28 * 0.9).clamp(1400.0, 2400.0).toDouble();
    return MealPlanModel(
      id: '',
      uid: uid,
      title: 'Thực đơn 7 ngày ($age tuổi, ${weightKg.toStringAsFixed(1)} kg)',
      targetCalories: calories,
      targetProteinGrams: protein,
      days: days,
      createdAt: DateTime.now(),
    );
  }
}
