import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import '../providers/supabase_provider.dart';
import 'ingredients_repository.dart';
import 'recommendation_engine.dart';

final recipesRepositoryProvider = Provider<RecipesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecipesRepository(client, ref);
});

class RecipesRepository {
  RecipesRepository(this._client, this._ref);

  final SupabaseClient? _client;
  final Ref _ref;
  List<Recipe>? _cachedRecipes;

  Future<List<Recipe>> loadRecipes() async {
    if (_cachedRecipes != null) return _cachedRecipes!;

    try {
      final recipeData = await _ref.read(recipeDataProvider.future);
      _cachedRecipes = recipeData.recipes;
      return _cachedRecipes!;
    } catch (e) {
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    final recipes = await loadRecipes();
    try {
      return recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<RecipeRecommendation>> getRecommendations(Set<String> userIngredients) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getRecommendations(
      recipes: recipes,
      userIngredients: userIngredients,
      limit: 30,
      minMatchScore: 0.3,
    );
  }

  Future<List<RecipeRecommendation>> getFullMatchRecipes(Set<String> userIngredients) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getFullMatchRecipes(
      recipes: recipes,
      userIngredients: userIngredients,
    );
  }

  Future<List<RecipeRecommendation>> getAlmostMatchRecipes(
    Set<String> userIngredients, {
    int maxMissing = 3,
  }) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getAlmostMatchRecipes(
      recipes: recipes,
      userIngredients: userIngredients,
      maxMissing: maxMissing,
    );
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.searchRecipes(
      recipes: recipes,
      query: query,
    );
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getRecipesByCategory(
      recipes: recipes,
      category: category,
    );
  }

  Future<List<Recipe>> getRandomRecipes({int count = 5}) async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getRandomRecipes(recipes: recipes, count: count);
  }

  Future<Recipe?> getRecipeOfTheDay() async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getRecipeOfTheDay(recipes);
  }

  Future<Set<String>> getAllCategories() async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getAllCategories(recipes);
  }

  Future<Set<String>> getAllCuisines() async {
    final recipes = await loadRecipes();
    final engine = _ref.read(recommendationEngineProvider);
    
    return engine.getAllCuisines(recipes);
  }

  Future<List<Recipe>> loadRemoteRecipes() async {
    if (_client == null) return [];

    try {
      final data = await _client!.from('recipes').select();
      return (data as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

final recipeRecommendationsProvider = FutureProvider<List<RecipeRecommendation>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  final inventoryKeys = ref.watch(inventoryKeysProvider);
  
  if (inventoryKeys.isEmpty) return [];
  
  return repository.getRecommendations(inventoryKeys);
});

final fullMatchRecipesProvider = FutureProvider<List<RecipeRecommendation>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  final inventoryKeys = ref.watch(inventoryKeysProvider);
  
  if (inventoryKeys.isEmpty) return [];
  
  return repository.getFullMatchRecipes(inventoryKeys);
});

final almostMatchRecipesProvider = FutureProvider<List<RecipeRecommendation>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  final inventoryKeys = ref.watch(inventoryKeysProvider);
  
  if (inventoryKeys.isEmpty) return [];
  
  return repository.getAlmostMatchRecipes(inventoryKeys, maxMissing: 3);
});

final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.loadRecipes();
});

final recipeProvider = FutureProvider.family<Recipe?, String>((ref, id) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getRecipeById(id);
});

final recipeOfTheDayProvider = FutureProvider<Recipe?>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getRecipeOfTheDay();
});

final recipeCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getAllCategories();
});

final recipeSearchProvider = FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.searchRecipes(query);
});
