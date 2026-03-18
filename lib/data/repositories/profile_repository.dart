import '../../core/config/supabase_config.dart';
import '../models/profile.dart';

class ProfileRepository {
  final _client = SupabaseConfig.client;

  Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromSupabase(data);
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toSupabase())
        .eq('id', profile.id);
  }

  Future<Profile?> getProfileById(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromSupabase(data);
  }

  Future<List<Profile>> searchPublicProfiles({
    String? query,
    int limit = 25,
  }) async {
    final user = _client.auth.currentUser;
    var q = _client.from('profiles').select().eq('is_public', true);

    if (user != null) {
      q = q.neq('id', user.id);
    }

    if (query != null && query.trim().isNotEmpty) {
      q = q.ilike('username', '%${query.trim().toLowerCase()}%');
    }

    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((e) => Profile.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }
}

