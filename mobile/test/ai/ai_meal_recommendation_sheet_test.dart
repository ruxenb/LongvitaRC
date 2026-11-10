import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/models/ai_meal_recommendation.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/services/i_gemini_ai_service.dart';
import 'package:longvita/widgets/ai_meal_recommendation_sheet.dart';

class FakeGeminiAiService implements IGeminiAiService {
  AiMealRecommendation? stubRecommendation;
  bool recommendCalled = false;
  String? acceptedId;
  bool? acceptedWasEdited;

  @override
  Future<AiMealRecommendation> recommendLongevityMeal({
    required String mealType,
    int? targetCalories,
    String? preferences,
  }) async {
    recommendCalled = true;
    return stubRecommendation ??
        const AiMealRecommendation(
          id: 'test-rec-1',
          mealName: 'Salad đậu lăng Địa Trung Hải',
          description: 'Salad dinh dưỡng giàu polyphenol',
          calories: 380,
          proteinGrams: 14.5,
          longevityNutrients: ['Polyphenol', 'Chất xơ'],
          longevityReason: 'Hỗ trợ autophagy tế bào theo TS. Longo',
          ingredients: ['Đậu lăng 100g', 'Dầu ô liu 15ml'],
          isAiGenerated: true,
          confidenceScore: 0.95,
        );
  }

  @override
  void logRecommendationAccepted(
    String recommendationId, {
    bool wasEdited = false,
  }) {
    acceptedId = recommendationId;
    acceptedWasEdited = wasEdited;
  }
}

void main() {
  Widget buildTestHost({
    required IGeminiAiService aiService,
    RecipeModel? originalRecipe,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<IGeminiAiService>.value(value: aiService),
        ],
        child: Scaffold(
          body: AiMealRecommendationSheet(
            mealType: 'lunch',
            targetCalories: 400,
            originalRecipe: originalRecipe,
          ),
        ),
      ),
    );
  }

  testWidgets('renders AI-Generated badge, longevity nutrients and prefilled values', (tester) async {
    final fakeAi = FakeGeminiAiService();

    await tester.pumpWidget(buildTestHost(aiService: fakeAi));
    await tester.pumpAndSettle();

    expect(fakeAi.recommendCalled, isTrue);
    expect(find.text('AI-Generated (Google Gemini 2.0 Flash)'), findsOneWidget);
    expect(find.text('Salad đậu lăng Địa Trung Hải'), findsOneWidget);
    expect(find.text('380'), findsOneWidget);
    expect(find.text('14.5'), findsOneWidget);
    expect(find.text('Polyphenol'), findsOneWidget);
    expect(find.text('Chất xơ'), findsOneWidget);
  });

  testWidgets('allows user to edit meal name and logs wasEdited=true on apply', (tester) async {
    final fakeAi = FakeGeminiAiService();

    await tester.pumpWidget(buildTestHost(aiService: fakeAi));
    await tester.pumpAndSettle();

    // User edits the meal name
    final nameField = find.byKey(const Key('ai-meal-name-field'));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Salad đậu lăng biến tấu');
    await tester.pumpAndSettle();

    // User taps apply button
    final applyBtn = find.byKey(const Key('ai-meal-apply-btn'));
    expect(applyBtn, findsOneWidget);
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();

    expect(fakeAi.acceptedId, 'test-rec-1');
    expect(fakeAi.acceptedWasEdited, isTrue);
  });

  testWidgets('displays Fallback badge when response isAiGenerated is false', (tester) async {
    final fakeAi = FakeGeminiAiService()
      ..stubRecommendation = AiMealRecommendation.fallback(mealType: 'lunch');

    await tester.pumpWidget(buildTestHost(aiService: fakeAi));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fallback'), findsOneWidget);
    expect(find.text('Súp đậu Garbanzo và rau củ trường thọ'), findsOneWidget);
  });
}
