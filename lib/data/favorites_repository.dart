import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recipe.dart';
import 'recipes_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesRepository {
  static const _boxName = 'favorites';
  static const _favoritesKey = 'favorite_recipe_ids';

  Box get _box => Hive.box(_boxName);

  List<String> getFavoriteIds() {
    final data = _box.get(_favoritesKey);
    if (data == null) return [];
    
    final List<dynamic> ids = jsonDecode(data as String);
    return ids.cast<String>();
  }

  Future<void> addFavorite(String recipeId) async {
    final favorites = getFavoriteIds();
    if (!favorites.contains(recipeId)) {
      favorites.add(recipeId);
      await _saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String recipeId) async {
    final favorites = getFavoriteIds();
    favorites.remove(recipeId);
    await _saveFavorites(favorites);
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (isFavorite(recipeId)) {
      await removeFavorite(recipeId);
    } else {
      await addFavorite(recipeId);
    }
  }

  bool isFavorite(String recipeId) {
    return getFavoriteIds().contains(recipeId);
  }

  Future<void> clearFavorites() async {
    await _box.delete(_favoritesKey);
  }

  Future<void> _saveFavorites(List<String> favorites) async {
    final data = jsonEncode(favorites);
    await _box.put(_favoritesKey, data);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repository);
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier(this._repository) : super(_repository.getFavoriteIds());

  final FavoritesRepository _repository;

  Future<void> toggle(String recipeId) async {
    await _repository.toggleFavorite(recipeId);
    state = _repository.getFavoriteIds();
  }

  Future<void> add(String recipeId) async {
    await _repository.addFavorite(recipeId);
    state = _repository.getFavoriteIds();
  }

  Future<void> remove(String recipeId) async {
    await _repository.removeFavorite(recipeId);
    state = _repository.getFavoriteIds();
  }

  bool isFavorite(String recipeId) {
    return state.contains(recipeId);
  }
}

final favoriteRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider);
  final recipesRepo = ref.watch(recipesRepositoryProvider);
  
  final recipes = <Recipe>[];
  for (final id in favoriteIds) {
    final recipe = await recipesRepo.getRecipeById(id);
    if (recipe != null) {
      recipes.add(recipe);
    }
  }
  return recipes;
});
