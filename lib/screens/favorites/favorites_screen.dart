import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../data/favorites_repository.dart';
import '../../models/recipe.dart';
import '../recipes/recipe_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
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
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.appIconColor,
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
                          'Favorilerim',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Beğendiğin tarifler',
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
            ),
            // Content
            Expanded(
              child: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return _FavoriteTile(
                recipe: recipe,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                    ),
                  );
                },
                onRemove: () {
                  ref.read(favoritesProvider.notifier).remove(recipe.id);
                },
              );
            },
          );
        },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (_, __) => _buildEmptyState(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz favori tarifin yok',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarifleri keşfet ve beğendiklerini ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appSectionLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.recipe,
    required this.onTap,
    required this.onRemove,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
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
                    recipe.name,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.totalTime} dk',
                    style: TextStyle(
                      color: context.appSectionLabel,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
