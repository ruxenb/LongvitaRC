import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:longvita/services/gemini_ai_service.dart';
import 'package:longvita_core/models/ai_meal_recommendation.dart';

void main() {
  group('GeminiAiService (TA-03 & TA-04)', () {
    test('returns structured AiMealRecommendation when Gemini API returns valid JSON', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'mealName': 'Salad đậu lăng Địa Trung Hải',
                    'description': 'Đậu lăng nấu chín trộn cà chua, ô liu và dầu ô liu nguyên chất.',
                    'calories': 380,
                    'proteinGrams': 15.5,
                    'longevityNutrients': ['Polyphenols', 'Chất xơ', 'Sắt thực vật'],
                    'longevityReason': 'Giúp ổn định đường huyết và kích thích autophagy theo TS. Valter Longo.',
                    'ingredients': ['Đậu lăng 100g', 'Cà chua 50g', 'Dầu ô liu 15ml'],
                    'preparationMinutes': 20,
                  })
                }
              ]
            }
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.toString(), contains('generativelanguage.googleapis.com'));
        expect(request.headers['Content-Type'], 'application/json');

        // Zero PII check: ensure no personal identifiers are sent
        final body = request.body;
        expect(body.contains('@'), isFalse, reason: 'Must not send email addresses');
        expect(body.contains('user_id'), isFalse, reason: 'Must not send user ID');
        expect(body.contains('Thai An'), isFalse, reason: 'Must not send user name');

        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = GeminiAiService(
        httpClient: client,
        apiKey: 'test-api-key',
      );

      final result = await service.recommendLongevityMeal(
        mealType: 'Bữa trưa',
        targetCalories: 400,
        preferences: ['Ăn chay', 'Nhiều đậu'],
      );

      expect(result.mealName, 'Salad đậu lăng Địa Trung Hải');
      expect(result.calories, 380);
      expect(result.proteinGrams, 15.5);
      expect(result.longevityNutrients, contains('Polyphenols'));
      expect(result.isAiGenerated, isTrue);
    });

    test('strips markdown code fences correctly', () async {
      const fencedJson = '''```json
{
  "mealName": "Cháo yến mạch việt quất",
  "description": "Yến mạch nấu nước cùng việt quất.",
  "calories": 310,
  "proteinGrams": 8.0,
  "longevityNutrients": ["Anthocyanin"],
  "longevityReason": "Chống lão hóa tế bào",
  "ingredients": ["Yến mạch 40g"],
  "preparationMinutes": 10
}
```''';

      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': fencedJson}
              ]
            }
          }
        ]
      };

      final client = MockClient((_) async => http.Response(jsonEncode(mockResponse), 200));
      final service = GeminiAiService(
        httpClient: client,
        apiKey: 'test-api-key',
      );

      final result = await service.recommendLongevityMeal(mealType: 'breakfast');
      expect(result.mealName, 'Cháo yến mạch việt quất');
      expect(result.calories, 310);
      expect(result.isAiGenerated, isTrue);
    });

    test('falls back gracefully to Valter Longo meal on HTTP error (500, 429)', () async {
      final client = MockClient((_) async => http.Response('Internal server error', 500));
      final service = GeminiAiService(
        httpClient: client,
        apiKey: 'test-api-key',
      );

      final result = await service.recommendLongevityMeal(mealType: 'dinner');

      expect(result, isNotNull);
      expect(result.mealName, contains('Salad đậu gà'));
      expect(result.isAiGenerated, isFalse);
      expect(result.sourceNote, contains('Valter Longo Diet Standard'));
    });

    test('falls back gracefully when missing API key', () async {
      final service = GeminiAiService(apiKey: '');
      final result = await service.recommendLongevityMeal(mealType: 'lunch');

      expect(result, isNotNull);
      expect(result.mealName, contains('Súp đậu Garbanzo'));
      expect(result.isAiGenerated, isFalse);
    });

    test('AiMealRecommendation model copyWith and json roundtrip', () {
      final original = AiMealRecommendation.fallback(mealType: 'breakfast');
      final json = original.toJson();
      final fromJson = AiMealRecommendation.fromJson(json);

      expect(fromJson.mealName, original.mealName);
      expect(fromJson.calories, original.calories);

      final edited = fromJson.copyWith(mealName: 'Cháo yến mạch sửa đổi', isEditedByUser: true);
      expect(edited.mealName, 'Cháo yến mạch sửa đổi');
      expect(edited.isEditedByUser, isTrue);
    });
  });
}
