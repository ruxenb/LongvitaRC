import 'package:firebase_analytics/firebase_analytics.dart';

/// Service quản lý toàn bộ việc đo lường hành vi người dùng (Firebase Analytics)
/// Tuân thủ nghiêm ngặt chuẩn Handout Appendix A và docs/analytics-plan.md:
/// - Không chứa bất kỳ thông tin định danh cá nhân nào (No PII: không email, phone, tên).
/// - Mọi hàm đều có bọc try/catch để đảm bảo lỗi analytics không bao giờ làm crash ứng dụng.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Gán User ID sau khi đăng nhập thành công để theo dõi phiên (không dùng email)
  Future<void> setUserId(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (_) {}
  }

  /// Hàm phụ trợ gọi logEvent an toàn
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  // ===========================================================================
  // 8 SỰ KIỆN CHUẨN TRONG docs/analytics-plan.md (APPENDIX A)
  // ===========================================================================

  /// 1. Sự kiện standard: Đăng nhập thành công
  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  /// 2. Sự kiện standard: Người dùng chủ động đăng xuất
  Future<void> logLogout() async {
    try {
      await logEvent('logout');
    } catch (_) {}
  }

  /// 3. Sự kiện standard: Tìm kiếm món ăn hoặc chủ đề sách
  Future<void> logSearch({
    required String searchTerm,
    required int resultCount,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {
          'result_count': resultCount,
        },
      );
    } catch (_) {}
  }

  /// 4. Sự kiện custom: Tạo thực đơn 7 ngày tại S03 (Primary Action Flow 1)
  Future<void> logGenerateMealPlan({
    required String targetAgeGroup,
    required int mealsPerDay,
    required int eatingWindowHours,
    required int fishMealsCount,
  }) async {
    await logEvent('generate_meal_plan', {
      'target_age_group': targetAgeGroup, // "under_65" | "over_65"
      'meals_per_day': mealsPerDay,
      'eating_window_hours': eatingWindowHours,
      'fish_meals_count': fishMealsCount,
    });
  }

  /// 5. Sự kiện custom: Xem chi tiết một món ăn tại S05 (Detail Screen Flow 3)
  Future<void> logViewRecipeDetails({
    required String recipeId,
    required int isFishMeal, // 0 hoặc 1
    required int isBookCitation, // 0 hoặc 1
    required int calories,
  }) async {
    await logEvent('view_recipe_details', {
      'recipe_id': recipeId,
      'is_fish_meal': isFishMeal,
      'is_book_citation': isBookCitation,
      'calories': calories,
    });
  }

  /// 6. Sự kiện custom: Đổi một món ăn trong thực đơn tại S06 (Flow 3)
  Future<void> logReplaceMeal({
    required String oldRecipeId,
    required String newRecipeId,
    required int dayIndex, // 1 đến 7
  }) async {
    await logEvent('replace_meal', {
      'old_recipe_id': oldRecipeId,
      'new_recipe_id': newRecipeId,
      'day_index': dayIndex,
    });
  }

  /// 7. Sự kiện custom: Xuất báo cáo PDF và upload lên Firebase Storage (Export/Upload)
  Future<void> logExportReport({
    String topic = 'longevity_meal_plan',
    required int fileSizeKb,
    required int hasShoppingList, // 0 hoặc 1
  }) async {
    await logEvent('export_report', {
      'topic': topic,
      'file_size_kb': fileSizeKb,
      'has_shopping_list': hasShoppingList,
    });
  }

  /// 8. Sự kiện custom: Đánh dấu hoàn thành mua nguyên liệu tại S08 (Flow 2)
  Future<void> logToggleShoppingItem({
    required String ingredientId,
    required int isChecked, // 0 hoặc 1
  }) async {
    await logEvent('toggle_shopping_item', {
      'ingredient_id': ingredientId,
      'is_checked': isChecked,
    });
  }

  /// Sự kiện bổ trợ: Lưu kế hoạch vào Firestore (Flow 1)
  Future<void> logSaveMealPlan({
    required String planId,
    required String status,
  }) async {
    await logEvent('save_meal_plan', {
      'plan_id': planId,
      'status': status,
    });
  }
}
