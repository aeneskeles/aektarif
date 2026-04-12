class Ingredient {
  const Ingredient({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    this.calorie,
    this.carbohydrates,
    this.protein,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.potassium,
    this.cholesterol,
    this.saturatedFat,
    this.servingSize,
    this.category,
    this.imageUrl,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final double? calorie;
  final double? carbohydrates;
  final double? protein;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final double? potassium;
  final double? cholesterol;
  final double? saturatedFat;
  final double? servingSize;
  final String? category;
  final String? imageUrl;

  String get key => nameTr.toLowerCase();

  String getName(String languageCode) {
    return languageCode == 'tr' ? nameTr : nameEn;
  }

  factory Ingredient.fromFirebaseJson(String id, Map<String, dynamic> json) {
    return Ingredient(
      id: id,
      nameTr: json['Turkish Name'] as String? ?? '',
      nameEn: json['English Name'] as String? ?? '',
      calorie: _parseDouble(json['Calorie']),
      carbohydrates: _parseDouble(json['Carbohydrates']),
      protein: _parseDouble(json['Protein']),
      fat: _parseDouble(json['Fat']),
      fiber: _parseDouble(json['Fiber']),
      sugar: _parseDouble(json['Sugar']),
      sodium: _parseDouble(json['Sodium']),
      potassium: _parseDouble(json['Potassium']),
      cholesterol: _parseDouble(json['Cholesterol']),
      saturatedFat: _parseDouble(json['Saturated Fat']),
      servingSize: _parseDouble(json['Serving Size']),
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String? ?? json['key'] as String,
      nameTr: json['name_tr'] as String? ?? json['nameTr'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String? ?? '',
      calorie: _parseDouble(json['calorie']),
      carbohydrates: _parseDouble(json['carbohydrates']),
      protein: _parseDouble(json['protein']),
      fat: _parseDouble(json['fat']),
      fiber: _parseDouble(json['fiber']),
      sugar: _parseDouble(json['sugar']),
      sodium: _parseDouble(json['sodium']),
      potassium: _parseDouble(json['potassium']),
      cholesterol: _parseDouble(json['cholesterol']),
      saturatedFat: _parseDouble(json['saturated_fat']),
      servingSize: _parseDouble(json['serving_size']),
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_tr': nameTr,
      'name_en': nameEn,
      'calorie': calorie,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'potassium': potassium,
      'cholesterol': cholesterol,
      'saturated_fat': saturatedFat,
      'serving_size': servingSize,
      'category': category,
      'image_url': imageUrl,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.ingredientName,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.addedAt,
  });

  final String id;
  final String ingredientName;
  final double? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final DateTime? addedAt;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      ingredientName: json['ingredient_name'] as String? ?? json['ingredient_key'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.toIso8601String(),
      'added_at': addedAt?.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? ingredientName,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? addedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class DetectedIngredient {
  final String label;
  final double confidence;
  final BoundingBox? bbox;

  DetectedIngredient({
    required this.label,
    required this.confidence,
    this.bbox,
  });

  String get ingredientKey => label.toLowerCase();

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: json['bbox'] != null
          ? BoundingBox.fromJson(json['bbox'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'bbox': bbox?.toJson(),
    };
  }
}

class BoundingBox {
  final double x1, y1, x2, y2;

  BoundingBox(this.x1, this.y1, this.x2, this.y2);

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      (json['x1'] as num).toDouble(),
      (json['y1'] as num).toDouble(),
      (json['x2'] as num).toDouble(),
      (json['y2'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    };
  }
}
