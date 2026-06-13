import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/app_settings_provider.dart';
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('ingredients');
  await Hive.openBox('settings');
  await Hive.openBox('favorites');

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(
    const ProviderScope(
      child: TarifUygApp(),
    ),
  );
}

class TarifUygApp extends ConsumerWidget {
  const TarifUygApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            settings.isDarkTheme ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: settings.activeTheme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            settings.isDarkTheme ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'LezzetPot',
      debugShowCheckedModeBanner: false,
      theme: settings.activeTheme,
      locale: settings.locale,
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}
