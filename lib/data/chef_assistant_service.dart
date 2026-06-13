import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import 'recipes_repository.dart';
import 'recommendation_engine.dart';

final chefAssistantProvider = Provider<ChefAssistantService>((ref) {
  final recipesRepository = ref.watch(recipesRepositoryProvider);
  final recommendationEngine = ref.watch(recommendationEngineProvider);
  return ChefAssistantService(recipesRepository, recommendationEngine);
});

class ChefAssistantService {
  ChefAssistantService(this._recipesRepository, this._recommendationEngine);

  final RecipesRepository _recipesRepository;
  final RecommendationEngine _recommendationEngine;

  Future<ChefResponse> getRecipeFromIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) {
      return ChefResponse(
        success: false,
        message: 'Lütfen en az bir malzeme belirtin.',
      );
    }

    final normalizedIngredients = ingredients
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final recipes = await _recipesRepository.loadRecipes();
    final recommendations = _recommendationEngine.getRecommendations(
      recipes: recipes,
      userIngredients: normalizedIngredients,
      limit: 5,
      minMatchScore: 0.3,
    );

    if (recommendations.isEmpty) {
      return ChefResponse(
        success: false,
        message: 'Belirtilen malzemelerle uyumlu tarif bulunamadı. '
            'Farklı malzemeler deneyebilir veya malzeme sayısını artırabilirsiniz.',
      );
    }

    final bestMatch = recommendations.first;
    return ChefResponse(
      success: true,
      recipe: bestMatch.recipe,
      formattedRecipe: formatRecipe(
        bestMatch.recipe,
        matchedIngredients: bestMatch.matchedIngredients,
        missingIngredients: bestMatch.missingIngredients,
      ),
      matchScore: bestMatch.matchScore,
      alternatives: recommendations.skip(1).take(3).map((r) => r.recipe).toList(),
    );
  }

  Future<ChefResponse> searchRecipeByName(String query) async {
    if (query.trim().isEmpty) {
      return ChefResponse(
        success: false,
        message: 'Lütfen bir tarif adı veya anahtar kelime girin.',
      );
    }

    final recipes = await _recipesRepository.searchRecipes(query);
    
    if (recipes.isEmpty) {
      return ChefResponse(
        success: false,
        message: '"$query" ile ilgili tarif bulunamadı.',
      );
    }

    final recipe = recipes.first;
    return ChefResponse(
      success: true,
      recipe: recipe,
      formattedRecipe: formatRecipe(recipe),
      alternatives: recipes.skip(1).take(3).toList(),
    );
  }

  Future<List<Recipe>> getRandomSuggestions({int count = 5}) async {
    return _recipesRepository.getRandomRecipes(count: count);
  }

  Future<Recipe?> getRecipeOfTheDay() async {
    return _recipesRepository.getRecipeOfTheDay();
  }

  String formatRecipe(
    Recipe recipe, {
    List<String>? matchedIngredients,
    List<String>? missingIngredients,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🍳 ${recipe.name}');
    buffer.writeln();

    final prepTime = recipe.prepTime ?? 0;
    final cookTime = recipe.cookTime ?? 0;
    buffer.writeln('⏱️ Hazırlama Süresi: $prepTime dk | 🍲 Pişirme Süresi: $cookTime dk');
    
    if (recipe.servings != null) {
      buffer.writeln('👥 Porsiyon: ${recipe.servings} kişilik');
    }
    if (recipe.difficulty != null) {
      buffer.writeln('📊 Zorluk: ${recipe.difficulty}');
    }
    buffer.writeln();

    buffer.writeln('🛒 Malzemeler:');
    for (final ingredient in recipe.ingredientsRaw) {
      final isMatched = matchedIngredients?.any(
        (m) => ingredient.toLowerCase().contains(m.toLowerCase()),
      ) ?? false;
      
      if (isMatched) {
        buffer.writeln('✅ $ingredient');
      } else {
        buffer.writeln('• $ingredient');
      }
    }
    
    if (missingIngredients != null && missingIngredients.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ Eksik Malzemeler:');
      for (final missing in missingIngredients) {
        buffer.writeln('• $missing');
      }
    }
    buffer.writeln();

    buffer.writeln('📝 Adım Adım Yapılışı:');
    for (final step in recipe.steps) {
      buffer.writeln('${step.order}. ${step.instructionTr}');
      if (step.tip != null) {
        buffer.writeln('   💡 İpucu: ${step.tip}');
      }
      buffer.writeln();
    }

    final tip = _getChefTip(recipe);
    if (tip != null) {
      buffer.writeln('💡 Şefin Dokunuşu: $tip');
    }

    return buffer.toString();
  }

  String? _getChefTip(Recipe recipe) {
    final tips = <String>[];

    final name = recipe.name.toLowerCase();
    final ingredients = recipe.ingredientNames.join(' ').toLowerCase();
    final category = recipe.category?.toLowerCase() ?? '';

    if (name.contains('çorba') || category.contains('çorba')) {
      tips.addAll([
        'Çorbayı servis etmeden önce üzerine taze kekik veya maydanoz ekleyin.',
        'Kremsi bir doku için çorbayı blenderdan geçirebilirsiniz.',
        'Yanında çıtır ekmek dilimleri ile servis edin.',
      ]);
    }

    if (name.contains('köfte') || ingredients.contains('kıyma')) {
      tips.addAll([
        'Köfteleri şekillendirmeden önce karışımı 30 dakika buzdolabında dinlendirin.',
        'Elinizi ıslatarak şekillendirirseniz köfteler yapışmaz.',
        'Piştikten sonra 5 dakika dinlendirin, böylece suyunu içinde tutar.',
      ]);
    }

    if (name.contains('pilav') || ingredients.contains('pirinç')) {
      tips.addAll([
        'Pirinci en az 30 dakika suda bekletin.',
        'Pilavı pişirdikten sonra 10 dakika dinlendirin, taneler daha güzel açılır.',
        'Üzerine tereyağı ile kavrulmuş şehriye ekleyebilirsiniz.',
      ]);
    }

    if (name.contains('salata') || category.contains('salata')) {
      tips.addAll([
        'Malzemeleri son anda karıştırın, daha taze kalır.',
        'Limon suyu yerine nar ekşisi kullanmayı deneyin.',
        'Üzerine kavrulmuş ceviz veya badem serpin.',
      ]);
    }

    if (name.contains('tatlı') || category.contains('tatlı')) {
      tips.addAll([
        'Şerbeti soğuk, tatlıyı sıcak olarak buluşturun.',
        'Üzerine taze kaymak veya dondurma ile servis edin.',
        'Tatlının daha iyi şerbet çekmesi için bekletin.',
      ]);
    }

    if (ingredients.contains('tavuk')) {
      tips.addAll([
        'Tavuğu pişirmeden önce oda sıcaklığına gelmesini bekleyin.',
        'Marine etmek için yoğurt kullanın, eti yumuşatır.',
        'Tavuk suyu ile pişirirseniz daha lezzetli olur.',
      ]);
    }

    if (ingredients.contains('balık') || category.contains('balık')) {
      tips.addAll([
        'Balığı pişirmeden önce limonlu suyla yıkayın.',
        'Çok karıştırmayın, balık eti dağılabilir.',
        'Yanında roka salatası mükemmel uyum sağlar.',
      ]);
    }

    if (tips.isEmpty) {
      tips.addAll([
        'Malzemeleri önceden hazırlayın, pişirme süreci daha rahat olacaktır.',
        'Taze otlar kullanarak lezzeti artırabilirsiniz.',
        'Tuz miktarını kendi damak tadınıza göre ayarlayın.',
        'Yemeği servis etmeden önce birkaç dakika dinlendirin.',
      ]);
    }

    return tips[Random().nextInt(tips.length)];
  }

  List<String> parseIngredientsFromText(String text) {
    final ingredients = text
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length > 1)
        .toList();
    
    return ingredients;
  }

  String getWelcomeMessage() {
    final messages = [
      'Merhaba! Ben senin mutfak asistanınım. Elindeki malzemeleri söyle, sana en uygun tarifi önereyim! 🍳',
      'Hoş geldin! Bugün ne pişirmek istersin? Malzemelerini paylaş, birlikte harika tarifler keşfedelim! 👨‍🍳',
      'Mutfağa hoş geldin! Malzemelerini yazarak veya fotoğraf çekerek başlayabilirsin. 📸',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  String getNoFoodDetectedMessage() {
    return 'Görselde herhangi bir yiyecek malzemesi algılayamadım. '
        'Lütfen malzemelerinizin net bir fotoğrafını yükleyin veya yazarak belirtin.';
  }

  String getOutOfScopeMessage() {
    return 'Ben sadece yemek tarifleri ve mutfak ipuçları konusunda yardımcı olabilirim. 🍽️\n'
        'Malzemelerinizi yazarak veya fotoğraf çekerek tarif önerisi alabilirsiniz.';
  }
}

class ChefResponse {
  ChefResponse({
    required this.success,
    this.message,
    this.recipe,
    this.formattedRecipe,
    this.matchScore,
    this.alternatives,
  });

  final bool success;
  final String? message;
  final Recipe? recipe;
  final String? formattedRecipe;
  final double? matchScore;
  final List<Recipe>? alternatives;
}

final chefMessagesProvider = StateNotifierProvider<ChefMessagesNotifier, List<ChefMessage>>((ref) {
  return ChefMessagesNotifier();
});

class ChefMessagesNotifier extends StateNotifier<List<ChefMessage>> {
  ChefMessagesNotifier() : super([]);

  void addMessage(ChefMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = [];
  }
}

class ChefMessage {
  ChefMessage({
    required this.content,
    required this.isUser,
    this.recipe,
    this.alternatives,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String content;
  final bool isUser;
  final Recipe? recipe;
  final List<Recipe>? alternatives;
  final DateTime timestamp;
}
