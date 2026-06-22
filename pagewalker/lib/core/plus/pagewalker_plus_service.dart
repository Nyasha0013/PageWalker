import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import 'pagewalker_plus_features.dart';

final pagewalkerPlusProvider =
    AsyncNotifierProvider<PagewalkerPlusNotifier, bool>(
  PagewalkerPlusNotifier.new,
);

class PagewalkerPlusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => PagewalkerPlusService.instance.isPlusActive();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await PagewalkerPlusService.instance.isPlusActive(forceRefresh: true),
    );
  }
}

class PagewalkerPlusService {
  PagewalkerPlusService._();
  static final instance = PagewalkerPlusService._();

  static const _debugPlusKey = 'pagewalker_plus_debug';
  static const _cachedPlusKey = 'pagewalker_plus_cached';

  bool? _cached;

  Future<bool> isPlusActive({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    if (kDebugMode && prefs.getBool(_debugPlusKey) == true) {
      _cached = true;
      return true;
    }

    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) {
      _cached = false;
      return false;
    }

    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('is_plus, plus_expires_at')
          .eq('id', uid)
          .maybeSingle();

      final active = _rowIsPlusActive(row);
      _cached = active;
      await prefs.setBool(_cachedPlusKey, active);
      return active;
    } catch (e) {
      debugPrint('Plus status check failed: $e');
      final fallback = prefs.getBool(_cachedPlusKey) ?? false;
      _cached = fallback;
      return fallback;
    }
  }

  bool _rowIsPlusActive(Map<String, dynamic>? row) {
    if (row == null || row['is_plus'] != true) return false;
    final expiresRaw = row['plus_expires_at'] as String?;
    if (expiresRaw == null || expiresRaw.isEmpty) return true;
    return DateTime.parse(expiresRaw).isAfter(DateTime.now());
  }

  Future<bool> canUse(PagewalkerPlusFeature feature) {
    return isPlusActive();
  }

  Future<bool> canJoinAnotherClub(int currentClubCount) async {
    if (currentClubCount < PagewalkerPlusCatalog.freeClubLimit) return true;
    return isPlusActive();
  }

  Future<void> setDebugPlus(bool enabled) async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPlusKey, enabled);
    _cached = enabled;
  }

  void invalidateCache() => _cached = null;
}
