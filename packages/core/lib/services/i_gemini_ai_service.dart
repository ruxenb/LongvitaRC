import '../models/ai_meal_recommendation.dart';

/// Interface for Gemini AI Longevity Nutrition Recommendation Service.
/// Supports Level 2 Structured Output, Fallback, and Zero PII policies.
abstract class IGeminiAiService {
  /// Request a structured longevity meal recommendation based on nutrition goals.
  /// Zero PII: Only nutritional constraints and meal type are sent to Gemini.
  Future<AiMealRecommendation> recommendLongevityMeal({
    required String mealType,
    int? targetCalories,
    List<String>? preferences,
  });

  /// Log user confirmation or edit of the AI-generated recommendation.
  Future<void> logRecommendationAccepted({
    required String recommendationId,
    required bool wasEdited,
  });
}
