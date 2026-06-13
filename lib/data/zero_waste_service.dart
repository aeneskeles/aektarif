import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';

final zeroWasteServiceProvider = Provider<ZeroWasteService>((ref) {
  return ZeroWasteService();
});

class ZeroWasteService {
  ZeroWasteService();

  /// Analyzes recipe ingredients and returns zero waste suggestions
  ZeroWasteAnalysis analyzeRecipe(Recipe recipe) {
    final ingredients = recipe.ingredientsRaw;
    final ingredientNames = recipe.ingredientNames;
    
    final identifiedWaste = <String>[];
    final suggestions = <ZeroWasteSuggestion>[];

    // Analyze each ingredient for potential waste
    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i].toLowerCase();
      final name = i < ingredientNames.length 
          ? ingredientNames[i].toLowerCase() 
          : ingredient;

      // Check for vegetables with peelable parts
      if (_containsAny(name, ['patates', 'havuç', 'salatalık', 'kabak', 'patlıcan', 'elma', 'armut'])) {
        if (!identifiedWaste.contains('Sebze/meyve kabukları')) {
          identifiedWaste.add('Sebze/meyve kabukları');
        }
      }

      // Check for vegetables with stems/leaves
      if (_containsAny(name, ['brokoli', 'karnabahar', 'kereviz', 'maydanoz', 'dereotu', 'nane', 'fesleğen', 'roka'])) {
        if (!identifiedWaste.contains('Yeşillik sapları')) {
          identifiedWaste.add('Yeşillik sapları');
        }
      }

      // Check for citrus
      if (_containsAny(name, ['limon', 'portakal', 'mandalina', 'greyfurt'])) {
        if (!identifiedWaste.contains('Narenciye kabukları')) {
          identifiedWaste.add('Narenciye kabukları');
        }
      }

      // Check for onion family
      if (_containsAny(name, ['soğan', 'sarımsak', 'pırasa'])) {
        if (!identifiedWaste.contains('Soğan/sarımsak kabukları')) {
          identifiedWaste.add('Soğan/sarımsak kabukları');
        }
      }

      // Check for bread
      if (_containsAny(name, ['ekmek', 'francala', 'baget', 'somun'])) {
        if (!identifiedWaste.contains('Bayat ekmek')) {
          identifiedWaste.add('Bayat ekmek');
        }
      }

      // Check for cheese/dairy
      if (_containsAny(name, ['peynir', 'lor', 'kaşar', 'beyaz peynir'])) {
        if (!identifiedWaste.contains('Peynir kabukları/kalıntıları')) {
          identifiedWaste.add('Peynir kabukları/kalıntıları');
        }
      }

      // Check for chicken/meat with bones
      if (_containsAny(name, ['tavuk', 'but', 'kanat', 'pirzola', 'kemikli'])) {
        if (!identifiedWaste.contains('Tavuk/et kemikleri')) {
          identifiedWaste.add('Tavuk/et kemikleri');
        }
      }

      // Check for eggs
      if (_containsAny(name, ['yumurta'])) {
        if (!identifiedWaste.contains('Yumurta kabukları')) {
          identifiedWaste.add('Yumurta kabukları');
        }
      }

      // Check for tomatoes
      if (_containsAny(name, ['domates'])) {
        if (!identifiedWaste.contains('Domates sapları ve kabukları')) {
          identifiedWaste.add('Domates sapları ve kabukları');
        }
      }

      // Check for rice/pasta water
      if (_containsAny(name, ['pirinç', 'makarna', 'bulgur'])) {
        if (!identifiedWaste.contains('Haşlama suyu')) {
          identifiedWaste.add('Haşlama suyu');
        }
      }
    }

    // Generate suggestions based on identified waste
    suggestions.addAll(_generateSuggestions(identifiedWaste));

    // Generate green impact message
    final greenImpact = _generateGreenImpact(identifiedWaste.length);

    return ZeroWasteAnalysis(
      isZeroWastePossible: identifiedWaste.isNotEmpty,
      identifiedWaste: identifiedWaste,
      premiumSuggestions: suggestions.take(2).toList(),
      greenImpact: greenImpact,
    );
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  List<ZeroWasteSuggestion> _generateSuggestions(List<String> waste) {
    final suggestions = <ZeroWasteSuggestion>[];

    for (final item in waste) {
      switch (item) {
        case 'Sebze/meyve kabukları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Çıtır Sebze Cipsi',
            steps: [
              'Kabukları iyice yıkayıp kurulayın',
              'İnce dilimler halinde kesin',
              'Zeytinyağı, tuz ve baharatlarla harmanlayın',
              '180°C fırında 15-20 dk çıtır olana kadar pişirin',
            ],
          ));
          suggestions.add(ZeroWasteSuggestion(
            title: 'Ev Yapımı Sebze Suyu',
            steps: [
              'Kabukları buzlukta biriktirin',
              'Yeterli miktara ulaşınca suyla kaynatın',
              '45 dk demlendikten sonra süzün',
              'Çorba ve risotto için mükemmel bir baz elde edin',
            ],
          ));
          break;

        case 'Yeşillik sapları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Yeşillik Pesto',
            steps: [
              'Sapları zeytinyağı ile blenderda çekin',
              'Sarımsak, ceviz ve parmesan ekleyin',
              'Tuz ile tatlandırın',
              'Makarna veya sandviçlerde kullanın',
            ],
          ));
          suggestions.add(ZeroWasteSuggestion(
            title: 'Baharat Küpleri',
            steps: [
              'Sapları ince ince doğrayın',
              'Buz kalıplarına paylaştırın',
              'Üzerine zeytinyağı dökün',
              'Dondurun ve her yemekte taze lezzet ekleyin',
            ],
          ));
          break;

        case 'Narenciye kabukları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Şekerli Limon Kabuğu',
            steps: [
              'Kabukları ince şeritler halinde kesin',
              'Şekerli suda 20 dk kaynatın',
              'Süzüp pudra şekerine bulayın',
              'Kurutup tatlılarda kullanın veya atıştırın',
            ],
          ));
          suggestions.add(ZeroWasteSuggestion(
            title: 'Ev Yapımı Temizleyici',
            steps: [
              'Kabukları cam kavanoza koyun',
              'Üzerini beyaz sirkeyle örtün',
              '2 hafta bekletin',
              'Süzüp doğal mutfak temizleyicisi olarak kullanın',
            ],
          ));
          break;

        case 'Soğan/sarımsak kabukları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Altın Renkli Et Suyu',
            steps: [
              'Kabukları diğer sebze atıklarıyla biriktirin',
              'Suyla birlikte 1 saat kaynatın',
              'Soğan kabuğu suyunuza altın rengi verir',
              'Pilav ve çorbalarda kullanın',
            ],
          ));
          break;

        case 'Bayat ekmek':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Ev Yapımı Galeta Unu',
            steps: [
              'Bayat ekmeği küçük parçalara ayırın',
              'Fırında kurutun veya robottan geçirin',
              'Kavanozda saklayın',
              'Köfte, şnitzel ve graten için kullanın',
            ],
          ));
          suggestions.add(ZeroWasteSuggestion(
            title: 'İtalyan Panzanella Salatası',
            steps: [
              'Bayat ekmeği küp küp doğrayın',
              'Zeytinyağında kızartın',
              'Domates, salatalık ve fesleğenle karıştırın',
              'Balzamik sos ile servis edin',
            ],
          ));
          break;

        case 'Peynir kabukları/kalıntıları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Lezzetli Peynir Cipsi',
            steps: [
              'Peynir kalıntılarını rendeleyin',
              'Yağlı kağıt üzerine küçük yığınlar yapın',
              '180°C fırında 5-7 dk pişirin',
              'Çorba ve salataların üzerine serpin',
            ],
          ));
          break;

        case 'Tavuk/et kemikleri':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Ev Yapımı Kemik Suyu',
            steps: [
              'Kemikleri fırında 20 dk kavurun',
              'Suyla birlikte 4-6 saat kaynatın',
              'Sebze kırpıntıları ve defne yaprağı ekleyin',
              'Süzüp buzdolabında 1 hafta saklayın',
            ],
          ));
          break;

        case 'Yumurta kabukları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Doğal Bitki Gübresi',
            steps: [
              'Kabukları iyice yıkayıp kurutun',
              'Havanda veya blenderda toz haline getirin',
              'Saksı toprağına karıştırın',
              'Bitkileriniz için kalsiyum kaynağı oluşturun',
            ],
          ));
          break;

        case 'Domates sapları ve kabukları':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Domates Tozu',
            steps: [
              'Kabukları düşük ısıda fırında kurutun',
              'Blenderda toz haline getirin',
              'Çorba ve soslara yoğun domates aroması katın',
              'Cam kavanozda 3 ay saklayabilirsiniz',
            ],
          ));
          break;

        case 'Haşlama suyu':
          suggestions.add(ZeroWasteSuggestion(
            title: 'Pirinç/Makarna Suyu Kullanımı',
            steps: [
              'Haşlama suyunu dökmeyin',
              'Soğutup saç ve cilt bakımında kullanın',
              'Çorba ve sos bazı olarak değerlendirin',
              'Bitkileri sulamak için kullanın (soğuttuktan sonra)',
            ],
          ));
          break;
      }
    }

    return suggestions;
  }

  String _generateGreenImpact(int wasteCount) {
    if (wasteCount == 0) {
      return 'Bu tarif zaten oldukça verimli! Yine de malzemeleri son damlasına kadar değerlendirmeyi unutmayın.';
    } else if (wasteCount == 1) {
      return 'Bu basit adımla yılda yaklaşık 2 kg gıda atığını önleyebilir ve karbon ayak izinizi %3 azaltabilirsiniz! 🌍';
    } else if (wasteCount <= 3) {
      return 'Bu önerilerle yılda 5 kg\'a kadar gıda israfını önleyebilir, hem bütçenize hem de gezegene katkı sağlayabilirsiniz! 🌱';
    } else {
      return 'Harika bir fırsat! Bu tarifteki atıkları değerlendirerek yılda 10 kg\'a kadar gıda israfını önleyebilirsiniz. Sürdürülebilir mutfağın kahramanısınız! 🏆';
    }
  }

  /// Convert analysis to JSON format (for API response)
  Map<String, dynamic> toJson(ZeroWasteAnalysis analysis) {
    return {
      'is_zero_waste_possible': analysis.isZeroWastePossible,
      'identified_waste': analysis.identifiedWaste,
      'premium_suggestions': analysis.premiumSuggestions.map((s) => {
        'title': s.title,
        'steps': s.steps,
      }).toList(),
      'green_impact': analysis.greenImpact,
    };
  }
}

class ZeroWasteAnalysis {
  const ZeroWasteAnalysis({
    required this.isZeroWastePossible,
    required this.identifiedWaste,
    required this.premiumSuggestions,
    required this.greenImpact,
  });

  final bool isZeroWastePossible;
  final List<String> identifiedWaste;
  final List<ZeroWasteSuggestion> premiumSuggestions;
  final String greenImpact;
}

class ZeroWasteSuggestion {
  const ZeroWasteSuggestion({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;
}
