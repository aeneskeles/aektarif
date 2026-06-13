import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/app_theme.dart';

class AppSettings {
  const AppSettings({
    this.themeVariant = AppThemeVariant.light,
    this.languageCode = 'tr',
  });

  final AppThemeVariant themeVariant;
  final String languageCode;

  bool get isDarkTheme => themeVariant != AppThemeVariant.light;

  ThemeMode get themeMode => ThemeMode.light;

  ThemeData get activeTheme => AppTheme.themeFor(themeVariant);

  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    AppThemeVariant? themeVariant,
    String? languageCode,
  }) {
    return AppSettings(
      themeVariant: themeVariant ?? this.themeVariant,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _boxName = 'settings';
  static const _themeKey = 'theme_variant';
  static const _darkThemeKey = 'is_dark_theme';
  static const _languageKey = 'language_code';

  Box get _box => Hive.box(_boxName);

  void _load() {
    final storedVariant = _box.get(_themeKey) as String?;
    AppThemeVariant variant;

    if (storedVariant != null) {
      variant = AppThemeVariant.values.firstWhere(
        (value) => value.name == storedVariant,
        orElse: () => AppThemeVariant.light,
      );
    } else {
      final isDark = _box.get(_darkThemeKey, defaultValue: false) as bool;
      variant = isDark ? AppThemeVariant.blue : AppThemeVariant.light;
    }

    final language = _box.get(_languageKey, defaultValue: 'tr') as String;
    state = AppSettings(
      themeVariant: variant,
      languageCode: language,
    );
  }

  Future<void> setThemeVariant(AppThemeVariant variant) async {
    state = state.copyWith(themeVariant: variant);
    await _box.put(_themeKey, variant.name);
  }

  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(languageCode: languageCode);
    await _box.put(_languageKey, languageCode);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
