import 'ingredient_model.dart';

class RecipeModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'ca' (fish), 'dau' (legumes), 'rau_cu' (vegetables), 'ngu_coc' (wholegrains)
  final double proteinGrams;
  final double calories;
  final List<IngredientModel> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  // Provenance text from Firestore. Use [book] only after the exact edition/page
  // has been verified; [web] marks a website source. Unmarked sources are unknown.
  final String sourceNote;
  final bool isArchived;

  /// A populated sourceNote alone does not prove a book citation.
  bool get isBookCitation {
    final note = sourceNote.trimLeft();
    return note.toLowerCase().startsWith('[book] ') &&
        note.substring(7).trim().isNotEmpty;
  }

  const RecipeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.proteinGrams,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.sourceNote =
        '', // Must come from verified Firestore data; never invent a citation.
    this.isArchived = false,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map, String id) {
    return RecipeModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'rau_cu',
      proteinGrams: (map['proteinGrams'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      ingredients:
          (map['ingredients'] as List<dynamic>?)
              ?.map(
                (item) => IngredientModel.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      instructions:
          (map['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: map['imageUrl'] as String?,
      sourceNote: map['sourceNote'] as String? ?? '',
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'proteinGrams': proteinGrams,
      'calories': calories,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'instructions': instructions,
      'imageUrl': imageUrl,
      'sourceNote': sourceNote,
      'isArchived': isArchived,
    };
  }
}
