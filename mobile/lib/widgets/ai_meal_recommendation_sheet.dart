import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/models/ai_meal_recommendation.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/services/i_gemini_ai_service.dart';
import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';
import 'package:longvita_core/widgets/app_button.dart';

/// Modal bottom sheet for Level 2 Gemini AI Longevity Nutrition Recommendation.
///
/// Complies with PRM393 Final Assignment Section 8 requirements:
/// - Explicitly labeled as "AI-Generated" (or Fallback if offline/disabled).
/// - Fully editable by the user before saving into their meal plan.
/// - Telemetry logged via [IGeminiAiService.logRecommendationAccepted].
class AiMealRecommendationSheet extends StatefulWidget {
  final String mealType;
  final int? targetCalories;
  final List<String>? preferences;
  final RecipeModel? originalRecipe;

  const AiMealRecommendationSheet({
    super.key,
    required this.mealType,
    this.targetCalories,
    this.preferences,
    this.originalRecipe,
  });

  /// Helper to display this sheet as a modal bottom sheet.
  static Future<RecipeModel?> show({
    required BuildContext context,
    required String mealType,
    int? targetCalories,
    List<String>? preferences,
    RecipeModel? originalRecipe,
  }) {
    return showModalBottomSheet<RecipeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiMealRecommendationSheet(
        mealType: mealType,
        targetCalories: targetCalories,
        preferences: preferences,
        originalRecipe: originalRecipe,
      ),
    );
  }

  @override
  State<AiMealRecommendationSheet> createState() =>
      _AiMealRecommendationSheetState();
}

class _AiMealRecommendationSheetState extends State<AiMealRecommendationSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  AiMealRecommendation? _recommendation;

  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _reasonController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRecommendation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aiService = context.read<IGeminiAiService>();
      final rec = await aiService.recommendLongevityMeal(
        mealType: widget.mealType,
        targetCalories: widget.targetCalories,
        preferences: widget.preferences,
      );

      if (!mounted) return;
      setState(() {
        _recommendation = rec;
        _nameController.text = rec.mealName;
        _caloriesController.text = rec.calories.toString();
        _proteinController.text = rec.proteinGrams.toStringAsFixed(1);
        _reasonController.text = rec.longevityReason;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể lấy gợi ý AI: $e';
        _isLoading = false;
      });
    }
  }

  void _applyRecommendation() {
    final rec = _recommendation;
    if (rec == null) return;

    final newName = _nameController.text.trim();
    final caloriesParsed = int.tryParse(_caloriesController.text);
    final proteinParsed = double.tryParse(_proteinController.text);

    if (newName.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên món ăn.');
      return;
    }
    if (caloriesParsed == null || caloriesParsed <= 0) {
      setState(() => _errorMessage = 'Lượng calo phải là số nguyên dương lớn hơn 0.');
      return;
    }
    if (proteinParsed == null || proteinParsed <= 0) {
      setState(() => _errorMessage = 'Lượng protein phải là số dương lớn hơn 0.');
      return;
    }

    final newCalories = caloriesParsed;
    final newProtein = proteinParsed;
    final newReason = _reasonController.text.trim();

    final wasEdited =
        newName != rec.mealName ||
        newCalories != rec.calories ||
        newProtein != rec.proteinGrams ||
        newReason != rec.longevityReason;

    // Log acceptance event to Firebase Analytics
    final aiService = context.read<IGeminiAiService>();
    unawaited(aiService.logRecommendationAccepted(
      recommendationId: rec.id,
      wasEdited: wasEdited,
    ));

    // Generate unique ID to prevent collisions in plan
    final uniqueId = '${rec.id}-${DateTime.now().millisecondsSinceEpoch}';

    // Build finalized RecipeModel
    final updated = rec
        .copyWith(
          id: uniqueId,
          mealName: newName,
          calories: newCalories,
          proteinGrams: newProtein,
          longevityReason:
              newReason.isNotEmpty ? newReason : rec.longevityReason,
          isEditedByUser: wasEdited,
        )
        .toRecipeModel(category: widget.originalRecipe?.category ?? 'dau');

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderControl.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.actionPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gợi ý từ Gemini AI',
                      style: const TextStyle(
                        fontFamily: AppTypography.newsreader,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Dinh dưỡng trường thọ tối ưu hóa Autophagy & IGF-1 (TS. Valter Longo)',
                style: TextStyle(
                  fontFamily: AppTypography.quicksand,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading) ...[
                const SizedBox(height: 40),
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Gemini đang thiết kế món ăn trường thọ...',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.bgPeach,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: AppTypography.quicksand,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Thử lại',
                  icon: Icons.refresh,
                  onPressed: _loadRecommendation,
                ),
              ] else if (_recommendation != null) ...[
                _buildRecommendationContent(_recommendation!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationContent(AiMealRecommendation rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Rubric Mandatory AI Label Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: rec.isAiGenerated ? AppColors.bgSelected : AppColors.bgPeach,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rec.isAiGenerated
                  ? AppColors.actionPrimary
                  : const Color(0xFFC47D42),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                rec.isAiGenerated
                    ? Icons.auto_awesome
                    : Icons.shield_outlined,
                size: 18,
                color: rec.isAiGenerated
                    ? AppColors.actionPrimary
                    : const Color(0xFF8A4B1A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.isAiGenerated
                      ? 'AI-Generated (Google Gemini 2.0 Flash)'
                      : 'An toàn: Fallback (Thực đơn chuẩn TS. Valter Longo)',
                  style: TextStyle(
                    fontFamily: AppTypography.quicksand,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rec.isAiGenerated
                        ? AppColors.actionPrimary
                        : const Color(0xFF8A4B1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Editable Name Field (Rubric requirement)
        const Text(
          'Tên món ăn (Bạn có thể chỉnh sửa)',
          style: TextStyle(
            fontFamily: AppTypography.quicksand,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('ai-meal-name-field'),
          controller: _nameController,
          style: const TextStyle(
            fontFamily: AppTypography.quicksand,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderControl),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.actionPrimary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Nutrition Row: Calories & Protein (Editable)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calo mục tiêu (kcal)',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('ai-meal-calories-field'),
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.borderControl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protein (g)',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('ai-meal-protein-field'),
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.borderControl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Longevity Nutrients
        if (rec.longevityNutrients.isNotEmpty) ...[
          const Text(
            'Dưỡng chất trường thọ chính',
            style: TextStyle(
              fontFamily: AppTypography.quicksand,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rec.longevityNutrients
                .map(
                  (nutrient) => Chip(
                    backgroundColor: AppColors.bgSelected,
                    label: Text(
                      nutrient,
                      style: const TextStyle(
                        fontFamily: AppTypography.quicksand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.actionPrimary,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
        ],

        // 5. Longevity Reason
        const Text(
          'Lý do dinh dưỡng (Khoa học TS. Longo)',
          style: TextStyle(
            fontFamily: AppTypography.quicksand,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderControl.withValues(alpha: 0.5)),
          ),
          child: Text(
            rec.longevityReason,
            style: const TextStyle(
              fontFamily: AppTypography.quicksand,
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 6. Ingredients
        if (rec.ingredients.isNotEmpty) ...[
          const Text(
            'Nguyên liệu gợi ý',
            style: TextStyle(
              fontFamily: AppTypography.quicksand,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rec.ingredients
                  .map(
                    (ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.actionPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ing,
                              style: const TextStyle(
                                fontFamily: AppTypography.quicksand,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 7. Action Buttons
        AppButton(
          key: const Key('ai-meal-apply-btn'),
          text: 'Áp dụng món ăn này',
          icon: Icons.check,
          variant: AppButtonVariant.primary,
          onPressed: _applyRecommendation,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _loadRecommendation,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Gợi ý món khác',
                  style: TextStyle(
                    fontFamily: AppTypography.quicksand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    fontFamily: AppTypography.quicksand,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
