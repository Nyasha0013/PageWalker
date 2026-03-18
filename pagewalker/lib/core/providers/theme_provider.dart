import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const _key = 'pagewalker_theme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> setLight() async {
    state = ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
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

