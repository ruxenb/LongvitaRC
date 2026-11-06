import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_service.dart';
import '../models/recipe_model.dart';
import '../models/view_state.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/state_views.dart';
import 'flow_ui.dart';
import 'meal_flow_screens.dart';

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
    return FlowFrame(
      title: 'S05 • Chi tiết món ăn',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowSection(
            title: recipe.name,
            child: Text(
              recipe.description.isEmpty
                  ? 'Chưa có phần mô tả trong Firestore.'
                  : recipe.description,
            ),
          ),
          FlowSection(
            title: 'Dinh dưỡng tham khảo',
            child: Text(
              '${recipe.calories.toStringAsFixed(0)} kcal • ${recipe.proteinGrams.toStringAsFixed(1)} g đạm',
            ),
          ),
          FlowSection(
            title: 'Nguyên liệu',
            child: recipe.ingredients.isEmpty
                ? const Text('Công thức chưa có danh sách nguyên liệu.')
                : Column(
                    children: [
                      for (final item in recipe.ingredients)
                        FlowItemCard(
                          title: item.name,
                          subtitle:
                              '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                          icon: Icons.eco_outlined,
                        ),
                    ],
                  ),
          ),
          FlowSection(
            title: 'Cách chế biến',
            child: recipe.instructions.isEmpty
                ? const Text('Chưa có hướng dẫn trong Firestore.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < recipe.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('${i + 1}. ${recipe.instructions[i]}'),
                        ),
                    ],
                  ),
          ),
          FlowSection(
            title: 'Nguồn trong dữ liệu',
            child: Text(
              recipe.sourceNote.isNotEmpty
                  ? recipe.sourceNote
                  : 'Chưa xác minh được nguồn trong Firestore.',
            ),
          ),
          AppButton(
            text: 'Kiến thức sách',
            icon: Icons.menu_book_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookKnowledgeScreen(recipe: recipe),
              ),
            ),
          ),
          if (widget.dayIndex != null) ...[
            const SizedBox(height: 12),
            AppButton(
              text: 'Đổi món ăn',
              icon: Icons.swap_horiz,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MealAlternativesScreen(
                    original: recipe,
                    dayIndex: widget.dayIndex!,
                  ),
                ),
              ),
            ),
          ],
        ],
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
    return FlowFrame(
      title: 'S06 • Món thay thế',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowSection(
            title: 'Thay món ${widget.original.name}',
            child: const Text(
              'Món đang xem chỉ thay đổi khi máy chủ xác nhận. Nếu mất mạng, thao tác có thể đồng bộ sau; hãy tải lại thực đơn để kiểm tra.',
            ),
          ),
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
                  RadioGroup<String>(
                    groupValue: _selected?.id,
                    onChanged: (value) => setState(() {
                      for (final recipe in choices) {
                        if (recipe.id == value) _selected = recipe;
                      }
                    }),
                    child: Column(
                      children: [
                        for (final recipe in choices)
                          Semantics(
                            selected: _selected?.id == recipe.id,
                            child: RadioListTile<String>(
                              key: Key('alternative-${recipe.id}'),
                              title: Text(recipe.name),
                              subtitle: Text(
                                '${recipe.calories.toStringAsFixed(0)} kcal • ${recipe.proteinGrams.toStringAsFixed(1)} g đạm',
                              ),
                              value: recipe.id,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Xác nhận thay đổi',
                    icon: Icons.check,
                    isLoading: vm.replaceState is ViewStateLoading<bool>,
                    onPressed: _selected == null ? null : _replace,
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
        ],
      ),
    );
  }
}

/// S09: show only source metadata actually supplied by Firestore.
class BookKnowledgeScreen extends StatelessWidget {
  final RecipeModel? recipe;
  const BookKnowledgeScreen({super.key, this.recipe});

  @override
  Widget build(BuildContext context) => FlowFrame(
    title: 'S09 • Kiến thức sách',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowSection(
          title: 'Nguồn tham khảo',
          child: Text(
            recipe == null
                ? 'Chọn một công thức từ thư viện để xem thông tin nguồn.'
                : recipe!.sourceNote.trim().isEmpty
                ? 'Chưa có thông tin nguồn đã kiểm chứng.'
                : recipe!.sourceNote,
          ),
        ),
        const Text(
          'Phần này chỉ hiển thị dữ liệu về nguồn đã lưu trong '
          'Firestore. Chưa có số trang hoặc trích dẫn nguyên văn được '
          'kiểm chứng thì ứng dụng không tự tạo trích dẫn.',
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Tra cứu công thức',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecipeCatalogScreen()),
          ),
        ),
      ],
    ),
  );
}
