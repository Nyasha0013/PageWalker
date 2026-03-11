import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

final authStateProvider =
    StreamProvider<AuthState>((ref) async* {
  final client = SupabaseConfig.client;
  yield* client.auth.onAuthStateChange
      .map((event) => event);
});

