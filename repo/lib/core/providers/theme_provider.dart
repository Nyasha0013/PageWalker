import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  static const _keyV2 = 'pw_theme_mode_v2';
  static const _keyLegacy = 'pw_theme_mode';

  Future<void> _loadTheme() async {
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

  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _persist(1);
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    await _persist(0);
  }

  Future<void> setSystem() async {
    state = ThemeMode.system;
    await _persist(2);
  }

  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await setLight();
    } else {
      await setDark();
    }
  }

  bool get isDark => state == ThemeMode.dark;
}
