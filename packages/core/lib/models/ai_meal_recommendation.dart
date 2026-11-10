import 'dart:convert';
import 'package:longvita_core/models/ingredient_model.dart';
import 'package:longvita_core/models/recipe_model.dart';

/// Level 2 Structured Output Model for Gemini AI Longevity Nutrition Recommendation.
/// Corresponds to PRM393 Final Assignment Section 8 requirements.
class AiMealRecommendation {
  final String id;
  final String mealName;
  final String description;
  final int calories;
  final double proteinGrams;
  final List<String> longevityNutrients;
  final String longevityReason;
  final List<String> ingredients;
  final int preparationMinutes;
  final bool isAiGenerated;
  final bool isEditedByUser;
  final double confidenceScore;
  final String? sourceNote;

  const AiMealRecommendation({
    required this.id,
    required this.mealName,
    required this.description,
    required this.calories,
    required this.proteinGrams,
    required this.longevityNutrients,
    required this.longevityReason,
    required this.ingredients,
    this.preparationMinutes = 20,
    this.isAiGenerated = true,
    this.isEditedByUser = false,
    this.confidenceScore = 0.95,
    this.sourceNote,
  });

  /// Deterministic fallback recommendation when Gemini is unavailable,
  /// quota is exceeded, or offline. Adheres to Valter Longo Longevity diet.
  factory AiMealRecommendation.fallback({
    String mealType = 'lunch',
    String? reason,
  }) {
    final type = mealType.toLowerCase();
    if (type.contains('breakfast') || type.contains('sang') || type.contains('sáng')) {
      return const AiMealRecommendation(
        id: 'fallback-breakfast',
        mealName: 'Cháo yến mạch hạt chia & quả mọng',
        description: 'Cháo yến mạch nguyên cám nấu cùng sữa hạnh nhân, rắc hạt chia và việt quất tươi.',
        calories: 320,
        proteinGrams: 9.5,
        longevityNutrients: ['Beta-glucan', 'Chất xơ hòa tan', 'Anthocyanin', 'Omega-3'],
        longevityReason: 'Kích hoạt autophagy buổi sáng, giữ đường huyết ổn định theo TS. Valter Longo.',
        ingredients: ['Yến mạch nguyên hạt 50g', 'Hạt chia 15g', 'Việt quất 40g', 'Sữa hạnh nhân không đường 150ml'],
        preparationMinutes: 10,
        isAiGenerated: false,
        isEditedByUser: false,
        confidenceScore: 1.0,
        sourceNote: 'Fallback nội bộ (Valter Longo Diet Standard)',
      );
    } else if (type.contains('dinner') || type.contains('toi') || type.contains('tối')) {
      return const AiMealRecommendation(
        id: 'fallback-dinner',
        mealName: 'Salad đậu gà Địa Trung Hải sốt dầu ô liu',
        description: 'Đậu gà hấp trộn rau bina, cà chua bi, dưa chuột và dầu ô liu nguyên chất ép lạnh.',
        calories: 380,
        proteinGrams: 14.0,
        longevityNutrients: ['Polyphenol', 'Folate', 'Chất xơ prebiotic', 'Chất béo đơn bất bão hòa'],
        longevityReason: 'Protein thực vật sạch, giảm gánh nặng chuyển hóa vào buổi tối, bảo vệ tim mạch.',
        ingredients: ['Đậu gà luộc 120g', 'Rau bina non 60g', 'Cà chua bi 50g', 'Dầu ô liu extra virgin 15ml'],
        preparationMinutes: 15,
        isAiGenerated: false,
        isEditedByUser: false,
        confidenceScore: 1.0,
        sourceNote: 'Fallback nội bộ (Valter Longo Diet Standard)',
      );
    } else {
      return const AiMealRecommendation(
        id: 'fallback-lunch',
        mealName: 'Súp đậu Garbanzo và rau củ trường thọ',
        description: 'Súp hầm đậu Garbanzo, cà rốt, bí ngòi và thảo mộc Địa Trung Hải, ăn kèm hạt gai dầu.',
        calories: 420,
        proteinGrams: 16.5,
        longevityNutrients: ['Polyphenols', 'Lignans', 'Magie', 'Chất xơ'],
        longevityReason: 'Công thức trường thọ vùng Sardinia: tối ưu hóa tỷ lệ IGF-1 và kéo dài tuổi thọ tế bào.',
        ingredients: ['Đậu Garbanzo 150g', 'Cà rốt 50g', 'Bí ngòi 50g', 'Hạt gai dầu 10g', 'Dầu ô liu 10ml'],
        preparationMinutes: 25,
        isAiGenerated: false,
        isEditedByUser: false,
        confidenceScore: 1.0,
        sourceNote: 'Fallback nội bộ (Valter Longo Diet Standard)',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealName': mealName,
    'description': description,
    'calories': calories,
    'proteinGrams': proteinGrams,
    'longevityNutrients': longevityNutrients,
    'longevityReason': longevityReason,
    'ingredients': ingredients,
    'preparationMinutes': preparationMinutes,
    'isAiGenerated': isAiGenerated,
    'isEditedByUser': isEditedByUser,
    'confidenceScore': confidenceScore,
    'sourceNote': sourceNote,
  };

  factory AiMealRecommendation.fromJson(Map<String, dynamic> json) {
    return AiMealRecommendation(
      id: json['id'] as String? ?? 'ai-${DateTime.now().millisecondsSinceEpoch}',
      mealName: json['mealName'] as String? ?? json['meal_name'] as String? ?? 'Món ăn trường thọ',
      description: json['description'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 400,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ??
          (json['protein_grams'] as num?)?.toDouble() ??
          12.0,
      longevityNutrients: (json['longevityNutrients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['longevity_nutrients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Chất xơ', 'Polyphenol'],
      longevityReason: json['longevityReason'] as String? ??
          json['longevity_reason'] as String? ??
          'Thực phẩm giàu dưỡng chất thực vật theo nguyên lý TS. Longo.',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preparationMinutes: (json['preparationMinutes'] as num?)?.toInt() ??
          (json['preparation_minutes'] as num?)?.toInt() ??
          20,
      isAiGenerated: json['isAiGenerated'] as bool? ?? json['is_ai_generated'] as bool? ?? true,
      isEditedByUser: json['isEditedByUser'] as bool? ?? json['is_edited_by_user'] as bool? ?? false,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ??
          (json['confidence_score'] as num?)?.toDouble() ??
          0.95,
      sourceNote: json['sourceNote'] as String? ?? json['source_note'] as String?,
    );
  }

  AiMealRecommendation copyWith({
    String? id,
    String? mealName,
    String? description,
    int? calories,
    double? proteinGrams,
    List<String>? longevityNutrients,
    String? longevityReason,
    List<String>? ingredients,
    int? preparationMinutes,
    bool? isAiGenerated,
    bool? isEditedByUser,
    double? confidenceScore,
    String? sourceNote,
  }) {
    return AiMealRecommendation(
      id: id ?? this.id,
      mealName: mealName ?? this.mealName,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      longevityNutrients: longevityNutrients ?? this.longevityNutrients,
      longevityReason: longevityReason ?? this.longevityReason,
      ingredients: ingredients ?? this.ingredients,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isEditedByUser: isEditedByUser ?? this.isEditedByUser,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sourceNote: sourceNote ?? this.sourceNote,
    );
  }

  /// Converts this AI recommendation into a domain [RecipeModel]
  /// for seamless replacement or addition into weekly meal plans.
  RecipeModel toRecipeModel({String category = 'dau'}) {
    return RecipeModel(
      id: id,
      name: mealName,
      description: description.isNotEmpty ? description : longevityReason,
      category: category,
      proteinGrams: proteinGrams,
      calories: calories.toDouble(),
      ingredients: [
        for (var i = 0; i < ingredients.length; i++)
          IngredientModel(
            id: '$id-ing-$i',
            name: ingredients[i],
            amount: 1,
            unit: 'phần',
            isPurchased: false,
          ),
      ],
      instructions: [
        longevityReason,
        if (longevityNutrients.isNotEmpty)
          'Dưỡng chất trường thọ: ${longevityNutrients.join(", ")}',
        'Thời gian chuẩn bị: $preparationMinutes phút',
      ],
      sourceNote: isAiGenerated
          ? (sourceNote != null ? '[ai] $sourceNote' : '[ai] Google Gemini 2.0 Flash')
          : (sourceNote ?? '[fallback] Valter Longo Diet Standard'),
    );
  }
}
