import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../models/recipe.dart';
import '../../data/recipes_repository.dart';

class RecipeMenu {
  final String id;
  final String name;
  final String icon;
  final List<String> recipeIds;
  final String? creatorName;
  final bool isOwn;

  RecipeMenu({
    required this.id,
    required this.name,
    required this.icon,
    required this.recipeIds,
    this.creatorName,
    this.isOwn = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'recipeIds': recipeIds,
    'creatorName': creatorName,
    'isOwn': isOwn,
  };

  factory RecipeMenu.fromJson(Map<String, dynamic> json) => RecipeMenu(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
    recipeIds: List<String>.from(json['recipeIds']),
    creatorName: json['creatorName'],
    isOwn: json['isOwn'] ?? true,
  );
}

final recipeMenusProvider = StateNotifierProvider<RecipeMenusNotifier, List<RecipeMenu>>((ref) {
  return RecipeMenusNotifier();
});

class RecipeMenusNotifier extends StateNotifier<List<RecipeMenu>> {
  RecipeMenusNotifier() : super([]) {
    _loadMenus();
  }

  static const _boxName = 'settings';
  static const _menusKey = 'recipe_menus';

  Box get _box => Hive.box(_boxName);

  Future<void> _loadMenus() async {
    final data = _box.get(_menusKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data as String);
      state = jsonList.map((e) => RecipeMenu.fromJson(e)).toList();
    }
    
    // Başlangıçta boş — kullanıcı kendi tariflerini ekler
  }

  Future<void> _saveMenus() async {
    final jsonList = state.map((e) => e.toJson()).toList();
    await _box.put(_menusKey, jsonEncode(jsonList));
  }

  Future<void> addMenu(RecipeMenu menu) async {
    state = [...state, menu];
    await _saveMenus();
  }

  Future<void> removeMenu(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _saveMenus();
  }

  Future<void> updateMenu(RecipeMenu menu) async {
    state = state.map((m) => m.id == menu.id ? menu : m).toList();
    await _saveMenus();
  }

  List<RecipeMenu> get ownMenus => state.where((m) => m.isOwn).toList();
  List<RecipeMenu> get savedMenus => state.where((m) => !m.isOwn).toList();
}

class RecipeBookScreen extends ConsumerStatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  ConsumerState<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends ConsumerState<RecipeBookScreen> {
  bool _showOwnMenus = true;

  @override
  Widget build(BuildContext context) {
    ref.watch(recipeMenusProvider);
    final notifier = ref.read(recipeMenusProvider.notifier);
    final displayMenus = _showOwnMenus ? notifier.ownMenus : notifier.savedMenus;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.recipeBook,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.recipeBookSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.appTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.appCardFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showOwnMenus = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _showOwnMenus
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${strings.myRecipes} (${notifier.ownMenus.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showOwnMenus
                                    ? Colors.white
                                    : context.appTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showOwnMenus = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !_showOwnMenus
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${strings.savedMenus} (${notifier.savedMenus.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_showOwnMenus
                                    ? Colors.white
                                    : context.appTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu Cards
            if (displayMenus.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 64,
                        color: AppTheme.textTertiary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showOwnMenus
                            ? strings.noMenusYet
                            : strings.noSavedMenus,
                        style: TextStyle(
                          color: context.appTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final menu = displayMenus[index];
                      return _MenuCard(
                        menu: menu,
                        onTap: () => _showMenuDetail(context, menu),
                      );
                    },
                    childCount: displayMenus.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _showOwnMenus
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateMenuDialog(context),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                strings.createNew,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  void _showMenuDetail(BuildContext context, RecipeMenu menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuDetailSheet(menu: menu),
    );
  }

  void _showCreateMenuDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateMenuSheet(),
    );
  }
}

class _CreateMenuSheet extends ConsumerStatefulWidget {
  const _CreateMenuSheet();

  @override
  ConsumerState<_CreateMenuSheet> createState() => _CreateMenuSheetState();
}

class _CreateMenuSheetState extends ConsumerState<_CreateMenuSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedIcon = '🍽️';
  String _searchQuery = '';
  final Set<String> _selectedRecipeIds = {};

  static const _icons = [
    '🍽️', '🥗', '🥚', '🌙', '🎉', '🍝', '🍜', '🥘', '🍲', '🥧',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _searchResults(List<Recipe> recipes) {
    if (_searchQuery.trim().isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return recipes.where((recipe) {
      if (_selectedRecipeIds.contains(recipe.id)) return false;
      return recipe.name.toLowerCase().contains(query) ||
          recipe.shortDescription.toLowerCase().contains(query) ||
          recipe.ingredientNames.any((i) => i.toLowerCase().contains(query));
    }).take(8).toList();
  }

  List<Recipe> _selectedRecipes(List<Recipe> recipes) {
    return recipes
        .where((recipe) => _selectedRecipeIds.contains(recipe.id))
        .toList();
  }

  void _addRecipe(String recipeId) {
    setState(() {
      _selectedRecipeIds.add(recipeId);
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _removeRecipe(String recipeId) {
    setState(() {
      _selectedRecipeIds.remove(recipeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final recipesAsync = ref.watch(allRecipesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: sheetHeight,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.createMenu,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: context.appTextPrimary),
                    decoration: InputDecoration(
                      hintText: strings.menuName,
                      hintStyle: TextStyle(color: context.appTextMuted),
                      filled: true,
                      fillColor: context.appCardFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.appBorderSubtle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.selectIcon,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : context.appCardFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : context.appBorderSubtle,
                            ),
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: context.appTextPrimary),
                    decoration: InputDecoration(
                      hintText: strings.searchRecipes,
                      hintStyle: TextStyle(color: context.appTextMuted),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.appIconColor,
                      ),
                      filled: true,
                      fillColor: context.appCardFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.appBorderSubtle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  recipesAsync.when(
                    data: (recipes) {
                      final searchResults = _searchResults(recipes);
                      final selectedRecipes = _selectedRecipes(recipes);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_searchQuery.trim().isNotEmpty) ...[
                            if (searchResults.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Sonuç bulunamadı',
                                  style: TextStyle(
                                    color: context.appTextMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...searchResults.map(
                                (recipe) => _MenuRecipeSearchTile(
                                  recipe: recipe,
                                  onTap: () => _addRecipe(recipe.id),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                          if (selectedRecipes.isNotEmpty) ...[
                            Text(
                              strings.recipes,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...selectedRecipes.map(
                              (recipe) => _MenuSelectedRecipeRow(
                                recipe: recipe,
                                onRemove: () => _removeRecipe(recipe.id),
                              ),
                            ),
                          ] else if (_searchQuery.trim().isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Tarif arayarak menüye ekleyin',
                                style: TextStyle(
                                  color: context.appTextMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          strings.recipesLoadError,
                          style: TextStyle(color: context.appTextMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) return;
                  final menu = RecipeMenu(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    icon: _selectedIcon,
                    recipeIds: _selectedRecipeIds.toList(),
                    isOwn: true,
                  );
                  ref.read(recipeMenusProvider.notifier).addMenu(menu);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.create,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRecipeSearchTile extends StatelessWidget {
  const _MenuRecipeSearchTile({
    required this.recipe,
    required this.onTap,
  });

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                color: context.appInput,
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.restaurant,
                          color: context.appIconColor.withValues(alpha: 0.5),
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        color: context.appIconColor.withValues(alpha: 0.5),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recipe.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: context.appIconColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSelectedRecipeRow extends StatelessWidget {
  const _MenuSelectedRecipeRow({
    required this.recipe,
    required this.onRemove,
  });

  final Recipe recipe;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.restaurant_rounded,
              size: 14,
              color: context.appIconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recipe.name,
              style: TextStyle(
                fontSize: 14,
                color: context.appTextPrimary,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: context.appIconColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends ConsumerWidget {
  const _MenuCard({required this.menu, required this.onTap});

  final RecipeMenu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Text(menu.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      if (menu.creatorName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Kaydeden: ${menu.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recipesAsync.when(
              data: (allRecipes) {
                final menuRecipes = menu.recipeIds
                    .map((id) => allRecipes.where((r) => 
                        r.id == id || 
                        r.name.toLowerCase().contains(id.replaceAll('_', ' '))
                    ).firstOrNull)
                    .where((r) => r != null)
                    .cast<Recipe>()
                    .toList();
                
                if (menuRecipes.isEmpty && menu.recipeIds.isNotEmpty) {
                  final sampleRecipes = allRecipes.take(menu.recipeIds.length).toList();
                  return _buildRecipeThumbnails(sampleRecipes);
                }
                
                return _buildRecipeThumbnails(menuRecipes.isEmpty ? allRecipes.take(3).toList() : menuRecipes);
              },
              loading: () => const SizedBox(height: 56),
              error: (_, __) => const SizedBox(height: 56),
            ),
            const SizedBox(height: 12),
            recipesAsync.when(
              data: (allRecipes) {
                final count = menu.recipeIds.length;
                int totalTime = 0;
                for (final id in menu.recipeIds) {
                  final recipe = allRecipes.where((r) => 
                      r.id == id || 
                      r.name.toLowerCase().contains(id.replaceAll('_', ' '))
                  ).firstOrNull;
                  if (recipe != null) {
                    totalTime += recipe.totalTime;
                  }
                }
                if (totalTime == 0) totalTime = count * 35;
                
                return Text(
                  '$count yemek  •  $totalTime dakika',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeThumbnails(List<Recipe> recipes) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            width: 56,
            height: 56,
            margin: EdgeInsets.only(right: index < recipes.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.inputColor,
              image: recipe.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(recipe.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: recipe.imageUrl == null
                ? Center(
                    child: Icon(
                      Icons.restaurant,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _MenuDetailSheet extends ConsumerWidget {
  const _MenuDetailSheet({required this.menu});

  final RecipeMenu menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              child: Row(
                children: [
                  Text(menu.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      menu.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.appTextSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: recipesAsync.when(
                data: (allRecipes) {
                  List<Recipe> menuRecipes = [];
                  for (final id in menu.recipeIds) {
                    final recipe = allRecipes.where((r) => 
                        r.id == id || 
                        r.name.toLowerCase().contains(id.replaceAll('_', ' '))
                    ).firstOrNull;
                    if (recipe != null) {
                      menuRecipes.add(recipe);
                    }
                  }
                  
                  if (menuRecipes.isEmpty) {
                    menuRecipes = allRecipes.take(menu.recipeIds.length.clamp(2, 4)).toList();
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: menuRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = menuRecipes[index];
                      return _RecipeListTile(
                        recipe: recipe,
                        index: index + 1,
                        onTap: () => _showRecipeDetail(context, recipe),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (_, __) => const Center(
                  child: Text('Tarifler yüklenemedi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipeDetailModal(recipe: recipe),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({
    required this.recipe,
    required this.index,
    required this.onTap,
  });

  final Recipe recipe;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.inputColor,
                image: recipe.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(recipe.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: recipe.imageUrl == null
                  ? Icon(
                      Icons.restaurant,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yemek $index',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.shortDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appSectionLabel,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: context.appSectionLabel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTime}dk',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appSectionLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: context.appSectionLabel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings ?? 4} kişi',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appSectionLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeDetailModal extends StatefulWidget {
  const _RecipeDetailModal({required this.recipe});

  final Recipe recipe;

  @override
  State<_RecipeDetailModal> createState() => _RecipeDetailModalState();
}

class _RecipeDetailModalState extends State<_RecipeDetailModal> {
  bool _showIngredients = true;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      color: AppTheme.inputColor,
                      image: recipe.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(recipe.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: recipe.imageUrl == null
                        ? Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.shortDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.schedule,
                          value: '${recipe.totalTime} dk',
                          label: 'Süre',
                        ),
                        _StatItem(
                          icon: Icons.people_outline,
                          value: '${recipe.servings ?? 4}',
                          label: 'Kişi',
                        ),
                        _StatItem(
                          icon: Icons.local_fire_department_outlined,
                          value: '${(recipe.servings ?? 4) * 80}',
                          label: 'Kalori',
                        ),
                        _StatItem(
                          icon: Icons.star_outline,
                          value: '4.6',
                          label: 'Puan',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tags
                    Row(
                      children: [
                        if (recipe.category != null)
                          _TagChip(label: recipe.category!),
                        if (recipe.difficulty != null)
                          _TagChip(label: recipe.difficulty!),
                        const Spacer(),
                        Text(
                          '218 değerlendirme',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appSectionLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.appCardFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showIngredients = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _showIngredients
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Malzemeler',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _showIngredients
                                        ? Colors.white
                                        : context.appSectionLabel,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showIngredients = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_showIngredients
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Yapılış',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !_showIngredients
                                        ? Colors.white
                                        : context.appSectionLabel,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content based on tab
                    if (_showIngredients)
                      _buildIngredientsList(recipe)
                    else
                      _buildStepsList(recipe),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsList(Recipe recipe) {
    return Column(
      children: recipe.ingredientsRaw.map((ingredient) {
        final parts = ingredient.split(' ');
        String quantity = '';
        String name = ingredient;
        
        if (parts.length >= 2) {
          final firstPart = parts[0];
          if (RegExp(r'^\d').hasMatch(firstPart)) {
            quantity = parts.take(2).join(' ');
            name = parts.skip(2).join(' ');
            if (name.isEmpty) {
              name = parts.last;
              quantity = parts.take(parts.length - 1).join(' ');
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.appCardFill,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.isEmpty ? ingredient : name,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              if (quantity.isNotEmpty)
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepsList(Recipe recipe) {
    return Column(
      children: recipe.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appCardFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  step.instructionTr,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appTextPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: context.appSectionLabel,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.appCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorderSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: context.appTextPrimary,
        ),
      ),
    );
  }
}
