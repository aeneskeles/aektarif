import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../models/recipe.dart';
import '../../data/recipes_repository.dart';
import '../../data/favorites_repository.dart';
import '../../data/auth_repository.dart';
import '../recipes/recipe_detail_screen.dart';
import '../favorites/favorites_screen.dart';
import '../ingredients/ingredient_search_screen.dart';
import '../chef/chef_assistant_screen.dart';
import '../recipe_book/recipe_book_screen.dart';

import '../recipes/recommendations_screen.dart';

final featuredRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final allRecipes = await ref.watch(allRecipesProvider.future);
  return allRecipes.take(6).toList();
});

final userMenuRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final menus = ref.watch(recipeMenusProvider);
  final recipeIds = menus
      .where((m) => m.isOwn)
      .expand((m) => m.recipeIds)
      .toSet()
      .toList();
  if (recipeIds.isEmpty) return [];

  final allRecipes = await ref.watch(allRecipesProvider.future);
  final recipes = <Recipe>[];
  for (final id in recipeIds) {
    for (final recipe in allRecipes) {
      if (recipe.id == id) {
        recipes.add(recipe);
        break;
      }
    }
  }
  return recipes;
});

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedDayOffset = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final userName = profile?.displayName ?? profile?.username ?? 'Şef';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş geldin 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$firstName!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tarif ara...',
                    hintStyle: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.appIconColor,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: context.appIconColor,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),

          // Daily Recipe Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Günün Önerisi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ),

          // Day Selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final offset = index - 3;
                  final isSelected = offset == _selectedDayOffset;
                  final date = DateTime.now().add(Duration(days: offset));
                  final dayNames = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDayOffset = offset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : context.appOverlay,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNames[date.weekday % 7],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : context.appTextMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : context.appTextMuted,
                              ),
                            ),
                            if (offset == 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected 
                                      ? Colors.white 
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Daily Recipe Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _DailyRecipeCard(dayOffset: _selectedDayOffset),
            ),
          ),

          // AI'a Sor Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _AiSorCard(),
            ),
          ),

          // Favorites Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorilerim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tümünü Gör',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _FavoritesHorizontalList()),

          // User Recipes Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tarifler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecommendationsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tümünü Gör',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const _FeaturedRecipesList(),

          // Ingredient Search Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _IngredientSearchCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _AiSorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChefAssistantScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appOverlayStrong,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.appIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI'a Sor",
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tarif önerisi al, sorularını sor',
                      style: TextStyle(
                        color: context.appTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appTextMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientSearchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const IngredientSearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: AppTheme.successColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Malzeme ile Ara',
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Elindeki malzemelere göre tarif bul',
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appTextMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHorizontalList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);

    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return _buildEmptyState(context);
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < favorites.length - 1 ? 12 : 0,
                ),
                child: _FavoriteRecipeCard(
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
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      error: (error, stackTrace) => _buildEmptyState(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 28,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz favori tarifin yok',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tarifleri keşfet ve beğendiklerini ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
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
        width: 160,
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
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      color: context.appInput,
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
                              size: 32,
                              color: context.appIconColor.withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.lightSurface.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.appTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: context.appIconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTime} dk',
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

class _DailyRecipeCard extends ConsumerWidget {
  const _DailyRecipeCard({required this.dayOffset});

  final int dayOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeOfTheDayAsync = ref.watch(recipeOfTheDayProvider(dayOffset));

    return recipeOfTheDayAsync.when(
      data: (recipe) {
        if (recipe == null) {
          return _buildDefaultCard(context);
        }
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                  recipeId: recipe.id,
                  hideBottomBar: true,
                ),
              ),
            );
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: recipe.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(recipe.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: recipe.imageUrl == null ? AppTheme.cardGradient : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.deepNavy.withValues(alpha: 0.95),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.category ?? 'Ana Yemek',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.amberStar.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dayOffset == 0 ? 'Bugün' : 'Öneri',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTime} dk',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.star,
                        size: 13,
                        color: AppTheme.amberStar,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tarifi Gör →',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => _buildDefaultCard(context),
      error: (error, stackTrace) => _buildDefaultCard(context),
    );
  }

  Widget _buildDefaultCard(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.cardGradient,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Hızlı seçim',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lezzetli Tarifler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hızlı, Sağlıklı & Pratik',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRecipesList extends ConsumerWidget {
  const _FeaturedRecipesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(featuredRecipesProvider);

    return recipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.appCardFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 40,
                      color: context.appIconColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tarif bulunamadı',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return _RecipeGridCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeDetailScreen(recipeId: recipe.id),
                      ),
                    );
                  },
                );
              },
              childCount: recipes.length,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.appCardFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'Tarifler yüklenemedi',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeGridCard extends StatelessWidget {
  const _RecipeGridCard({
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      color: context.appInput,
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
                              size: 32,
                              color: context.appIconColor.withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.appBackground.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.appTextPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 11,
                        color: context.appIconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTime}dk',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appTextMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 11,
                        color: AppTheme.amberStar,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.amberStar,
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
