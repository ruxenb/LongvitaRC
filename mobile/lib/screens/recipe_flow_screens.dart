import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita/services/secure_recipe_image.dart';
import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/theme/app_spacing.dart';
import 'package:longvita_core/theme/app_typography.dart';
import 'package:longvita_core/widgets/app_badge.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita_core/widgets/app_button.dart';
import 'package:longvita_core/widgets/state_views.dart';
import 'package:longvita/screens/flow_ui.dart';
import 'package:longvita/screens/meal_flow_screens.dart';
import 'package:longvita/widgets/ai_meal_recommendation_sheet.dart';

/// S05: show only a bounded, HTTPS-loaded Firestore image without
/// following redirects or inventing stock assets when an image is absent.
class _RecipeHero extends StatefulWidget {
  final RecipeModel recipe;
  const _RecipeHero(this.recipe);

  @override
  State<_RecipeHero> createState() => _RecipeHeroState();
}

class _RecipeHeroState extends State<_RecipeHero> {
  Future<Uint8List>? _image;

  void _loadImage() {
    final rawUrl = widget.recipe.imageUrl?.trim();
    if (rawUrl != null && rawUrl.startsWith('data:image')) {
      final comma = rawUrl.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(rawUrl.substring(comma + 1));
          _image = Future.value(bytes);
          return;
        } catch (_) {}
      }
    }
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    _image =
        uri != null &&
            uri.scheme == 'https' &&
            uri.hasAuthority &&
            uri.userInfo.isEmpty
        ? fetchSecureRecipeImage(uri)
        : null;
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _RecipeHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.imageUrl != widget.recipe.imageUrl) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget placeholder({bool loading = false}) => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? Semantics(
                  key: const Key('recipe-hero-loading'),
                  liveRegion: true,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Đang tải ảnh món…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  'Chưa có ảnh được xác minh cho món này',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 328 / 126,
        child: _image == null
            ? placeholder()
            : FutureBuilder<Uint8List>(
                future: _image,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return placeholder(loading: true);
                  }
                  if (!snapshot.hasData) return placeholder();
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Decode near the rendered physical width, avoiding
                      // excessive memory use for large source photographs.
                      final cacheWidth =
                          (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .ceil()
                              .clamp(64, 2048);
                      return Image.memory(
                        snapshot.data!,
                        key: const Key('recipe-hero-image'),
                        fit: BoxFit.cover,
                        cacheWidth: cacheWidth,
                        semanticLabel: 'Ảnh món ${widget.recipe.name}',
                        errorBuilder: (_, _, _) => placeholder(),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

/// Search uses real Firestore data; filter is in MealPlanViewModel.
class RecipeCatalogScreen extends StatefulWidget {
  const RecipeCatalogScreen({super.key});

  @override
  State<RecipeCatalogScreen> createState() => _RecipeCatalogScreenState();
}

class _RecipeCatalogScreenState extends State<RecipeCatalogScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MealPlanViewModel>().searchRecipes('');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() => context.read<MealPlanViewModel>().searchRecipes(_search.text);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MealPlanViewModel>().recipesState;
    return FlowFrame(
      title: 'Tra cứu công thức',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('recipe-search'),
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              labelText: 'Tên món, danh mục hoặc mô tả',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                onPressed: _load,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FlowStateView<List<RecipeModel>>(
            state: state,
            emptyTitle: 'Chưa có công thức phù hợp',
            onRetry: _load,
            onBack: () => Navigator.of(context).pop(),
            onData: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tìm thấy ${items.length} công thức.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                for (final recipe in items)
                  FlowItemCard(
                    title: recipe.name,
                    subtitle:
                        '${recipe.calories.toStringAsFixed(0)} kcal • ${recipe.proteinGrams.toStringAsFixed(1)} g đạm',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailsScreen(recipe: recipe),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// S05: nutritional details and Firestore-provided citation metadata.
class RecipeDetailsScreen extends StatefulWidget {
  final RecipeModel recipe;
  final int? dayIndex;
  const RecipeDetailsScreen({super.key, required this.recipe, this.dayIndex});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = widget.recipe;
      context.read<AnalyticsService>().logViewRecipeDetails(
        recipeId: r.id,
        isFishMeal: r.category == 'ca' ? 1 : 0,
        isBookCitation: r.isBookCitation ? 1 : 0,
        calories: r.calories.round(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.actionPrimary),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Chi tiết công thức',
          style: TextStyle(
            fontFamily: AppTypography.newsreader,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecipeHero(recipe),
                  const SizedBox(height: 16),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontFamily: AppTypography.newsreader,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (recipe.isBookCitation) ...[
                        const AppBadge(kind: AppBadgeKind.fromBook),
                      ],
                      Text(
                        '${recipe.proteinGrams.toStringAsFixed(0)} g protein · 1 serving',
                        style: const TextStyle(
                          fontFamily: AppTypography.quicksand,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      recipe.description,
                      style: const TextStyle(
                        fontFamily: AppTypography.quicksand,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Nguyên liệu',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipe.ingredients.isEmpty)
                    const Text('Công thức chưa có danh sách nguyên liệu.')
                  else
                    for (final item in recipe.ingredients)
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.bgPressed,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: AppTypography.quicksand,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                              style: const TextStyle(
                                fontFamily: AppTypography.quicksand,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 24),
                  const Text(
                    'Các bước thực hiện',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipe.instructions.isEmpty)
                    const Text('Chưa có hướng dẫn trong Firestore.')
                  else
                    for (var i = 0; i < recipe.instructions.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppRadius.rounded8,
                          boxShadow: AppElevation.level1,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.bgSelected,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontFamily: AppTypography.quicksand,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.actionPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  recipe.instructions[i],
                                  style: const TextStyle(
                                    fontFamily: AppTypography.quicksand,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 24),
                  // Button Replace Meal (Design System AppButton)
                  AppButton(
                    text: 'Đổi món',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      final targetIndex = widget.dayIndex ?? 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MealAlternativesScreen(
                            original: recipe,
                            dayIndex: targetIndex,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Button Direct Gemini AI Recommendation
                  AppButton(
                    key: const Key('gemini-ai-direct-btn'),
                    text: 'Gợi ý món mới từ Gemini AI',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.primary,
                    onPressed: () async {
                      final aiRecipe = await AiMealRecommendationSheet.show(
                        context: context,
                        mealType: recipe.category == 'ca' ? 'lunch' : 'dinner',
                        targetCalories: recipe.calories.round(),
                        originalRecipe: recipe,
                      );
                      if (aiRecipe != null && context.mounted) {
                        final vm = context.read<MealPlanViewModel>();
                        final success = await vm.replaceMeal(
                          dayIndex: widget.dayIndex ?? 0,
                          originalId: recipe.id,
                          replacement: aiRecipe,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Secondary: Sách
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.actionPrimary,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookKnowledgeScreen(recipe: recipe),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    label: const Text(
                      'Kiến thức sách (TS. Valter Longo)',
                      style: TextStyle(
                        fontFamily: AppTypography.quicksand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// S06: no-alternative -> S02; failed cloud update retains the original.
class MealAlternativesScreen extends StatefulWidget {
  final RecipeModel original;
  final int dayIndex;
  const MealAlternativesScreen({
    super.key,
    required this.original,
    required this.dayIndex,
  });

  @override
  State<MealAlternativesScreen> createState() => _MealAlternativesScreenState();
}

class _MealAlternativesScreenState extends State<MealAlternativesScreen> {
  RecipeModel? _selected;

  void _load() =>
      context.read<MealPlanViewModel>().loadAlternatives(widget.original);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _replace() async {
    final selection = _selected;
    if (selection == null) return;
    final vm = context.read<MealPlanViewModel>();
    final success = await vm.replaceMeal(
      dayIndex: widget.dayIndex,
      originalId: widget.original.id,
      replacement: selection,
    );
    if (!mounted) return;
    if (success) {
      final navigator = Navigator.of(context);
      navigator.pop(); // S06
      navigator.pop(); // S05
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlanViewModel>();
    final state = vm.alternativesState;
    final updateError = vm.replaceState is ViewStateError<bool>
        ? (vm.replaceState as ViewStateError<bool>).message
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.actionPrimary),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Meal alternatives',
          style: TextStyle(
            fontFamily: AppTypography.quicksand,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose a replacement',
                    style: TextStyle(
                      fontFamily: AppTypography.newsreader,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your original meal stays unchanged until you confirm.',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Original Meal Card (Warm Peach)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.bgPeach,
                      borderRadius: AppRadius.rounded8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original: ${widget.original.name}',
                          style: const TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.actionPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Món gốc được giữ lại nếu bạn hủy hoặc cập nhật thất bại.',
                          style: TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gemini AI Replacement Card (Level 2 Structured Output)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSelected,
                      borderRadius: AppRadius.rounded12,
                      border: Border.all(
                        color: AppColors.actionPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.actionPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gợi ý món thay thế bằng Gemini AI',
                                style: TextStyle(
                                  fontFamily: AppTypography.quicksand,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.actionPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tạo món thay thế chuẩn TS. Longo tương đồng calo và dinh dưỡng.',
                          style: TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          key: const Key('gemini-ai-alternative-btn'),
                          text: 'Nhận gợi ý từ Gemini AI',
                          icon: Icons.auto_awesome,
                          variant: AppButtonVariant.primary,
                          onPressed: () async {
                            final aiRecipe =
                                await AiMealRecommendationSheet.show(
                                  context: context,
                                  mealType: widget.original.category == 'ca'
                                      ? 'lunch'
                                      : 'dinner',
                                  targetCalories:
                                      widget.original.calories.round(),
                                  originalRecipe: widget.original,
                                );
                            if (aiRecipe != null && context.mounted) {
                              setState(() => _selected = aiRecipe);
                              await _replace();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state is ViewStateEmpty<List<RecipeModel>>)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FlowStateView<List<RecipeModel>>(
                          state: state,
                          onData: (_) => const SizedBox.shrink(),
                          onRetry: _load,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Điều chỉnh sở thích (S02)',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PreferencesScreen(),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    FlowStateView<List<RecipeModel>>(
                      state: state,
                      onRetry: _load,
                      onBack: () => Navigator.of(context).pop(),
                      onData: (choices) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final recipe in choices) ...[
                            _buildAlternativeCard(recipe),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          if (_selected != null) ...[
                            AppButton(
                              text: 'Xác nhận: ${_selected!.name}',
                              variant: AppButtonVariant.primary,
                              isLoading:
                                  vm.replaceState is ViewStateLoading<bool>,
                              icon: Icons.check,
                              onPressed: _replace,
                            ),
                            const SizedBox(height: AppSpacing.s12),
                          ],
                          // Keep Original Button (Outlined Design System)
                          AppButton(
                            text: 'Giữ món gốc',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  if (updateError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ErrorView(
                        title: 'Không thể đổi món',
                        message: updateError,
                        retryLabel: 'Thử lại',
                        onRetry: _replace,
                        backLabel: 'Giữ món gốc',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(RecipeModel recipe) {
    final isSelected = _selected?.id == recipe.id;
    return Semantics(
      selected: isSelected,
      child: InkWell(
        key: Key('alternative-${recipe.id}'),
        onTap: () => setState(() => _selected = recipe),
        borderRadius: AppRadius.rounded12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.rounded12,
            border: Border.all(
              color: isSelected
                  ? AppColors.actionPrimary
                  : AppColors.borderDecorative,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? AppElevation.level2 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.description.isNotEmpty
                              ? recipe.description
                              : '${recipe.calories.toStringAsFixed(0)} kcal • ${recipe.proteinGrams.toStringAsFixed(1)} g đạm',
                          style: const TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Select button
                  GestureDetector(
                    onTap: () => setState(() => _selected = recipe),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.actionPrimary
                            : Colors.transparent,
                        borderRadius: AppRadius.rounded8,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.actionPrimary
                              : AppColors.borderControl,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isSelected ? 'Đã chọn' : 'Chọn',
                        style: TextStyle(
                          fontFamily: AppTypography.quicksand,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.actionPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (recipe.isBookCitation)
                    const AppBadge(kind: AppBadgeKind.fromBook)
                  else
                    const AppBadge(kind: AppBadgeKind.appSuggestion),
                  const Spacer(),
                  Text(
                    '${recipe.proteinGrams.toStringAsFixed(0)}g protein • ${recipe.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S09: Book knowledge principles and verified source citation from Figma (108:332).
class BookKnowledgeScreen extends StatelessWidget {
  final RecipeModel? recipe;
  const BookKnowledgeScreen({super.key, this.recipe});

  static const _principles = [
    (
      'Nền tảng giàu thực vật',
      'Ưu tiên rau củ, các loại đậu và ngũ cốc nguyên hạt.',
    ),
    ('Cân bằng protein', 'Dùng mục tiêu đã tính toán để tham khảo.'),
    ('Chất béo lành mạnh', 'Ưu tiên dầu ô liu, các loại hạt và nguồn omega-3.'),
    ('Cá ít thủy ngân', 'Giữ lượng cá trong giới hạn khuyến nghị mỗi tuần.'),
  ];

  @override
  Widget build(BuildContext context) {
    final sourceText = recipe != null && recipe!.sourceNote.trim().isNotEmpty
        ? recipe!.sourceNote
        : 'The Longevity Diet · Phụ lục A và các nguyên tắc dinh dưỡng Longvita sử dụng.';

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.actionPrimary),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Book knowledge',
          style: TextStyle(
            fontFamily: AppTypography.quicksand,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Offstage marker for traceability
                  const Offstage(
                    offstage: true,
                    child: Text('S09 • Kiến thức sách'),
                  ),
                  const Text(
                    'Vì sao thực đơn này phù hợp',
                    style: TextStyle(
                      fontFamily: AppTypography.newsreader,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Các nguyên tắc ngắn gọn từ nguồn, gắn với bữa ăn thực tế.',
                    style: TextStyle(
                      fontFamily: AppTypography.quicksand,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 4 Knowledge Principle Cards
                  for (final (title, description) in _principles) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppRadius.rounded8,
                        border: Border.all(
                          color: AppColors.borderDecorative,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: AppTypography.quicksand,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.actionPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: AppTypography.quicksand,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  // Source Card (Warm Peach)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.bgPeach,
                      borderRadius: AppRadius.rounded8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Source',
                          style: TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.actionPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sourceText,
                          style: const TextStyle(
                            fontFamily: AppTypography.quicksand,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Back to Recipe Button (Design System AppButton)
                  AppButton(
                    text: 'Quay lại công thức',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
