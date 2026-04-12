import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/ingredient.dart';
import 'recommendation_engine.dart';

final ingredientsRepositoryProvider = Provider<IngredientsRepository>((ref) {
  return IngredientsRepository(ref);
});

class IngredientsRepository {
  IngredientsRepository(this._ref);
  
  final Ref _ref;
  static const _boxName = 'ingredients';
  static const _inventoryKey = 'inventory';
  
  Box get _box => Hive.box(_boxName);
  final _uuid = const Uuid();

  Future<List<Ingredient>> getAllIngredients() async {
    try {
      final recipeData = await _ref.read(recipeDataProvider.future);
      return recipeData.ingredients;
    } catch (e) {
      return [];
    }
  }

  Future<Ingredient?> getIngredientByName(String name) async {
    try {
      final recipeData = await _ref.read(recipeDataProvider.future);
      final normalizedName = name.toLowerCase().trim();
      return recipeData.ingredientMap[normalizedName];
    } catch (_) {
      return null;
    }
  }

  Future<String> getIngredientName(String key, {String languageCode = 'tr'}) async {
    final ingredient = await getIngredientByName(key);
    if (ingredient == null) return key;
    return ingredient.getName(languageCode);
  }

  Future<List<Ingredient>> searchIngredients(String query, {String languageCode = 'tr'}) async {
    final ingredients = await getAllIngredients();
    if (query.isEmpty) return ingredients;
    
    final lowerQuery = query.toLowerCase();
    return ingredients.where((i) {
      final name = languageCode == 'tr' ? i.nameTr : i.nameEn;
      return name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<InventoryItem> getInventory() {
    final data = _box.get(_inventoryKey);
    if (data == null) return [];
    
    final List<dynamic> items = jsonDecode(data as String);
    return items.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InventoryItem> addToInventory({
    required String ingredientName,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
  }) async {
    final inventory = getInventory();
    
    final item = InventoryItem(
      id: _uuid.v4(),
      ingredientName: ingredientName.toLowerCase().trim(),
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
      addedAt: DateTime.now(),
    );
    
    inventory.add(item);
    await _saveInventory(inventory);
    
    return item;
  }

  Future<List<InventoryItem>> addMultipleToInventory(List<String> ingredientNames) async {
    final inventory = getInventory();
    final existingNames = inventory.map((e) => e.ingredientName.toLowerCase()).toSet();
    final newItems = <InventoryItem>[];
    
    for (final name in ingredientNames) {
      final normalizedName = name.toLowerCase().trim();
      if (!existingNames.contains(normalizedName) && normalizedName.isNotEmpty) {
        final item = InventoryItem(
          id: _uuid.v4(),
          ingredientName: normalizedName,
          addedAt: DateTime.now(),
        );
        inventory.add(item);
        newItems.add(item);
        existingNames.add(normalizedName);
      }
    }
    
    await _saveInventory(inventory);
    return newItems;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final inventory = getInventory();
    final index = inventory.indexWhere((e) => e.id == item.id);
    
    if (index != -1) {
      inventory[index] = item;
      await _saveInventory(inventory);
    }
  }

  Future<void> removeFromInventory(String itemId) async {
    final inventory = getInventory();
    inventory.removeWhere((e) => e.id == itemId);
    await _saveInventory(inventory);
  }

  Future<void> clearInventory() async {
    await _box.delete(_inventoryKey);
  }

  bool isInInventory(String ingredientName) {
    final inventory = getInventory();
    final normalized = ingredientName.toLowerCase().trim();
    return inventory.any((e) => e.ingredientName.toLowerCase() == normalized);
  }

  Set<String> getInventoryNames() {
    return getInventory().map((e) => e.ingredientName.toLowerCase()).toSet();
  }

  Future<void> _saveInventory(List<InventoryItem> inventory) async {
    final data = jsonEncode(inventory.map((e) => e.toJson()).toList());
    await _box.put(_inventoryKey, data);
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  final repository = ref.watch(ingredientsRepositoryProvider);
  return InventoryNotifier(repository);
});

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  InventoryNotifier(this._repository) : super(_repository.getInventory());

  final IngredientsRepository _repository;

  Future<void> addItem({
    required String ingredientName,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
  }) async {
    await _repository.addToInventory(
      ingredientName: ingredientName,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
    );
    state = _repository.getInventory();
  }

  Future<void> addMultiple(List<String> ingredientNames) async {
    await _repository.addMultipleToInventory(ingredientNames);
    state = _repository.getInventory();
  }

  Future<void> removeItem(String itemId) async {
    await _repository.removeFromInventory(itemId);
    state = _repository.getInventory();
  }

  Future<void> updateItem(InventoryItem item) async {
    await _repository.updateInventoryItem(item);
    state = _repository.getInventory();
  }

  Future<void> clear() async {
    await _repository.clearInventory();
    state = [];
  }

  void refresh() {
    state = _repository.getInventory();
  }
}

final inventoryKeysProvider = Provider<Set<String>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.map((e) => e.ingredientName.toLowerCase()).toSet();
});

final allIngredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  final repository = ref.watch(ingredientsRepositoryProvider);
  return repository.getAllIngredients();
});
