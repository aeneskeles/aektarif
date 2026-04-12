import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import '../models/ingredient.dart';

final recipeDataProvider = FutureProvider<RecipeData>((ref) async {
  final jsonString = await rootBundle.loadString('assets/recipe_data.json');
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  return RecipeData.fromJson(data);
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

class RecipeData {
  final List<Recipe> recipes;
  final List<Ingredient> ingredients;
  final Map<String, Ingredient> ingredientMap;

  RecipeData({
    required this.recipes,
    required this.ingredients,
    required this.ingredientMap,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) {
    final ingredientJson = json['Ingredient'] as Map<String, dynamic>? ?? {};
    final recipeJson = json['Recipe'] as Map<String, dynamic>? ?? {};

    final ingredients = <Ingredient>[];
    final ingredientMap = <String, Ingredient>{};

    ingredientJson.forEach((id, data) {
      if (data is Map<String, dynamic>) {
        final ingredient = Ingredient.fromFirebaseJson(id, data);
        ingredients.add(ingredient);
        ingredientMap[ingredient.nameTr.toLowerCase()] = ingredient;
      }
    });

    final recipes = <Recipe>[];
    recipeJson.forEach((id, data) {
      if (data is Map<String, dynamic>) {
        try {
          recipes.add(Recipe.fromFirebaseJson(id, data));
        } catch (e) {
          // Skip invalid recipes
        }
      }
    });

    return RecipeData(
      recipes: recipes,
      ingredients: ingredients,
      ingredientMap: ingredientMap,
    );
  }
}

class RecommendationEngine {
  List<RecipeRecommendation> getRecommendations({
    required List<Recipe> recipes,
    required Set<String> userIngredients,
    int limit = 20,
    double minMatchScore = 0.3,
    String? category,
    String? cuisine,
  }) {
    if (userIngredients.isEmpty) {
      return [];
    }

    final normalizedUserIngredients = userIngredients
        .map((e) => _normalizeIngredient(e))
        .toSet();

    final recommendations = <RecipeRecommendation>[];

    for (final recipe in recipes) {
      if (category != null && 
          recipe.category?.toLowerCase() != category.toLowerCase()) {
        continue;
      }
      if (cuisine != null && 
          recipe.cuisine?.toLowerCase() != cuisine.toLowerCase()) {
        continue;
      }

      final matchResult = _calculateMatch(
        recipe.ingredientNames,
        normalizedUserIngredients,
      );

      if (matchResult.score >= minMatchScore) {
        recommendations.add(RecipeRecommendation(
          recipe: recipe,
          matchCount: matchResult.matchedIngredients.length,
          totalIngredients: recipe.ingredientNames.length,
          matchedIngredients: matchResult.matchedIngredients,
          missingIngredients: matchResult.missingIngredients,
          matchScore: matchResult.score,
        ));
      }
    }

    recommendations.sort((a, b) {
      final scoreCompare = b.matchScore.compareTo(a.matchScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.missingCount.compareTo(b.missingCount);
    });

    return recommendations.take(limit).toList();
  }

  List<RecipeRecommendation> getFullMatchRecipes({
    required List<Recipe> recipes,
    required Set<String> userIngredients,
    int limit = 10,
  }) {
    return getRecommendations(
      recipes: recipes,
      userIngredients: userIngredients,
      limit: limit,
      minMatchScore: 1.0,
    );
  }

  List<RecipeRecommendation> getAlmostMatchRecipes({
    required List<Recipe> recipes,
    required Set<String> userIngredients,
    int maxMissing = 3,
    int limit = 20,
  }) {
    final allRecommendations = getRecommendations(
      recipes: recipes,
      userIngredients: userIngredients,
      limit: 100,
      minMatchScore: 0.5,
    );

    return allRecommendations
        .where((r) => r.missingCount > 0 && r.missingCount <= maxMissing)
        .take(limit)
        .toList();
  }

  List<Recipe> searchRecipes({
    required List<Recipe> recipes,
    required String query,
    int limit = 20,
  }) {
    if (query.isEmpty) return recipes.take(limit).toList();

    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));

    final scored = <_ScoredRecipe>[];

    for (final recipe in recipes) {
      double score = 0;

      final name = recipe.name.toLowerCase();
      if (name.contains(normalizedQuery)) {
        score += 10;
      }
      for (final word in queryWords) {
        if (name.contains(word)) score += 2;
      }

      final description = recipe.shortDescription.toLowerCase();
      if (description.contains(normalizedQuery)) {
        score += 3;
      }

      for (final keyword in recipe.keywords ?? []) {
        if (keyword.toLowerCase().contains(normalizedQuery)) {
          score += 5;
        }
      }

      final category = recipe.category?.toLowerCase() ?? '';
      if (category.contains(normalizedQuery)) {
        score += 4;
      }

      for (final ingredient in recipe.ingredientNames) {
        if (ingredient.contains(normalizedQuery)) {
          score += 1;
        }
      }

      if (score > 0) {
        scored.add(_ScoredRecipe(recipe, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((e) => e.recipe).toList();
  }

  List<Recipe> getRecipesByCategory({
    required List<Recipe> recipes,
    required String category,
    int limit = 20,
  }) {
    return recipes
        .where((r) => r.category?.toLowerCase() == category.toLowerCase() ||
                      r.categoryBread?.toLowerCase().contains(category.toLowerCase()) == true)
        .take(limit)
        .toList();
  }

  List<Recipe> getRandomRecipes({
    required List<Recipe> recipes,
    int count = 5,
  }) {
    if (recipes.isEmpty) return [];
    
    final random = Random();
    final shuffled = List<Recipe>.from(recipes)..shuffle(random);
    return shuffled.take(min(count, recipes.length)).toList();
  }

  Recipe? getRecipeOfTheDay(List<Recipe> recipes) {
    if (recipes.isEmpty) return null;
    
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);
    
    return recipes[random.nextInt(recipes.length)];
  }

  Set<String> getAllCategories(List<Recipe> recipes) {
    final categories = <String>{};
    for (final recipe in recipes) {
      if (recipe.category != null && recipe.category!.isNotEmpty) {
        categories.add(recipe.category!);
      }
    }
    return categories;
  }

  Set<String> getAllCuisines(List<Recipe> recipes) {
    final cuisines = <String>{};
    for (final recipe in recipes) {
      if (recipe.cuisine != null && recipe.cuisine!.isNotEmpty) {
        cuisines.add(recipe.cuisine!);
      }
    }
    return cuisines;
  }

  _MatchResult _calculateMatch(
    List<String> recipeIngredients,
    Set<String> userIngredients,
  ) {
    final matched = <String>[];
    final missing = <String>[];

    for (final ingredient in recipeIngredients) {
      final normalized = _normalizeIngredient(ingredient);
      
      bool found = false;
      for (final userIng in userIngredients) {
        if (_ingredientsMatch(normalized, userIng)) {
          found = true;
          break;
        }
      }

      if (found) {
        matched.add(ingredient);
      } else {
        missing.add(ingredient);
      }
    }

    final total = recipeIngredients.length;
    final score = total > 0 ? matched.length / total : 0.0;

    return _MatchResult(
      matchedIngredients: matched,
      missingIngredients: missing,
      score: score,
    );
  }

  String _normalizeIngredient(String ingredient) {
    var normalized = ingredient.toLowerCase().trim();
    
    normalized = normalized
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'(gram|gr|kg|adet|bardak|kaşık|dilim|demet|diş|boy|orta|büyük|küçük|tane)'), '')
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  bool _ingredientsMatch(String ing1, String ing2) {
    if (ing1 == ing2) return true;
    if (ing1.contains(ing2) || ing2.contains(ing1)) return true;
    
    final words1 = ing1.split(' ').where((w) => w.length > 2).toSet();
    final words2 = ing2.split(' ').where((w) => w.length > 2).toSet();
    
    final commonWords = words1.intersection(words2);
    if (commonWords.isNotEmpty) {
      final minWords = min(words1.length, words2.length);
      if (minWords > 0 && commonWords.length / minWords >= 0.5) {
        return true;
      }
    }

    final synonyms = _ingredientSynonyms;
    for (final synonymGroup in synonyms) {
      final hasIng1 = synonymGroup.any((s) => ing1.contains(s) || s.contains(ing1));
      final hasIng2 = synonymGroup.any((s) => ing2.contains(s) || s.contains(ing2));
      if (hasIng1 && hasIng2) return true;
    }

    return false;
  }

  static final List<Set<String>> _ingredientSynonyms = [
    {'soğan', 'kuru soğan', 'büyük boy soğan', 'küçük boy soğan', 'orta boy soğan'},
    {'domates', 'çeri domates', 'salkım domates'},
    {'biber', 'sivri biber', 'dolmalık biber', 'kapya biber', 'çarliston biber'},
    {'peynir', 'beyaz peynir', 'kaşar peyniri', 'tulum peyniri', 'lor peyniri'},
    {'yağ', 'sıvı yağ', 'zeytinyağı', 'ayçiçek yağı', 'tereyağı'},
    {'et', 'dana eti', 'kuzu eti', 'kıyma', 'dana kıyma', 'kuzu kıyma'},
    {'tavuk', 'tavuk göğsü', 'tavuk but', 'tavuk kanat'},
    {'un', 'buğday unu', 'tam buğday unu', 'mısır unu'},
    {'süt', 'tam yağlı süt', 'yarım yağlı süt'},
    {'yoğurt', 'süzme yoğurt', 'tam yağlı yoğurt'},
    {'sarımsak', 'diş sarımsak'},
    {'maydanoz', 'taze maydanoz'},
    {'dereotu', 'taze dereotu'},
    {'nane', 'taze nane', 'kuru nane'},
  ];
}

class _MatchResult {
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final double score;

  _MatchResult({
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.score,
  });
}

class _ScoredRecipe {
  final Recipe recipe;
  final double score;

  _ScoredRecipe(this.recipe, this.score);
}
