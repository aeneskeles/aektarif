class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.ingredientNames,
    required this.ingredientsRaw,
    required this.steps,
    this.imageUrl,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.difficulty,
    this.category,
    this.categoryBread,
    this.cuisine,
    this.keywords,
  });

  final String id;
  final String name;
  final String shortDescription;
  final List<String> ingredientNames;
  final List<String> ingredientsRaw;
  final List<RecipeStep> steps;
  final String? imageUrl;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? difficulty;
  final String? category;
  final String? categoryBread;
  final String? cuisine;
  final List<String>? keywords;

  int get totalTime => (prepTime ?? 0) + (cookTime ?? 0);

  factory Recipe.fromFirebaseJson(String id, Map<String, dynamic> json) {
    final prepDetails = (json['PrepDetails'] as String?)?.split(';') ?? [];
    
    int? servings;
    int? prepTime;
    int? cookTime;
    
    if (prepDetails.isNotEmpty) {
      final servingsStr = prepDetails[0].replaceAll(RegExp(r'[^0-9]'), '');
      if (servingsStr.isNotEmpty) {
        servings = int.tryParse(servingsStr);
      }
    }
    if (prepDetails.length > 1) {
      final prepTimeStr = prepDetails[1].replaceAll(RegExp(r'[^0-9]'), '');
      if (prepTimeStr.isNotEmpty) {
        prepTime = int.tryParse(prepTimeStr);
      }
    }
    if (prepDetails.length > 2) {
      final cookTimeStr = prepDetails[2].replaceAll(RegExp(r'[^0-9]'), '');
      if (cookTimeStr.isNotEmpty) {
        cookTime = int.tryParse(cookTimeStr);
      }
    }

    final ingredientNamesRaw = (json['IngridientNames'] as String?) ?? '';
    final ingredientNames = ingredientNamesRaw
        .split(';')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final ingredientsRaw = (json['Ingridients'] as String?)
            ?.split('\n')
            .map((e) => e.replaceAll('●', '').trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final recipeDetails = (json['RecipeDetails'] as String?) ?? '';
    final stepTexts = recipeDetails
        .split(RegExp(r'\d+\.\)'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final steps = <RecipeStep>[];
    for (int i = 0; i < stepTexts.length; i++) {
      steps.add(RecipeStep(
        order: i + 1,
        instructionTr: stepTexts[i],
        instructionEn: stepTexts[i],
      ));
    }

    final keywordsRaw = (json['Keywords'] as String?) ?? '';
    final keywords = keywordsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Recipe(
      id: id,
      name: json['Name'] as String? ?? 'Tarif',
      shortDescription: json['ShortDescription'] as String? ?? '',
      ingredientNames: ingredientNames,
      ingredientsRaw: ingredientsRaw,
      steps: steps,
      imageUrl: json['Image'] as String?,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      category: json['MainCategory'] as String?,
      categoryBread: json['CategoryBread'] as String?,
      cuisine: json['Cuisine'] as String?,
      keywords: keywords.isNotEmpty ? keywords : null,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse steps from steps_tr (Supabase) or steps (local)
    List<RecipeStep> parsedSteps = [];
    final stepsData = json['steps_tr'] ?? json['steps'];
    if (stepsData is List) {
      parsedSteps = stepsData.map((e) {
        if (e is Map<String, dynamic>) {
          return RecipeStep.fromJson(e);
        }
        return RecipeStep(order: 0, instructionTr: e.toString(), instructionEn: '');
      }).toList();
    }

    // Parse tags from tags (Supabase) or keywords (local)
    List<String>? parsedTags;
    final tagsData = json['tags'] ?? json['keywords'];
    if (tagsData is List) {
      parsedTags = tagsData.cast<String>();
    }

    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['title_tr'] as String? ?? 'Tarif',
      shortDescription: json['short_description'] as String? ?? json['description_tr'] as String? ?? '',
      ingredientNames: List<String>.from(json['ingredient_names'] ?? json['ingredient_keys'] ?? []),
      ingredientsRaw: List<String>.from(json['ingredients_raw'] ?? []),
      steps: parsedSteps,
      imageUrl: json['image_url'] as String?,
      prepTime: json['prep_time'] as int?,
      cookTime: json['cook_time'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      category: json['category'] as String?,
      categoryBread: json['category_bread'] as String?,
      cuisine: json['cuisine'] as String?,
      keywords: parsedTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_description': shortDescription,
      'ingredient_names': ingredientNames,
      'ingredients_raw': ingredientsRaw,
      'steps': steps.map((e) => e.toJson()).toList(),
      'image_url': imageUrl,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'category': category,
      'category_bread': categoryBread,
      'cuisine': cuisine,
      'keywords': keywords,
    };
  }
}

class RecipeStep {
  const RecipeStep({
    required this.order,
    required this.instructionTr,
    required this.instructionEn,
    this.imageUrl,
    this.duration,
    this.tip,
  });

  final int order;
  final String instructionTr;
  final String instructionEn;
  final String? imageUrl;
  final int? duration;
  final String? tip;

  int? get durationMinutes => duration != null ? (duration! / 60).ceil() : null;

  String getInstruction(String languageCode) {
    return languageCode == 'tr' ? instructionTr : instructionEn;
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      order: json['order'] as int? ?? 0,
      instructionTr: json['instruction_tr'] as String? ?? json['instruction'] as String? ?? '',
      instructionEn: json['instruction_en'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      duration: json['duration'] as int?,
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'instruction_tr': instructionTr,
      'instruction_en': instructionEn,
      'image_url': imageUrl,
      'duration': duration,
      'tip': tip,
    };
  }
}

class RecipeRecommendation {
  const RecipeRecommendation({
    required this.recipe,
    required this.matchCount,
    required this.totalIngredients,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.matchScore,
  });

  final Recipe recipe;
  final int matchCount;
  final int totalIngredients;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final double matchScore;

  int get missingCount => missingIngredients.length;
  bool get isFullMatch => missingCount == 0;
}
