import 'package:flutter/material.dart';

import 'app_theme.dart';

extension AppThemeContext on BuildContext {
  AppThemeVariant get appThemeVariant =>
      Theme.of(this).extension<AppThemeVariantExtension>()?.variant ??
      AppThemeVariant.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  bool get isBlueTheme => appThemeVariant == AppThemeVariant.blue;

  bool get isBlackTheme => appThemeVariant == AppThemeVariant.dark;

  Color get appBackground {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.lightBackground;
      case AppThemeVariant.blue:
        return AppTheme.backgroundColor;
      case AppThemeVariant.dark:
        return AppTheme.blackBackground;
    }
  }

  Color get appSurface {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.lightSurface;
      case AppThemeVariant.blue:
        return AppTheme.surfaceColor;
      case AppThemeVariant.dark:
        return AppTheme.blackSurface;
    }
  }

  Color get appCard {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.lightCard;
      case AppThemeVariant.blue:
        return AppTheme.cardColor;
      case AppThemeVariant.dark:
        return AppTheme.blackCard;
    }
  }

  Color get appInput {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return Colors.white;
      case AppThemeVariant.blue:
        return AppTheme.inputColor;
      case AppThemeVariant.dark:
        return AppTheme.blackInput;
    }
  }

  Color get appTextPrimary {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.textDark;
      case AppThemeVariant.blue:
        return AppTheme.textPrimary;
      case AppThemeVariant.dark:
        return AppTheme.blackTextPrimary;
    }
  }

  Color get appTextSecondary {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.textDarkSecondary;
      case AppThemeVariant.blue:
        return AppTheme.textSecondary;
      case AppThemeVariant.dark:
        return AppTheme.blackTextSecondary;
    }
  }

  Color get appTextMuted {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.textDarkMuted;
      case AppThemeVariant.blue:
        return AppTheme.accentMuted.withValues(alpha: 0.85);
      case AppThemeVariant.dark:
        return AppTheme.blackTextTertiary;
    }
  }

  Color get appSectionLabel {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.textDark;
      case AppThemeVariant.blue:
        return AppTheme.accentMuted;
      case AppThemeVariant.dark:
        return AppTheme.blackTextSecondary;
    }
  }

  Color get appCardFill {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return Colors.white;
      case AppThemeVariant.blue:
        return AppTheme.cardColor.withValues(alpha: 0.6);
      case AppThemeVariant.dark:
        return AppTheme.blackCard.withValues(alpha: 0.6);
    }
  }

  Color get appIconColor {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return AppTheme.textDark;
      case AppThemeVariant.blue:
      case AppThemeVariant.dark:
        return appTextPrimary;
    }
  }

  Color get appOverlay {
    return Colors.transparent;
  }

  Color get appOverlayStrong {
    return Colors.transparent;
  }

  Color get appBorderSubtle {
    switch (appThemeVariant) {
      case AppThemeVariant.light:
        return const Color(0xFFE5E7EB);
      case AppThemeVariant.blue:
      case AppThemeVariant.dark:
        return Colors.white.withValues(alpha: 0.12);
    }
  }
}
