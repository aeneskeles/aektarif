import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/recipe.dart';
import '../providers/supabase_provider.dart';
import 'recipes_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FavoritesRepository(client);
});

class FavoritesRepository {
  FavoritesRepository(this._client);

  final SupabaseClient? _client;
  static const _boxName = 'favorites';
  static const _tableName = 'favorites';

  Box get _box => Hive.box(_boxName);

  String? get _userId => _client?.auth.currentUser?.id;

  String get _localKey => 'favorite_recipe_ids_${_userId ?? 'guest'}';

  Future<List<String>> getFavoriteIds() async {
    if (_client != null && _userId != null && SupabaseConfig.isConfigured) {
      try {
        final response = await _client!
            .from(_tableName)
            .select('recipe_id')
            .eq('user_id', _userId!);

        final ids = (response as List)
            .map((e) => e['recipe_id'] as String)
            .toList();
        
        await _saveToLocal(ids);
        return ids;
      } catch (e) {
        return _getFromLocal();
      }
    }
    return _getFromLocal();
  }

  List<String> _getFromLocal() {
    final data = _box.get(_localKey);
    if (data == null) return [];
    
    final List<dynamic> ids = jsonDecode(data as String);
    return ids.cast<String>();
  }

  Future<void> _saveToLocal(List<String> favorites) async {
    final data = jsonEncode(favorites);
    await _box.put(_localKey, data);
  }

  Future<void> addFavorite(String recipeId) async {
    if (_client != null && _userId != null && SupabaseConfig.isConfigured) {
      try {
        await _client!.from(_tableName).upsert({
          'user_id': _userId!,
          'recipe_id': recipeId,
        });
      } catch (e) {
        // Fallback to local
      }
    }
    
    final favorites = _getFromLocal();
    if (!favorites.contains(recipeId)) {
      favorites.add(recipeId);
      await _saveToLocal(favorites);
    }
  }

  Future<void> removeFavorite(String recipeId) async {
    if (_client != null && _userId != null && SupabaseConfig.isConfigured) {
      try {
        await _client!
            .from(_tableName)
            .delete()
            .eq('user_id', _userId!)
            .eq('recipe_id', recipeId);
      } catch (e) {
        // Fallback to local
      }
    }
    
    final favorites = _getFromLocal();
    favorites.remove(recipeId);
    await _saveToLocal(favorites);
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (await isFavorite(recipeId)) {
      await removeFavorite(recipeId);
    } else {
      await addFavorite(recipeId);
    }
  }

  Future<bool> isFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(recipeId);
  }

  Future<void> clearFavorites() async {
    if (_client != null && _userId != null && SupabaseConfig.isConfigured) {
      try {
        await _client!
            .from(_tableName)
            .delete()
            .eq('user_id', _userId!);
      } catch (e) {
        // Fallback to local
      }
    }
    await _box.delete(_localKey);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repository);
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier(this._repository) : super([]) {
    _init();
  }

  final FavoritesRepository _repository;

  Future<void> _init() async {
    state = await _repository.getFavoriteIds();
  }

  Future<void> refresh() async {
    state = await _repository.getFavoriteIds();
  }

  Future<void> toggle(String recipeId) async {
    await _repository.toggleFavorite(recipeId);
    state = await _repository.getFavoriteIds();
  }

  Future<void> add(String recipeId) async {
    await _repository.addFavorite(recipeId);
    state = await _repository.getFavoriteIds();
  }

  Future<void> remove(String recipeId) async {
    await _repository.removeFavorite(recipeId);
    state = await _repository.getFavoriteIds();
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
