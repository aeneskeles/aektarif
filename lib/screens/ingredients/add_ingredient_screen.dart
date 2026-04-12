import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ingredient.dart';
import '../../theme/app_theme.dart';
import '../../data/ingredients_repository.dart';

class AddIngredientScreen extends ConsumerStatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  ConsumerState<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends ConsumerState<AddIngredientScreen> {
  final _searchController = TextEditingController();
  final _customIngredientController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    _customIngredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(allIngredientsProvider);
    final inventoryKeys = ref.watch(inventoryKeysProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Malzeme Ekle'),
        actions: [
          if (_selectedNames.isNotEmpty)
            TextButton.icon(
              onPressed: _addSelectedIngredients,
              icon: const Icon(Icons.check),
              label: Text('Ekle (${_selectedNames.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Malzeme ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Custom ingredient input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customIngredientController,
                    decoration: InputDecoration(
                      hintText: 'Özel malzeme ekle...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomIngredient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Selected count
          if (_selectedNames.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedNames.length} malzeme seçildi',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedNames.clear());
                    },
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Ingredients List
          Expanded(
            child: ingredientsAsync.when(
              data: (allIngredients) {
                final filteredIngredients = _searchQuery.isEmpty
                    ? allIngredients
                    : allIngredients.where((i) => 
                        i.nameTr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        i.nameEn.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();

                // Group by category (simplified for Firebase data)
                final groupedIngredients = <String, List<Ingredient>>{};
                for (final ing in filteredIngredients) {
                  final category = _getCategoryFromEnglishName(ing.nameEn);
                  groupedIngredients.putIfAbsent(category, () => []).add(ing);
                }

                final categories = groupedIngredients.keys.toList()..sort();

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'Malzeme bulunamadı',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yukarıdan özel malzeme ekleyebilirsiniz',
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final ingredients = groupedIngredients[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _getCategoryDisplayName(category),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),

                        // Ingredients Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ingredients.map((ing) {
                              final key = ing.nameTr.toLowerCase();
                              final isInInventory = inventoryKeys.contains(key);
                              final isSelected = _selectedNames.contains(key);

                              return _IngredientChip(
                                ingredient: ing,
                                isInInventory: isInInventory,
                                isSelected: isSelected,
                                onTap: isInInventory
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedNames.remove(key);
                                          } else {
                                            _selectedNames.add(key);
                                          }
                                        });
                                      },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (error, stack) => Center(
                child: Text('Hata: $error'),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _selectedNames.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _addSelectedIngredients,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      '${_selectedNames.length} Malzeme Ekle',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _getCategoryFromEnglishName(String englishName) {
    final name = englishName.toLowerCase();
    
    if (name.contains('chicken') || name.contains('beef') || name.contains('lamb') || 
        name.contains('meat') || name.contains('fish') || name.contains('egg')) {
      return 'proteins';
    }
    if (name.contains('milk') || name.contains('cheese') || name.contains('yogurt') || 
        name.contains('butter') || name.contains('cream')) {
      return 'dairy';
    }
    if (name.contains('oil') || name.contains('sauce') || name.contains('paste') ||
        name.contains('vinegar')) {
      return 'oils';
    }
    if (name.contains('pepper') || name.contains('salt') || name.contains('spice') ||
        name.contains('cumin') || name.contains('oregano') || name.contains('mint') ||
        name.contains('parsley') || name.contains('basil') || name.contains('thyme') ||
        name.contains('cinnamon') || name.contains('garlic powder')) {
      return 'spices';
    }
    if (name.contains('rice') || name.contains('pasta') || name.contains('flour') ||
        name.contains('bread') || name.contains('noodle') || name.contains('bulgur') ||
        name.contains('lentil') || name.contains('bean') || name.contains('chickpea')) {
      return 'grains';
    }
    if (name.contains('apple') || name.contains('banana') || name.contains('orange') ||
        name.contains('lemon') || name.contains('strawberry') || name.contains('grape')) {
      return 'fruits';
    }
    
    return 'vegetables';
  }

  String _getCategoryDisplayName(String category) {
    const categoryNames = {
      'vegetables': '🥬 Sebzeler',
      'fruits': '🍎 Meyveler',
      'proteins': '🥩 Proteinler',
      'dairy': '🥛 Süt Ürünleri',
      'grains': '🌾 Tahıllar & Baklagiller',
      'spices': '🌿 Baharatlar',
      'oils': '🫒 Yağlar & Soslar',
      'other': '📦 Diğer',
    };
    return categoryNames[category] ?? '📦 Diğer';
  }

  void _addCustomIngredient() {
    final text = _customIngredientController.text.trim();
    if (text.isEmpty) return;

    ref.read(inventoryProvider.notifier).addItem(ingredientName: text.toLowerCase());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text eklendi'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    _customIngredientController.clear();
  }

  void _addSelectedIngredients() {
    if (_selectedNames.isEmpty) return;

    ref.read(inventoryProvider.notifier).addMultiple(_selectedNames.toList());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedNames.length} malzeme eklendi'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    Navigator.of(context).pop();
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    required this.ingredient,
    required this.isInInventory,
    required this.isSelected,
    this.onTap,
  });

  final Ingredient ingredient;
  final bool isInInventory;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (isInInventory) {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade500;
      borderColor = Colors.grey.shade300;
    } else if (isSelected) {
      bgColor = AppTheme.primaryColor;
      textColor = Colors.white;
      borderColor = AppTheme.primaryColor;
    } else {
      bgColor = Colors.white;
      textColor = AppTheme.textPrimary;
      borderColor = Colors.grey.shade300;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInInventory)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 16, color: Colors.grey),
                )
              else if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              Text(
                ingredient.nameTr,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
