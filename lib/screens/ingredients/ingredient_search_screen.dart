import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/recipes_repository.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../recipes/recipe_detail_screen.dart';

const _commonIngredients = [
  'Yumurta',
  'Domates',
  'Soğan',
  'Sarımsak',
  'Zeytinyağı',
  'Un',
  'Tereyağı',
  'Maydanoz',
  'Biber',
  'Limon',
  'Pirinç',
  'Kıyma',
  'Yoğurt',
  'Salatalık',
  'Nane',
];

class IngredientSearchScreen extends ConsumerStatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  ConsumerState<IngredientSearchScreen> createState() =>
      _IngredientSearchScreenState();
}

class _IngredientSearchScreenState
    extends ConsumerState<IngredientSearchScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Set<String> _selectedIngredients = {};

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _selectedIngredients.add(trimmed);
      _inputController.clear();
    });
  }

  void _removeIngredient(String name) {
    setState(() => _selectedIngredients.remove(name));
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = _selectedIngredients.isEmpty
        ? null
        : ref.watch(_ingredientSearchProvider(_selectedIngredients));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with back button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Malzeme ile Ara',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Malzeme seç veya yaz, tarif bul',
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
            ),

            // Input row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.appCardFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.appBorderSubtle),
                        ),
                        child: TextField(
                          controller: _inputController,
                          style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Malzeme yaz...',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.35),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: _addIngredient,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _addIngredient(_inputController.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selected ingredients
            if (_selectedIngredients.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedIngredients.map((ingredient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ingredient,
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeIngredient(ingredient),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Common ingredients
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'YAYGIN MALZEMELER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonIngredients.map((ingredient) {
                    final isSelected = _selectedIngredients.contains(ingredient);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          _removeIngredient(ingredient);
                        } else {
                          _addIngredient(ingredient);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.25)
                              : context.appOverlay,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                : context.appOverlayStrong,
                          ),
                        ),
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Results or empty state
            if (_selectedIngredients.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 40,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Malzeme seçerek tarif bulmaya başla',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appSectionLabel,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              recommendationsAsync!.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Bu malzemelerle uygun tarif bulunamadı',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appSectionLabel,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final rec = recommendations[index];
                          return _RecipeResultTile(
                            recipe: rec.recipe,
                            matchScore: rec.matchScore,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipeId: rec.recipe.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: recommendations.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
          ],
        ),
      ),
    );
  }
}

final _ingredientSearchProvider =
    FutureProvider.family<List<RecipeRecommendation>, Set<String>>(
  (ref, ingredients) async {
    final repository = ref.watch(recipesRepositoryProvider);
    final normalized = ingredients
        .map((e) => e.toLowerCase().trim())
        .toSet();
    return repository.getRecommendations(normalized);
  },
);

class _RecipeResultTile extends StatelessWidget {
  const _RecipeResultTile({
    required this.recipe,
    required this.matchScore,
    required this.onTap,
  });

  final Recipe recipe;
  final double matchScore;
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
          border: Border.all(color: context.appBorderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
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
                    '${recipe.totalTime} dk · %${(matchScore * 100).round()} uyum',
                    style: TextStyle(
                      color: context.appSectionLabel,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
