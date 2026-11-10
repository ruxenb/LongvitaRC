import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/models/recipe_model.dart';
import 'package:longvita_core/models/view_state.dart';
import 'package:longvita/screens/recipe_flow_screens.dart';
import 'package:longvita_core/theme/app_theme.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';

/// Dữ liệu mẫu công thức kèm trích dẫn nguồn sách TS. Valter Longo
const mockRecipeS09 = RecipeModel(
  id: 'recipe_lentil_squash',
  name: 'Warm lentil and roasted squash',
  description: 'Món ăn trường thọ kết hợp đậu lăng và bí đỏ nướng thảo mộc Địa Trung Hải.',
  category: 'dau',
  calories: 420.0,
  proteinGrams: 32.0,
  ingredients: [],
  instructions: [],
  sourceNote: 'The Longevity Diet · Appendix A and nutrition principles used by Longvita.',
);

/// Mock ViewModel hỗ trợ nút 'Tra cứu công thức' hoạt động an toàn
class MockMealPlanViewModel extends ChangeNotifier
    implements MealPlanViewModel {
  final ViewState<List<RecipeModel>> _recipesState = const ViewStateSuccess([
    mockRecipeS09,
  ]);

  @override
  ViewState<List<RecipeModel>> get recipesState => _recipesState;

  @override
  Future<void> searchRecipes(String query) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  runApp(const PreviewS09App());
}

class PreviewS09App extends StatelessWidget {
  const PreviewS09App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MealPlanViewModel>(
      create: (_) => MockMealPlanViewModel(),
      child: MaterialApp(
        title: 'Preview S09: Kiến thức sách',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const BookKnowledgeScreen(recipe: mockRecipeS09),
      ),
    );
  }
}
