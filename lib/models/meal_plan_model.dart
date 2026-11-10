import 'recipe_model.dart';

double calculateProteinTarget(double weightKg, int age) =>
    (weightKg * (age >= 65 ? 1.0 : 0.8)).clamp(40.0, 95.0).toDouble();

double calculateProteinTargetForAgeGroup(
  double weightKg, {
  required bool isOlderAdult,
}) => (weightKg * (isOlderAdult ? 1.0 : 0.8)).clamp(40.0, 95.0).toDouble();

class DailyMeal {
  final int dayIndex; // 0 to 6
  final String dayName; // 'Thứ Hai'..'Chủ Nhật'
  final List<RecipeModel> meals;

  const DailyMeal({
    required this.dayIndex,
    required this.dayName,
    required this.meals,
  });

  double get totalProtein => meals.fold(0.0, (acc, r) => acc + r.proteinGrams);
  double get totalCalories => meals.fold(0.0, (acc, r) => acc + r.calories);

  factory DailyMeal.fromMap(Map<String, dynamic> map) {
    return DailyMeal(
      dayIndex: map['dayIndex'] as int? ?? 0,
      dayName: map['dayName'] as String? ?? '',
      meals:
          (map['meals'] as List<dynamic>?)
              ?.map(
                (e) => RecipeModel.fromMap(
                  e as Map<String, dynamic>,
                  e['id'] as String? ?? '',
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayIndex': dayIndex,
      'dayName': dayName,
      'meals': meals.map((m) {
        final map = m.toMap();
        map['id'] = m.id;
        return map;
      }).toList(),
    };
  }
}

class MealPlanModel {
  final String id;
  final String uid;
  final String title;
  final double targetCalories;
  final double targetProteinGrams;

  /// Status for Lab 3 and Cross-role Flow:
  /// 'draft' (default) -> 'submitted' -> 'approved' / 'rejected'
  final String status;
  final String? reviewerReason;
  final List<DailyMeal> days;
  final DateTime createdAt;

  const MealPlanModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.targetCalories,
    required this.targetProteinGrams,
    this.status = 'draft',
    this.reviewerReason,
    required this.days,
    required this.createdAt,
  });

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory MealPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return MealPlanModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      title: map['title'] as String? ?? 'Thực đơn 7 ngày trường thọ',
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 1800.0,
      targetProteinGrams:
          (map['targetProteinGrams'] as num?)?.toDouble() ?? 55.0,
      status: map['status'] as String? ?? 'draft',
      reviewerReason: map['reviewerReason'] as String?,
      days:
          (map['days'] as List<dynamic>?)
              ?.map((d) => DailyMeal.fromMap(d as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
                ? map['createdAt'] as DateTime
                : DateTime.tryParse(map['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'targetCalories': targetCalories,
      'targetProteinGrams': targetProteinGrams,
      'status': status,
      'reviewerReason': reviewerReason,
      'days': days.map((d) => d.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MealPlanModel copyWith({
    String? id,
    String? uid,
    String? title,
    double? targetCalories,
    double? targetProteinGrams,
    String? status,
    String? reviewerReason,
    List<DailyMeal>? days,
    DateTime? createdAt,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      status: status ?? this.status,
      reviewerReason: reviewerReason ?? this.reviewerReason,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
