import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/ingredient_model.dart';
import 'models/recipe_model.dart';
import 'models/view_state.dart';
import 'screens/recipe_flow_screens.dart';
import 'theme/app_theme.dart';
import 'viewmodels/meal_plan_viewmodel.dart';

/// Danh sách 3 món thay thế khớp 100% bản Figma của bạn:
final mockAlternatives = [
  const RecipeModel(
    id: 'alt_wild_rice',
    name: 'Wild rice vegetable bowl',
    description: 'Whole-grain swap with similar balance.',
    category: 'ngu_coc',
    proteinGrams: 28.0,
    calories: 410.0,
    ingredients: [],
    instructions: ['Cook wild rice.', 'Sauté seasonal vegetables.'],
    sourceNote: '[book] La dieta della longevità — TS. Valter Longo',
  ),
  const RecipeModel(
    id: 'alt_farro_bean',
    name: 'Farro and bean salad',
    description: 'Plant-rich alternative with familiar ingredients.',
    category: 'dau',
    proteinGrams: 26.0,
    calories: 385.0,
    ingredients: [],
    instructions: ['Toss boiled farro and white beans with EVOO.'],
    sourceNote: '[web] Valter Longo Foundation Mediterranean Recipes',
  ),
  const RecipeModel(
    id: 'alt_barley_mushroom',
    name: 'Barley mushroom bowl',
    description: 'Equivalent whole-grain substitution.',
    category: 'ngu_coc',
    proteinGrams: 24.0,
    calories: 395.0,
    ingredients: [],
    instructions: ['Simmer pearl barley.', 'Pan-sear mushrooms with garlic.'],
    sourceNote: '[book] La dieta della longevità — TS. Valter Longo',
  ),
];

/// Món gốc cần thay đổi (từ S05)
const mockOriginalRecipe = RecipeModel(
  id: 'recipe_lentil_squash',
  name: 'Warm lentil and roasted squash',
  description: 'Kept if you cancel or an update fails.',
  category: 'dau',
  calories: 420.0,
  proteinGrams: 32.0,
  ingredients: [],
  instructions: [],
  sourceNote: '[book] La dieta della longevità',
);

/// Mock ViewModel cho S06: mô phỏng nạp món thay thế và thao tác đổi món
class MockMealPlanViewModel extends ChangeNotifier
    implements MealPlanViewModel {
  ViewState<List<RecipeModel>> _alternativesState =
      ViewStateSuccess(mockAlternatives);
  ViewState<bool> _replaceState = const ViewStateIdle();

  @override
  ViewState<List<RecipeModel>> get alternativesState => _alternativesState;

  @override
  ViewState<bool> get replaceState => _replaceState;

  @override
  Future<void> loadAlternatives(RecipeModel original) async {
    _alternativesState = const ViewStateLoading();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _alternativesState = ViewStateSuccess(mockAlternatives);
    notifyListeners();
  }

  @override
  Future<bool> replaceMeal({
    required int dayIndex,
    required String originalId,
    required RecipeModel replacement,
  }) async {
    _replaceState = const ViewStateLoading();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _replaceState = const ViewStateSuccess(true);
    notifyListeners();
    return true;
  }

  void setEmptyState() {
    _alternativesState = const ViewStateEmpty();
    notifyListeners();
  }

  void setDataState() {
    _alternativesState = ViewStateSuccess(mockAlternatives);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  runApp(const PreviewS06App());
}

class PreviewS06App extends StatelessWidget {
  const PreviewS06App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MealPlanViewModel>(
      create: (_) => MockMealPlanViewModel(),
      child: MaterialApp(
        title: 'Preview S06: Meal alternatives',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MealAlternativesScreen(
          original: mockOriginalRecipe,
          dayIndex: 1,
        ),
      ),
    );
  }
}
