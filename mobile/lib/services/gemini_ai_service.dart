import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita_core/firebase/remote_config_service.dart';
import 'package:longvita_core/models/ai_meal_recommendation.dart';
import 'package:longvita_core/services/i_gemini_ai_service.dart';

/// Gemini AI Longevity Nutrition Recommendation Service.
/// Implements Level 2 Structured Output, Fallback Strategy & Zero PII.
/// Corresponds to PRM393 Final Assignment Section 8 requirements.
class GeminiAiService implements IGeminiAiService {
  final http.Client _client;
  final RemoteConfigService? _remoteConfig;
  final AnalyticsService? _analytics;
  final String? _apiKey;

  static const String _defaultModel = 'gemini-1.5-flash';
  static const Duration _timeout = Duration(seconds: 12);

  GeminiAiService({
    http.Client? httpClient,
    RemoteConfigService? remoteConfig,
    AnalyticsService? analytics,
    String? apiKey,
  })  : _client = httpClient ?? http.Client(),
        _remoteConfig = remoteConfig,
        _analytics = analytics,
        _apiKey = apiKey;

  @override
  Future<AiMealRecommendation> recommendLongevityMeal({
    required String mealType,
    int? targetCalories,
    List<String>? preferences,
  }) async {
    // 1. Check Remote Config feature flag
    final bool isEnabled = _remoteConfig?.getBool('ai_feature_enabled') ?? true;
    if (!isEnabled) {
      return AiMealRecommendation.fallback(
        mealType: mealType,
        reason: 'AI feature disabled via Remote Config',
      );
    }

    final modelName = _remoteConfig?.getString('gemini_model_name') ?? _defaultModel;
    final cleanModel = modelName.trim().isEmpty ? _defaultModel : modelName.trim();

    // 2. Zero PII: Prepare prompt containing ONLY nutritional constraints
    final sanitizedCalories = targetCalories != null && targetCalories > 0 ? targetCalories : 400;
    final sanitizedPrefs = preferences != null && preferences.isNotEmpty
        ? preferences.where((p) => p.trim().isNotEmpty).take(5).join(', ')
        : 'Địa Trung Hải, thực vật nguyên phần, ít đường';

    final prompt = _buildPrompt(
      mealType: mealType,
      targetCalories: sanitizedCalories,
      preferences: sanitizedPrefs,
    );

    // 3. Log Analytics request (Zero PII parameters only)
    try {
      await _analytics?.logEvent(
        name: 'ai_request',
        parameters: {
          'meal_type': mealType.toLowerCase(),
          'target_calories': sanitizedCalories,
          'model_name': cleanModel,
        },
      );
    } catch (_) {
      // Analytics failure must never block application flow
    }

    // 4. If no API key is provided in environment or test, trigger graceful fallback
    final key = _apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');
    if (key.trim().isEmpty) {
      return AiMealRecommendation.fallback(
        mealType: mealType,
        reason: 'Local graceful fallback (no Gemini API key configured)',
      );
    }

    // 5. Execute HTTP call to Gemini Developer API
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$cleanModel:generateContent?key=$key',
    );

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topK': 32,
        'topP': 0.9,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      }
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        final rawText = _extractTextFromGeminiResponse(responseJson);

        if (rawText != null && rawText.isNotEmpty) {
          final structured = _parseStructuredJson(rawText, mealType);
          if (structured != null) {
            return structured;
          }
        }
      }

      // Record non-fatal error in Analytics and fallback
      _logAiError('http_${response.statusCode}', mealType);
      return AiMealRecommendation.fallback(
        mealType: mealType,
        reason: 'HTTP error ${response.statusCode}',
      );
    } on TimeoutException {
      _logAiError('timeout', mealType);
      return AiMealRecommendation.fallback(
        mealType: mealType,
        reason: 'Gemini API request timed out after ${_timeout.inSeconds}s',
      );
    } catch (e) {
      _logAiError('exception_${e.runtimeType}', mealType);
      return AiMealRecommendation.fallback(
        mealType: mealType,
        reason: 'Network/Service exception occurred',
      );
    }
  }

  @override
  Future<void> logRecommendationAccepted({
    required String recommendationId,
    required bool wasEdited,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'ai_result_accepted',
        parameters: {
          'recommendation_id': recommendationId,
          'was_edited': wasEdited ? 1 : 0,
        },
      );
    } catch (_) {
      // Non-fatal
    }
  }

  void _logAiError(String errorType, String mealType) {
    try {
      _analytics?.logEvent(
        name: 'ai_error',
        parameters: {
          'error_type': errorType,
          'meal_type': mealType.toLowerCase(),
        },
      );
    } catch (_) {
      // Non-fatal
    }
  }

  String _buildPrompt({
    required String mealType,
    required int targetCalories,
    required String preferences,
  }) {
    return '''
Bạn là chuyên gia dinh dưỡng trường thọ theo nghiên cứu của TS. Valter Longo (Chế độ ăn trường thọ - Longevity Diet).
Hãy đề xuất 1 món ăn cho bữa "$mealType" với mục tiêu khoảng $targetCalories kcal.
Sở thích dinh dưỡng: $preferences.

YÊU CẦU ĐẶC BIỆT:
- Ưu tiên thực vật nguyên phần, đậu đỗ, rau củ giàu chất xơ, polyphenol, chất béo lành mạnh (dầu ô liu, hạt).
- Hạn chế đường tinh luyện, thịt đỏ và chất béo bão hòa.
- BẮT BUỘC trả về đúng định dạng JSON chuẩn theo schema sau, KHÔNG dùng markdown fence, KHÔNG giải thích ngoài JSON:
{
  "mealName": "Tên món ăn (tiếng Việt)",
  "description": "Mô tả ngắn gọn về món ăn (1-2 câu)",
  "calories": $targetCalories,
  "proteinGrams": 14.5,
  "longevityNutrients": ["Polyphenol", "Chất xơ", "Omega-3"],
  "longevityReason": "Lý giải ngắn gọn tại sao món này giúp kéo dài tuổi thọ tế bào theo TS. Longo",
  "ingredients": ["Nguyên liệu 1 và định lượng", "Nguyên liệu 2 và định lượng"],
  "preparationMinutes": 20
}
''';
  }

  String? _extractTextFromGeminiResponse(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) return null;
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return parts[0]['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  AiMealRecommendation? _parseStructuredJson(String rawText, String mealType) {
    try {
      String cleaned = rawText.trim();
      // Remove any markdown code fences if Gemini included them
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      decoded['isAiGenerated'] = true;
      decoded['sourceNote'] = 'Google Gemini Developer API (Level 2 Structured Output)';
      return AiMealRecommendation.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
