import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';
import 'app_colors.dart';

class PagewalkerThemeExtension extends ThemeExtension<PagewalkerThemeExtension> {
  final ThemeColors colors;
  final List<Color> scaffoldGradient;

  const PagewalkerThemeExtension({
    required this.colors,
    required this.scaffoldGradient,
  });

  @override
  PagewalkerThemeExtension copyWith({
    ThemeColors? colors,
    List<Color>? scaffoldGradient,
  }) {
    return PagewalkerThemeExtension(
      colors: colors ?? this.colors,
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
    );
  }

  @override
  PagewalkerThemeExtension lerp(
    ThemeExtension<PagewalkerThemeExtension>? other,
    double t,
  ) {
    if (other is! PagewalkerThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension PagewalkerThemeContext on BuildContext {
  ThemeColors get pwColors {
    final ext = Theme.of(this).extension<PagewalkerThemeExtension>();
    if (ext != null) return ext.colors;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return ThemeColors(appTheme: AppThemeType.classic, isDark: isDark);
  }
}
