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
}

