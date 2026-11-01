class IngredientModel {
  final String id;
  final String name;
  final double amount;
  final String unit; // 'g', 'ml', 'thìa', 'quả', 'miếng'
  final String category; // 'rau củ', 'đậu', 'cá', 'dầu hạt', 'gia vị'
  final bool isPurchased;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.category = 'khác',
    this.isPurchased = false,
  });

  factory IngredientModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return IngredientModel(
      id: id ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'g',
      category: map['category'] as String? ?? 'khác',
      isPurchased: map['isPurchased'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'category': category,
      'isPurchased': isPurchased,
    };
  }

  IngredientModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    String? category,
    bool? isPurchased,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
