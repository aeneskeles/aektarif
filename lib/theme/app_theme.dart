import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeVariant { light, blue, dark }

@immutable
class AppThemeVariantExtension
    extends ThemeExtension<AppThemeVariantExtension> {
  const AppThemeVariantExtension({required this.variant});

  final AppThemeVariant variant;

  @override
  AppThemeVariantExtension copyWith({AppThemeVariant? variant}) {
    return AppThemeVariantExtension(variant: variant ?? this.variant);
  }

  @override
  AppThemeVariantExtension lerp(
    covariant ThemeExtension<AppThemeVariantExtension>? other,
    double t,
  ) {
    if (other is! AppThemeVariantExtension) return this;
    return t < 0.5 ? this : other;
  }
}

class AppTheme {
  AppTheme._();
  
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryColor) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: textColor,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  // Modern Blue/Navy Color Palette - LezzetPot Theme
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondaryColor = Color(0xFF112244);
  static const Color accentColor = Color(0xFF1D4ED8);
  
  // Dark Theme Colors (Main)
  static const Color backgroundColor = Color(0xFF060D1B);
  static const Color surfaceColor = Color(0xFF0D1829);
  static const Color cardColor = Color(0xFF0D1829);
  static const Color inputColor = Color(0xFF112244);
  
  // Status Colors
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFFFFFFF);
  
  // Border & Divider
  static const Color dividerColor = Color(0xFF1E3A5F);
  static const Color borderColor = Color(0x333B82F6);
  static const Color highlightColor = Color(0xFF1E3A8A);
  static const Color chipColor = Color(0xFF112244);
  
  // Text Colors - Dark Theme
  static const Color textPrimary = Color(0xFFEEF2FF);
  static const Color textSecondary = Color(0xFF3B82F6);
  static const Color textTertiary = Color(0xFF2563EB);
  static const Color textMuted = Color(0xFF1E40AF);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Black Dark Theme Colors
  static const Color blackBackground = Color(0xFF000000);
  static const Color blackSurface = Color(0xFF141414);
  static const Color blackCard = Color(0xFF1A1A1A);
  static const Color blackInput = Color(0xFF252525);
  static const Color blackBorder = Color(0xFF333333);
  static const Color blackTextPrimary = Color(0xFFFFFFFF);
  static const Color blackTextSecondary = Color(0xFFB3B3B3);
  static const Color blackTextTertiary = Color(0xFF808080);

  // Text Colors - Light Theme
  static const Color textDark = Color(0xFF000000);
  static const Color textDarkSecondary = Color(0xFF333333);
  static const Color textDarkMuted = Color(0xFF666666);
  /// Koyu mavi vurgu — açık mavi (#93C5FD) yerine kullanılır
  static const Color accentMuted = Color(0xFF2563EB);
  static const Color accentMutedSoft = Color(0xFF1E40AF);
  
  // Special Colors
  static const Color navyBlue = Color(0xFF0D1829);
  static const Color deepNavy = Color(0xFF060D1B);
  static const Color blueGlow = Color(0x1A3B82F6);
  static const Color amberStar = Color(0xFFFBBF24);
  static const Color greenOnline = Color(0xFF22C55E);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF060D1B), Color(0xFF0D1829), Color(0xFF112244)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D1829), Color(0xFF112244)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0x332563EB), Color(0x331D4ED8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData themeFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.light:
        return lightTheme;
      case AppThemeVariant.blue:
        return blueTheme;
      case AppThemeVariant.dark:
        return blackTheme;
    }
  }

  // Blue Theme (formerly the default dark theme)
  static ThemeData get blueTheme {
    return _buildBlueTheme();
  }

  /// @deprecated Use [blueTheme] instead.
  static ThemeData get darkTheme => blueTheme;

  static ThemeData _buildBlueTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textLight,
        onSecondary: textSecondary,
        onSurface: textPrimary,
        onError: textLight,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        color: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: borderColor),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputColor.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: TextStyle(color: textTertiary.withValues(alpha: 0.6), fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipColor,
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor.withValues(alpha: 0.95),
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      textTheme: _buildTextTheme(
        ThemeData.dark().textTheme,
        textLight,
        textSecondary,
      ),
      extensions: const [
        AppThemeVariantExtension(variant: AppThemeVariant.blue),
      ],
    );
  }

  // Black Dark Theme
  static ThemeData get blackTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: blackBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: blackInput,
        tertiary: accentColor,
        surface: blackSurface,
        error: errorColor,
        onPrimary: blackTextPrimary,
        onSecondary: blackTextSecondary,
        onSurface: blackTextPrimary,
        onError: blackTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: blackTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: blackTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: blackBorder),
        ),
        color: blackCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: blackTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blackTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: blackBorder),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: blackInput.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blackBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blackBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: TextStyle(
          color: blackTextTertiary.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        labelStyle: const TextStyle(color: blackTextSecondary, fontSize: 14),
        prefixIconColor: blackTextTertiary,
        suffixIconColor: blackTextTertiary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: blackInput,
        labelStyle: const TextStyle(
          color: blackTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: blackSurface.withValues(alpha: 0.95),
        selectedItemColor: primaryColor,
        unselectedItemColor: blackTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: blackTextPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dividerTheme: const DividerThemeData(color: blackBorder, thickness: 1),
      textTheme: _buildTextTheme(
        ThemeData.dark().textTheme,
        blackTextPrimary,
        blackTextSecondary,
      ),
      extensions: const [
        AppThemeVariantExtension(variant: AppThemeVariant.dark),
      ],
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: lightSecondary,
        tertiary: accentColor,
        surface: lightSurface,
        error: errorColor,
        onPrimary: textLight,
        onSecondary: textDark,
        onSurface: textDark,
        onError: textLight,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: lightBackground,
        foregroundColor: textDark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryDark.withValues(alpha: 0.15)),
        ),
        color: lightCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryDark,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: primaryDark.withValues(alpha: 0.15)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryDark.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryDark.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: textDarkMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textDark, fontSize: 14),
        prefixIconColor: textDarkMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSecondary,
        labelStyle: const TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryDark,
        unselectedItemColor: textDarkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: textLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: primaryDark.withValues(alpha: 0.15),
        thickness: 1,
      ),
      textTheme: _buildTextTheme(
        ThemeData.light().textTheme,
        textDark,
        textDarkMuted,
      ),
      extensions: const [
        AppThemeVariantExtension(variant: AppThemeVariant.light),
      ],
    );
  }
}
