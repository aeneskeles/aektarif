import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  static const _cacheKey = 'cached_recipes';
  static const _cacheTimestampKey = 'cached_recipes_timestamp';
  static const _cacheDuration = Duration(hours: 24);

  Future<List<Recipe>> loadRecipes() async {
    if (_cachedRecipes != null) return _cachedRecipes!;

    // Try loading from Supabase first
    if (_client != null) {
      try {
        final recipes = await _loadFromSupabase();
        if (recipes.isNotEmpty) {
          _cachedRecipes = recipes;
          await _saveToLocalCache(recipes);
          return _cachedRecipes!;
        }
      } catch (e) {
        // Supabase failed, try local cache
      }
    }

    // Try loading from local cache
    final cachedRecipes = await _loadFromLocalCache();
    if (cachedRecipes.isNotEmpty) {
      _cachedRecipes = cachedRecipes;
      return _cachedRecipes!;
    }

    // Fallback to assets JSON (for backward compatibility)
    try {
      final recipeData = await _ref.read(recipeDataProvider.future);
      _cachedRecipes = recipeData.recipes;
      return _cachedRecipes!;
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> _loadFromSupabase() async {
    if (_client == null) return [];

    final data = await _client!.from('recipes').select();
    return (data as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveToLocalCache(List<Recipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recipes.map((r) => r.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Cache save failed, ignore
    }
  }

  Future<List<Recipe>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      // Check if cache is still valid
      if (cacheAge > _cacheDuration.inMilliseconds) {
        return [];
      }
      
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> refreshRecipes() async {
    _cachedRecipes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await loadRecipes();
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

  Future<Recipe?> getRecipeOfTheDay({int dayOffset = 0}) async {
    final recipes = await loadRecipes();
    if (recipes.isEmpty) return null;

    final targetDate = DateTime.now().add(Duration(days: dayOffset));
    final seed = targetDate.year * 10000 +
        targetDate.month * 100 +
        targetDate.day;
    final random = Random(seed);
    return recipes[random.nextInt(recipes.length)];
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

final recipeOfTheDayProvider =
    FutureProvider.family<Recipe?, int>((ref, dayOffset) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getRecipeOfTheDay(dayOffset: dayOffset);
});

final recipeCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getAllCategories();
});

final recipeSearchProvider = FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.searchRecipes(query);
});
