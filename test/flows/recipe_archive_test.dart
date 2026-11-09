import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/services/data_service.dart';

// PR #27 review: staff archive recipes (isArchived) instead of deleting them,
// so Mobile must drop archived recipes from the catalogue it builds plans from.
void main() {
  Map<String, dynamic> recipeMap({Object? isArchived}) => {
    'name': 'Canh đậu hũ',
    'description': '',
    'category': 'dau',
    'proteinGrams': 18,
    'calories': 210,
    'ingredients': const [],
    'instructions': const ['Bước 1'],
    'sourceNote': 'Nguồn test',
    'isArchived': ?isArchived,
  };

  group('RecipeModel.isArchived', () {
    test('a recipe without the field is active', () {
      expect(RecipeModel.fromMap(recipeMap(), 'r1').isArchived, isFalse);
    });

    test('reads true and false from Firestore', () {
      expect(
        RecipeModel.fromMap(recipeMap(isArchived: true), 'r1').isArchived,
        isTrue,
      );
      expect(
        RecipeModel.fromMap(recipeMap(isArchived: false), 'r1').isArchived,
        isFalse,
      );
    });

    test('round-trips through toMap', () {
      final archived = RecipeModel.fromMap(recipeMap(isArchived: true), 'r1');
      expect(archived.toMap()['isArchived'], isTrue);
    });
  });

  group('DataService.activeRecipes', () {
    test('drops archived recipes and keeps the order of the rest', () {
      final recipes = [
        RecipeModel.fromMap(recipeMap(), 'a'),
        RecipeModel.fromMap(recipeMap(isArchived: true), 'b'),
        RecipeModel.fromMap(recipeMap(isArchived: false), 'c'),
      ];
      expect(DataService.activeRecipes(recipes).map((r) => r.id), ['a', 'c']);
    });

    test('an all-archived catalogue is a real empty list', () {
      final recipes = [RecipeModel.fromMap(recipeMap(isArchived: true), 'b')];
      expect(DataService.activeRecipes(recipes), isEmpty);
    });
  });
}
