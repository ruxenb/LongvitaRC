import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/recipe_model.dart';

void main() {
  RecipeModel candidate(String note) => RecipeModel(
    id: 'source-test',
    name: 'Source test',
    description: 'Synthetic source test only',
    category: 'ngu_coc',
    proteinGrams: 0,
    calories: 0,
    ingredients: const [],
    instructions: const [],
    sourceNote: note,
  );

  test('verified-format book reference is explicitly book-marked', () {
    expect(
      candidate('[book] Valter Longo, The Longevity Diet, appendix A, p. 222')
          .isBookCitation,
      isTrue,
    );
    expect(candidate(' [BOOK] edition and page verified').isBookCitation, isTrue);
  });

  test('website references must not count as a book citation', () {
    expect(
      candidate('[web] Valter Longo Foundation; https://example.org/recipes')
          .isBookCitation,
      isFalse,
    );
    expect(
      candidate('Valter Longo Foundation online recipe').isBookCitation,
      isFalse,
    );
  });

  test('unmarked, empty and incomplete labels do not invent attribution', () {
    expect(candidate('').isBookCitation, isFalse);
    expect(candidate('Nguồn Firestore').isBookCitation, isFalse);
    expect(candidate('[book]').isBookCitation, isFalse);
    expect(candidate('[book] ').isBookCitation, isFalse);
  });

  test('Firestore decode preserves source label for analytics', () {
    final model = RecipeModel.fromMap({
      'name': 'Test',
      'sourceNote': '[web] verified foundation reference',
    }, 'id');
    expect(model.isBookCitation, isFalse);
    expect(model.sourceNote, contains('[web]'));
  });
}
