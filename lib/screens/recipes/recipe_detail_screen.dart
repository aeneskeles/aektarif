import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../data/ingredients_repository.dart';
import '../../data/recipes_repository.dart';
import '../../data/favorites_repository.dart';
import '../../data/zero_waste_service.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.hideBottomBar = false,
  });

  final String recipeId;
  final bool hideBottomBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesRepo = ref.watch(recipesRepositoryProvider);
    final inventoryKeys = ref.watch(inventoryKeysProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteIds.contains(recipeId);

    return FutureBuilder<Recipe?>(
      future: recipesRepo.getRecipeById(recipeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.appBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final recipe = snapshot.data;
        if (recipe == null) {
          return Scaffold(
            backgroundColor: context.appBackground,
            appBar: AppBar(backgroundColor: context.appBackground),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  Text('Tarif bulunamadı', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: context.appBackground,
          body: CustomScrollView(
            slivers: [
              // Hero Image
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.chipColor,
                      ),
                      child: recipe.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 80,
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 80,
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                    ),
                    // Gradient Overlay
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    // Back Button & Actions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          _FavoriteButton(
                            isFavorite: isFavorite,
                            onTap: () {
                              ref.read(favoritesProvider.notifier).toggle(recipeId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite 
                                        ? 'Favorilerden çıkarıldı' 
                                        : 'Favorilere eklendi'
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Card
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge
                          if (recipe.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                recipe.category!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),

                          // Title
                          Text(
                            recipe.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.appTextPrimary,
                                ),
                          ),

                          const SizedBox(height: 12),

                          // Description
                          if (recipe.shortDescription.isNotEmpty)
                            Text(
                              recipe.shortDescription,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Info Chips Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (recipe.totalTime > 0)
                                  _InfoChip(
                                    icon: Icons.schedule,
                                    label: '${recipe.totalTime} dk',
                                  ),
                                if (recipe.servings != null)
                                  _InfoChip(
                                    icon: Icons.people_outline,
                                    label: '${recipe.servings} kişilik',
                                  ),
                                if (recipe.cuisine != null)
                                  _InfoChip(
                                    icon: Icons.public,
                                    label: recipe.cuisine!,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Malzemeler Section
                          _SectionTitle(
                            title: 'Malzemeler',
                            subtitle: '${recipe.ingredientsRaw.length} malzeme',
                          ),
                          const SizedBox(height: 16),

                          // Ingredients List
                          _IngredientsList(
                            ingredients: recipe.ingredientsRaw,
                            ingredientNames: recipe.ingredientNames,
                            inventoryKeys: inventoryKeys,
                          ),

                          const SizedBox(height: 28),

                          // Hazırlanışı Section
                          if (recipe.steps.isNotEmpty) ...[
                            _SectionTitle(
                              title: 'Hazırlanışı',
                              subtitle: '${recipe.steps.length} adım',
                            ),
                            const SizedBox(height: 16),

                            // Steps List
                            ...recipe.steps.asMap().entries.map((entry) {
                              final index = entry.key;
                              final step = entry.value;

                              return _StepItem(
                                stepNumber: index + 1,
                                instruction: step.instructionTr,
                                duration: step.durationMinutes,
                                isLast: index == recipe.steps.length - 1,
                              );
                            }),
                          ],

                          const SizedBox(height: 28),

                          // Zero Waste Section
                          _ZeroWasteCard(recipe: recipe),

                          SizedBox(height: hideBottomBar ? 40 : 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: hideBottomBar ? null : Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Chef Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.chipColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Start Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Afiyet olsun! 🍽️'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Tarifi Başlat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: context.appTextPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : context.appTextPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  const _IngredientsList({
    required this.ingredients,
    required this.ingredientNames,
    required this.inventoryKeys,
  });

  final List<String> ingredients;
  final List<String> ingredientNames;
  final Set<String> inventoryKeys;

  bool _hasIngredient(String ingredientName) {
    final normalized = ingredientName.toLowerCase().trim();
    for (final key in inventoryKeys) {
      if (normalized.contains(key) || key.contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          final ingredientName = index < ingredientNames.length 
              ? ingredientNames[index] 
              : ingredient;
          final hasIt = _hasIngredient(ingredientName);
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < ingredients.length - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hasIt 
                        ? AppTheme.successColor.withOpacity(0.1) 
                        : AppTheme.chipColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    hasIt ? Icons.check : Icons.circle_outlined,
                    size: 14,
                    color: hasIt ? AppTheme.successColor : AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasIt ? AppTheme.successColor : context.appTextPrimary,
                      fontWeight: hasIt ? FontWeight.w600 : FontWeight.w400,
                      height: 1.4,
                      decoration: hasIt ? TextDecoration.none : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.stepNumber,
    required this.instruction,
    this.duration,
    this.isLast = false,
  });

  final int stepNumber;
  final String instruction;
  final int? duration;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppTheme.dividerColor,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appTextPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$duration dk',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroWasteCard extends ConsumerStatefulWidget {
  const _ZeroWasteCard({required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_ZeroWasteCard> createState() => _ZeroWasteCardState();
}

class _ZeroWasteCardState extends ConsumerState<_ZeroWasteCard> {
  bool _isExpanded = false;
  ZeroWasteAnalysis? _analysis;

  // Modern blue color palette matching Figma design
  static const Color _primaryBlue = AppTheme.primaryColor;
  static const Color _darkBlue = Color(0xFF1E40AF);
  static const Color _textBlue = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    _analyzeRecipe();
  }

  void _analyzeRecipe() {
    final service = ref.read(zeroWasteServiceProvider);
    _analysis = service.analyzeRecipe(widget.recipe);
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    
    if (analysis == null || !analysis.isZeroWastePossible) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.eco_outlined,
                    color: context.appIconColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sıfır Atık Önerileri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${analysis.identifiedWaste.length} atık tespit edildi',
                          style: TextStyle(
                            fontSize: 13,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identified Waste Section
                      Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tespit Edilen Atıklar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Waste Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.identifiedWaste.map((waste) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              waste,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Suggestions
                      ...analysis.premiumSuggestions.asMap().entries.map((entry) {
                        final suggestion = entry.value;
                        final iconData = _getSuggestionIcon(entry.key);
                        final iconColor = _getSuggestionColor(entry.key);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      suggestion.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: context.appTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...suggestion.steps.asMap().entries.map((stepEntry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: _primaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${stepEntry.key + 1}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          stepEntry.value,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),

                      // Green Impact
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: context.appSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '🌍',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                analysis.greenImpact,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _darkBlue,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  IconData _getSuggestionIcon(int index) {
    final icons = [
      Icons.restaurant_outlined,
      Icons.local_florist_outlined,
      Icons.eco_outlined,
    ];
    return icons[index % icons.length];
  }

  Color _getSuggestionColor(int index) {
    final colors = [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
      AppTheme.primaryColor, // Blue
    ];
    return colors[index % colors.length];
  }
}
