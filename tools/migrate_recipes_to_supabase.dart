// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Tarifleri recipe_data.json'dan Supabase'e aktarır
/// 
/// Kullanım:
///   PowerShell'de:
///     $env:SUPABASE_URL="https://fmseurmcrvexpxyypvuh.supabase.co"
///     $env:SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"
///     dart run tools/migrate_recipes_to_supabase.dart
Future<void> main() async {
  print('🚀 Tarif aktarımı başlıyor...\n');

  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  if (supabaseUrl.isEmpty || serviceKey.isEmpty) {
    print('❌ Hata: SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY ortam değişkenleri gerekli!\n');
    print('PowerShell için:');
    print('  \$env:SUPABASE_URL="https://fmseurmcrvexpxyypvuh.supabase.co"');
    print('  \$env:SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"');
    print('\nService Role Key\'i Supabase Dashboard > Settings > API > service_role kısmından alabilirsiniz.');
    exit(1);
  }

  // JSON dosyasını oku
  final jsonFile = File('assets/recipe_data.json');
  if (!jsonFile.existsSync()) {
    print('❌ assets/recipe_data.json bulunamadı!');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final recipesJson = data['Recipe'] as Map<String, dynamic>? ?? {};

  print('📊 Toplam ${recipesJson.length} tarif bulundu.\n');

  final client = HttpClient();
  final endpoint = Uri.parse('$supabaseUrl/rest/v1/recipes?on_conflict=id');

  int successCount = 0;
  int errorCount = 0;
  final batchSize = 50;
  final entries = recipesJson.entries.toList();

  try {
    for (var i = 0; i < entries.length; i += batchSize) {
      final chunk = entries.sublist(i, (i + batchSize).clamp(0, entries.length));
      final rows = <Map<String, dynamic>>[];

      for (final entry in chunk) {
        try {
          final recipe = _convertRecipe(entry.key, entry.value as Map<String, dynamic>);
          rows.add(recipe);
        } catch (e) {
          errorCount++;
          if (errorCount <= 3) {
            print('⚠️ Dönüştürme hatası (${entry.key}): $e');
          }
        }
      }

      if (rows.isNotEmpty) {
        try {
          await _upsertRecipes(
            client: client,
            uri: endpoint,
            serviceKey: serviceKey,
            rows: rows,
          );
          successCount += rows.length;
        } catch (e) {
          errorCount += rows.length;
          print('❌ Batch yükleme hatası: $e');
        }
      }

      print('📤 İlerleme: ${i + chunk.length}/${entries.length} (Başarılı: $successCount)');
    }
  } finally {
    client.close(force: true);
  }

  print('\n' + '=' * 50);
  print('📊 SONUÇ:');
  print('   ✅ Başarılı: $successCount');
  print('   ❌ Hatalı: $errorCount');
  print('=' * 50);

  exit(errorCount > 0 ? 1 : 0);
}

Future<void> _upsertRecipes({
  required HttpClient client,
  required Uri uri,
  required String serviceKey,
  required List<Map<String, dynamic>> rows,
}) async {
  final req = await client.openUrl('POST', uri);

  req.headers.set('apikey', serviceKey);
  req.headers.set('authorization', 'Bearer $serviceKey');
  req.headers.set('content-type', 'application/json; charset=utf-8');
  req.headers.set('prefer', 'resolution=merge-duplicates,return=minimal');

  final jsonBytes = utf8.encode(jsonEncode(rows));
  req.headers.set('content-length', jsonBytes.length.toString());
  req.add(jsonBytes);

  final res = await req.close();
  final status = res.statusCode;
  final body = await utf8.decodeStream(res);

  if (status < 200 || status >= 300) {
    throw StateError('Supabase upsert failed: HTTP $status\n$body');
  }
}

Map<String, dynamic> _convertRecipe(String id, Map<String, dynamic> json) {
  // PrepDetails parse: "4 kişilik;25 dakika;25 dakika;"
  final prepDetails = (json['PrepDetails'] as String?)?.split(';') ?? [];
  
  int? servings;
  int? prepTime;
  int? cookTime;
  
  if (prepDetails.isNotEmpty) {
    final servingsStr = prepDetails[0].replaceAll(RegExp(r'[^0-9]'), '');
    if (servingsStr.isNotEmpty) {
      servings = int.tryParse(servingsStr);
    }
  }
  if (prepDetails.length > 1) {
    final prepTimeStr = prepDetails[1].replaceAll(RegExp(r'[^0-9]'), '');
    if (prepTimeStr.isNotEmpty) {
      prepTime = int.tryParse(prepTimeStr);
    }
  }
  if (prepDetails.length > 2) {
    final cookTimeStr = prepDetails[2].replaceAll(RegExp(r'[^0-9]'), '');
    if (cookTimeStr.isNotEmpty) {
      cookTime = int.tryParse(cookTimeStr);
    }
  }

  // Ingredient names parse: semicolon separated
  final ingredientNamesRaw = (json['IngridientNames'] as String?) ?? '';
  final ingredientKeys = ingredientNamesRaw
      .split(';')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  // Ingredients raw parse: newline + bullet separated
  final ingredientsRaw = (json['Ingridients'] as String?)
          ?.split('\n')
          .map((e) => e.replaceAll('●', '').trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      [];

  // Steps parse: numbered with 1.), 2.), etc.
  final recipeDetails = (json['RecipeDetails'] as String?) ?? '';
  final stepTexts = recipeDetails
      .split(RegExp(r'\d+\.\)'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final stepsTr = <Map<String, dynamic>>[];
  for (int i = 0; i < stepTexts.length; i++) {
    stepsTr.add({
      'order': i + 1,
      'instruction': stepTexts[i],
    });
  }

  // Keywords parse: comma separated
  final keywordsRaw = (json['Keywords'] as String?) ?? '';
  final tags = keywordsRaw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // Difficulty - derive from total time
  final totalTime = (prepTime ?? 0) + (cookTime ?? 0);
  String difficulty;
  if (totalTime <= 30) {
    difficulty = 'easy';
  } else if (totalTime <= 60) {
    difficulty = 'medium';
  } else {
    difficulty = 'hard';
  }

  final titleTr = json['Name'] as String? ?? 'Tarif';
  final descriptionTr = json['ShortDescription'] as String? ?? '';

  return {
    'id': id,
    'title_tr': titleTr,
    'title_en': titleTr, // Türkçe başlığı İngilizce için de kullan
    'description_tr': descriptionTr,
    'description_en': descriptionTr, // Türkçe açıklamayı İngilizce için de kullan
    'steps_tr': stepsTr,
    'steps_en': stepsTr, // Türkçe adımları İngilizce için de kullan
    'ingredients_raw': ingredientsRaw,
    'ingredient_keys': ingredientKeys,
    'image_url': json['Image'] as String?,
    'prep_time': prepTime,
    'cook_time': cookTime,
    'servings': servings,
    'difficulty': difficulty,
    'category': json['MainCategory'] as String?,
    'tags': tags.isNotEmpty ? tags : null,
  };
}
