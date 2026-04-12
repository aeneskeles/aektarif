import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final inputPath = _argValue(args, '--input') ?? 'data/recipes_mvp.json';
  final batchSize = int.tryParse(_argValue(args, '--batch') ?? '') ?? 200;

  final supabaseUrl = (Platform.environment['SUPABASE_URL'] ?? '').trim();
  final serviceKey = (Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim();

  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  if (supabaseUrl.isEmpty || serviceKey.isEmpty) {
    stderr.writeln('Missing env vars: SUPABASE_URL and/or SUPABASE_SERVICE_ROLE_KEY');
    stderr.writeln('Example (PowerShell):');
    stderr.writeln(r'  $env:SUPABASE_URL="https://xxxxx.supabase.co"');
    stderr.writeln(r'  $env:SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"');
    _printUsage();
    exit(64);
  }

  final file = File(inputPath);
  if (!await file.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(66);
  }

  final jsonText = await file.readAsString();
  final decoded = jsonDecode(jsonText);
  if (decoded is! List) {
    stderr.writeln('Expected a JSON array at top-level');
    exit(65);
  }

  final recipes = decoded.cast<Map<String, dynamic>>();
  stdout.writeln('Loaded ${recipes.length} recipes');

  final client = HttpClient();
  try {
    final endpoint = _buildUpsertUri(supabaseUrl);

    var processed = 0;
    for (var i = 0; i < recipes.length; i += batchSize) {
      final chunk = recipes.sublist(i, (i + batchSize).clamp(0, recipes.length));

      final rows = <Map<String, dynamic>>[];
      for (final r in chunk) {
        final id = (r['id'] ?? '').toString().trim();
        final title = (r['title'] ?? '').toString();
        final steps = (r['steps'] ?? '').toString();
        final image = r['image']?.toString();

        final ingredientsRawDynamic = r['ingredients'];
        final ingredientsRaw = <String>[];
        if (ingredientsRawDynamic is List) {
          for (final x in ingredientsRawDynamic) {
            if (x == null) continue;
            final s = x.toString().trim();
            if (s.isNotEmpty) ingredientsRaw.add(s);
          }
        }

        final keys = _toIngredientKeys(ingredientsRaw);

        if (id.isEmpty || title.isEmpty || steps.isEmpty) {
          continue;
        }

        rows.add({
          'id': id,
          'title_en': title,
          'title_tr': null,
          'steps_en': steps,
          'steps_tr': null,
          'ingredients_raw': ingredientsRaw,
          'ingredient_keys': keys,
          'image': image,
        });
      }

      if (rows.isEmpty) {
        processed += chunk.length;
        stdout.writeln('Skipped empty chunk at $i');
        continue;
      }

      await _upsertRecipes(
        client: client,
        uri: endpoint,
        serviceKey: serviceKey,
        rows: rows,
      );

      processed += chunk.length;
      stdout.writeln('Progress: $processed/${recipes.length}');
    }

    stdout.writeln('Done');
  } finally {
    client.close(force: true);
  }
}

Uri _buildUpsertUri(String supabaseUrl) {
  final base = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;
  return Uri.parse('$base/rest/v1/recipes?on_conflict=id');
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

List<String> _toIngredientKeys(List<String> raw) {
  final out = <String>{};
  for (final s in raw) {
    final key = _canonicalizeIngredient(s);
    if (key.isNotEmpty) out.add(key);
  }
  return out.toList()..sort();
}

String _canonicalizeIngredient(String input) {
  final cleaned = input
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
      .replaceAll(RegExp(r"\s+"), ' ')
      .trim();

  if (cleaned.isEmpty) return '';

  final tokens = cleaned.split(' ').where((t) => t.isNotEmpty).toList();

  final stop = <String>{
    'and',
    'or',
    'with',
    'to',
    'of',
    'the',
    'a',
    'an',
    'fresh',
    'freshly',
    'finely',
    'coarsely',
    'thinly',
    'chopped',
    'minced',
    'ground',
    'peeled',
    'seeded',
    'sliced',
    'diced',
    'grated',
    'shredded',
    'cooked',
    'large',
    'medium',
    'small',
    'extra',
    'optional',
    'kosher',
    'unsalted',
    'salted',
  };

  final units = <String>{
    'cup',
    'cups',
    'tbsp',
    'tablespoon',
    'tablespoons',
    'tsp',
    'teaspoon',
    'teaspoons',
    'oz',
    'ounce',
    'ounces',
    'g',
    'gram',
    'grams',
    'kg',
    'ml',
    'l',
    'lb',
    'lbs',
    'pound',
    'pounds',
    'pinch',
    'clove',
    'cloves',
    'sprig',
    'sprigs',
    'leaf',
    'leaves',
    'slice',
    'slices',
    'stick',
    'sticks',
    'package',
    'packages',
    'can',
    'cans',
    'jar',
    'jars',
    'bottle',
    'bottles',
    'wedge',
    'wedges',
  };

  final filtered = <String>[];
  for (final t in tokens) {
    if (t.isEmpty) continue;
    if (stop.contains(t)) continue;
    if (RegExp(r"^\d+$").hasMatch(t)) continue;
    filtered.add(t);
  }

  if (filtered.isEmpty) {
    return cleaned.replaceAll(' ', '_');
  }

  var candidate = filtered.last;
  if (units.contains(candidate) && filtered.length >= 2) {
    candidate = filtered[filtered.length - 2];
  }

  if (candidate.length <= 1) {
    return cleaned.replaceAll(' ', '_');
  }

  return candidate;
}

String? _argValue(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == name && i + 1 < args.length) return args[i + 1];
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}

void _printUsage() {
  stdout.writeln('Usage: dart run tools/import_recipes.dart --input data/recipes_mvp.json --batch 200');
  stdout.writeln('Required env vars:');
  stdout.writeln('  SUPABASE_URL');
  stdout.writeln('  SUPABASE_SERVICE_ROLE_KEY');
}
