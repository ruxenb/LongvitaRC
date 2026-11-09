import '../models/meal_plan_model.dart';

/// One queue document. Bad owner-supplied data must not break other rows.
class ReviewQueueItem {
  final String id;
  final String title;
  final String uid;
  final DateTime createdAt;
  final MealPlanModel? plan;

  const ReviewQueueItem._({
    required this.id,
    required this.title,
    required this.uid,
    required this.createdAt,
    required this.plan,
  });

  bool get canApprove => plan != null;

  factory ReviewQueueItem.fromMap(Map<String, dynamic> data, String id) {
    MealPlanModel? plan;
    try {
      final parsed = MealPlanModel.fromMap(data, id);
      final indices = parsed.days.map((day) => day.dayIndex).toSet();
      if (parsed.isSubmitted &&
          parsed.days.length == 7 &&
          indices.length == 7 &&
          indices.every((index) => index >= 0 && index < 7) &&
          parsed.days.every((day) => day.meals.isNotEmpty)) {
        plan = parsed;
      }
    } on TypeError {
      // A single malformed nested day, recipe or ingredient stays visible as
      // an invalid row, without throwing away the rest of the query snapshot.
    } on FormatException {
      // Keep the same recovery path for invalid serialized values.
    }
    return ReviewQueueItem._(
      id: id,
      title: data['title'] is String ? data['title'] as String : 'Thực đơn lỗi',
      uid: data['uid'] is String ? data['uid'] as String : 'Không xác định',
      createdAt: plan?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      plan: plan,
    );
  }
}
