import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  classic,
  midnightLibrary,
  forestRetreat,
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

final appThemeProvider =
    StateNotifierProvider<AppThemeNotifier, AppThemeType>(
        (ref) => AppThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _load();
  }

  static const _keyV2 = 'pw_theme_mode_v2';
  static const _keyLegacy = 'pw_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_keyV2)) {
      final v = prefs.getInt(_keyV2) ?? 0;
      state = _modeFromInt(v);
      return;
    }
    if (prefs.containsKey(_keyLegacy)) {
      final isDark = prefs.getBool(_keyLegacy) ?? true;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
      await prefs.setInt(_keyV2, isDark ? 1 : 0);
      return;
    }
    state = ThemeMode.light;
  }

  static ThemeMode _modeFromInt(int v) {
    switch (v) {
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> _persist(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyV2, mode);
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    await _persist(0);
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _persist(1);
  }

  Future<void> setSystem() async {
    state = ThemeMode.system;
    await _persist(2);
  }

  bool get isDark => state == ThemeMode.dark;
}

class AppThemeNotifier extends StateNotifier<AppThemeType> {
  AppThemeNotifier() : super(AppThemeType.classic) {
    _load();
  }

  static const _key = 'pw_app_theme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 0;
    state = AppThemeType.values[index.clamp(0, AppThemeType.values.length - 1)];
  }

  Future<void> setTheme(AppThemeType theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, theme.index);
  }
}
