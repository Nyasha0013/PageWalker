import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/theme_provider.dart';
import 'app_colors.dart';
import 'pagewalker_theme_extension.dart';

List<Color> _scaffoldGradient(AppThemeType appTheme, bool isDark) {
  switch (appTheme) {
    case AppThemeType.classic:
      return isDark
          ? const [Color(0xFF0A0A0A), Color(0xFF1A0800)]
          : const [Color(0xFFFFFBF7), Color(0xFFFFF3E8)];
    case AppThemeType.midnightLibrary:
      return isDark
          ? const [Color(0xFF0A0A14), Color(0xFF0F0A1E)]
          : const [Color(0xFFF8F7FF), Color(0xFFEEEBFF)];
    case AppThemeType.forestRetreat:
      return isDark
          ? const [Color(0xFF080F0A), Color(0xFF0A1810)]
          : const [Color(0xFFF5FAF6), Color(0xFFE8F5EB)];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(AppThemeType appTheme, ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    final colors = ThemeColors(appTheme: appTheme, isDark: isDark);
    final gradient = _scaffoldGradient(appTheme, isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.bg,
      cardColor: colors.card,
      extensions: [
        PagewalkerThemeExtension(
          colors: colors,
          scaffoldGradient: gradient,
        ),
      ],
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.accent,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: colors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: colors.textMuted,
        ),
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: colors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.primary.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.primary.withValues(alpha: 0.4)
                : colors.card),
      ),
      dividerTheme: DividerThemeData(
        color: colors.primary.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }

  // legacy entry point
  static ThemeData get dark => buildTheme(AppThemeType.classic, ThemeMode.dark);

  static ThemeData get light =>
      buildTheme(AppThemeType.classic, ThemeMode.light);
}
