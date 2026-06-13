import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../data/recipes_repository.dart';
import 'recipe_detail_screen.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allRecipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Back Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.appCardFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tüm Tarifler',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lezzetli tarifleri keşfet',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.appSectionLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appCardFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Yemek adı ara...',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.35),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.textTertiary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Recipes Grid
            allRecipesAsync.when(
              data: (recipes) {
                final filtered = _filterRecipes(recipes);

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Arama sonucu bulunamadı',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'Arama Sonuçları' 
                                  : 'Tüm Tarifler',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '${filtered.length} tarif',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _SimpleRecipeCard(
                            recipe: filtered[index],
                            onTap: () => _openRecipeDetail(filtered[index]),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tarifler yüklenirken hata oluştu',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(allRecipesProvider),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    if (_searchQuery.isEmpty) return recipes;

    final query = _searchQuery.toLowerCase();
    return recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(query) ||
          recipe.shortDescription.toLowerCase().contains(query) ||
          (recipe.keywords?.any((k) => k.toLowerCase().contains(query)) ?? false) ||
          recipe.ingredientNames.any((ing) => ing.toLowerCase().contains(query));
    }).toList();
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }
}

class _SimpleRecipeCard extends StatelessWidget {
  const _SimpleRecipeCard({
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
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: AppTheme.chipColor,
                ),
                child: recipe.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.totalTime > 0 ? '${recipe.totalTime} dk' : '-',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        if (recipe.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 10,
                            color: AppTheme.dividerColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recipe.category!,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
