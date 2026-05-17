import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    if (kDebugMode) {
      debugPrint('Supabase connected: ${Env.supabaseUrl}');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isConnected =>
      !Env.supabaseUrl.contains('PASTE_YOUR') &&
      !Env.supabaseAnonKey.contains('PASTE_YOUR') &&
      Env.supabaseUrl.startsWith('https://') &&
      Env.supabaseAnonKey.isNotEmpty;
}
